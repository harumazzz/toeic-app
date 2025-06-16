package monitoring

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/cache"
	"github.com/toeic-app/internal/logger"
)

// HealthStatus represents the health status of a component
type HealthStatus string

const (
	HealthStatusUp      HealthStatus = "UP"
	HealthStatusDown    HealthStatus = "DOWN"
	HealthStatusWarning HealthStatus = "WARNING"
	HealthStatusUnknown HealthStatus = "UNKNOWN"
)

// ComponentHealth represents the health of a single component
type ComponentHealth struct {
	Status       HealthStatus           `json:"status"`
	Message      string                 `json:"message,omitempty"`
	LastChecked  time.Time              `json:"last_checked"`
	ResponseTime time.Duration          `json:"response_time"`
	Details      map[string]interface{} `json:"details,omitempty"`
}

// OverallHealth represents the overall health of the application
type OverallHealth struct {
	Status     HealthStatus                `json:"status"`
	Timestamp  time.Time                   `json:"timestamp"`
	Version    string                      `json:"version"`
	Uptime     time.Duration               `json:"uptime"`
	Components map[string]*ComponentHealth `json:"components"`
	Summary    map[string]interface{}      `json:"summary,omitempty"`
}

// HealthChecker interface for component health checks
type HealthChecker interface {
	CheckHealth(ctx context.Context) *ComponentHealth
	GetName() string
}

// DatabaseHealthChecker checks database health
type DatabaseHealthChecker struct {
	db      *sql.DB
	name    string
	timeout time.Duration
}

// NewDatabaseHealthChecker creates a new database health checker
func NewDatabaseHealthChecker(db *sql.DB, name string, timeout time.Duration) *DatabaseHealthChecker {
	return &DatabaseHealthChecker{
		db:      db,
		name:    name,
		timeout: timeout,
	}
}

func (d *DatabaseHealthChecker) GetName() string {
	return d.name
}

func (d *DatabaseHealthChecker) CheckHealth(ctx context.Context) *ComponentHealth {
	start := time.Now()

	// Create context with timeout
	ctx, cancel := context.WithTimeout(ctx, d.timeout)
	defer cancel()

	health := &ComponentHealth{
		LastChecked: start,
		Details:     make(map[string]interface{}),
	}

	// Basic ping test
	if err := d.db.PingContext(ctx); err != nil {
		health.Status = HealthStatusDown
		health.Message = fmt.Sprintf("Database ping failed: %v", err)
		health.ResponseTime = time.Since(start)
		return health
	}
	// Get database stats
	stats := d.db.Stats()
	health.Details["open_connections"] = stats.OpenConnections
	health.Details["idle_connections"] = stats.Idle
	health.Details["in_use_connections"] = stats.InUse
	health.Details["max_open_connections"] = stats.MaxOpenConnections
	health.Details["wait_count"] = stats.WaitCount
	health.Details["wait_duration"] = stats.WaitDuration.String()

	// Check connection pool health
	if stats.OpenConnections >= stats.MaxOpenConnections-1 {
		health.Status = HealthStatusWarning
		health.Message = "Connection pool nearly exhausted"
	} else {
		health.Status = HealthStatusUp
		health.Message = "Database is healthy"
	}

	health.ResponseTime = time.Since(start)
	return health
}

// CacheHealthChecker checks cache health
type CacheHealthChecker struct {
	cache   cache.Cache
	name    string
	timeout time.Duration
}

// NewCacheHealthChecker creates a new cache health checker
func NewCacheHealthChecker(cache cache.Cache, name string, timeout time.Duration) *CacheHealthChecker {
	return &CacheHealthChecker{
		cache:   cache,
		name:    name,
		timeout: timeout,
	}
}

func (c *CacheHealthChecker) GetName() string {
	return c.name
}

func (c *CacheHealthChecker) CheckHealth(ctx context.Context) *ComponentHealth {
	start := time.Now()

	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	health := &ComponentHealth{
		LastChecked: start,
		Details:     make(map[string]interface{}),
	}

	if c.cache == nil {
		health.Status = HealthStatusDown
		health.Message = "Cache is not initialized"
		health.ResponseTime = time.Since(start)
		return health
	}
	// Test cache with a simple operation
	testKey := "health_check_test"
	testValue := []byte("test_value")

	// Try to set a value
	if err := c.cache.Set(ctx, testKey, testValue, time.Minute); err != nil {
		health.Status = HealthStatusDown
		health.Message = fmt.Sprintf("Cache set operation failed: %v", err)
		health.ResponseTime = time.Since(start)
		return health
	}

	// Try to get the value
	result, err := c.cache.Get(ctx, testKey)
	if err != nil {
		health.Status = HealthStatusWarning
		health.Message = fmt.Sprintf("Cache get operation failed: %v", err)
	} else if string(result) != string(testValue) {
		health.Status = HealthStatusWarning
		health.Message = "Cache data integrity issue"
	} else {
		health.Status = HealthStatusUp
		health.Message = "Cache is healthy"
	}

	// Clean up test key
	c.cache.Delete(ctx, testKey)

	health.ResponseTime = time.Since(start)
	return health
}

// ExternalServiceHealthChecker checks external service health
type ExternalServiceHealthChecker struct {
	name       string
	url        string
	timeout    time.Duration
	httpClient *http.Client
}

// NewExternalServiceHealthChecker creates a new external service health checker
func NewExternalServiceHealthChecker(name, url string, timeout time.Duration) *ExternalServiceHealthChecker {
	return &ExternalServiceHealthChecker{
		name:    name,
		url:     url,
		timeout: timeout,
		httpClient: &http.Client{
			Timeout: timeout,
		},
	}
}

func (e *ExternalServiceHealthChecker) GetName() string {
	return e.name
}

func (e *ExternalServiceHealthChecker) CheckHealth(ctx context.Context) *ComponentHealth {
	start := time.Now()

	health := &ComponentHealth{
		LastChecked: start,
		Details:     make(map[string]interface{}),
	}

	req, err := http.NewRequestWithContext(ctx, "GET", e.url, nil)
	if err != nil {
		health.Status = HealthStatusDown
		health.Message = fmt.Sprintf("Failed to create request: %v", err)
		health.ResponseTime = time.Since(start)
		return health
	}

	resp, err := e.httpClient.Do(req)
	if err != nil {
		health.Status = HealthStatusDown
		health.Message = fmt.Sprintf("Request failed: %v", err)
		health.ResponseTime = time.Since(start)
		return health
	}
	defer resp.Body.Close()

	health.ResponseTime = time.Since(start)
	health.Details["status_code"] = resp.StatusCode
	health.Details["url"] = e.url

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		health.Status = HealthStatusUp
		health.Message = "Service is healthy"
	} else if resp.StatusCode >= 500 {
		health.Status = HealthStatusDown
		health.Message = fmt.Sprintf("Service returned server error: %d", resp.StatusCode)
	} else {
		health.Status = HealthStatusWarning
		health.Message = fmt.Sprintf("Service returned status: %d", resp.StatusCode)
	}

	return health
}

// HealthService manages health checks for all components
type HealthService struct {
	checkers    map[string]HealthChecker
	lastResults map[string]*ComponentHealth
	startTime   time.Time
	version     string
	config      *HealthConfig
	mu          sync.RWMutex
}

// HealthConfig configuration for health service
type HealthConfig struct {
	Enabled           bool
	CheckInterval     time.Duration
	DefaultTimeout    time.Duration
	CacheResults      bool
	MaxCacheAge       time.Duration
	FailureThreshold  int
	RecoveryThreshold int
}

// DefaultHealthConfig returns default health configuration
func DefaultHealthConfig() *HealthConfig {
	return &HealthConfig{
		Enabled:           true,
		CheckInterval:     30 * time.Second,
		DefaultTimeout:    5 * time.Second,
		CacheResults:      true,
		MaxCacheAge:       1 * time.Minute,
		FailureThreshold:  3,
		RecoveryThreshold: 2,
	}
}

// NewHealthService creates a new health service
func NewHealthService(version string, config *HealthConfig) *HealthService {
	if config == nil {
		config = DefaultHealthConfig()
	}

	return &HealthService{
		checkers:    make(map[string]HealthChecker),
		lastResults: make(map[string]*ComponentHealth),
		startTime:   time.Now(),
		version:     version,
		config:      config,
	}
}

// RegisterChecker registers a health checker
func (h *HealthService) RegisterChecker(checker HealthChecker) {
	h.mu.Lock()
	defer h.mu.Unlock()

	h.checkers[checker.GetName()] = checker
	logger.Info("Health checker registered: %s", checker.GetName())
}

// UnregisterChecker unregisters a health checker
func (h *HealthService) UnregisterChecker(name string) {
	h.mu.Lock()
	defer h.mu.Unlock()

	delete(h.checkers, name)
	delete(h.lastResults, name)
	logger.Info("Health checker unregistered: %s", name)
}

// CheckHealth performs health checks on all registered components
func (h *HealthService) CheckHealth(ctx context.Context) *OverallHealth {
	overall := &OverallHealth{
		Timestamp:  time.Now(),
		Version:    h.version,
		Uptime:     time.Since(h.startTime),
		Components: make(map[string]*ComponentHealth),
		Summary:    make(map[string]interface{}),
	}

	h.mu.RLock()
	checkers := make(map[string]HealthChecker)
	for name, checker := range h.checkers {
		checkers[name] = checker
	}
	h.mu.RUnlock()

	if len(checkers) == 0 {
		overall.Status = HealthStatusUp
		overall.Summary["message"] = "No health checkers registered"
		return overall
	}

	// Check each component
	var wg sync.WaitGroup
	results := make(chan struct {
		name   string
		health *ComponentHealth
	}, len(checkers))

	for name, checker := range checkers {
		wg.Add(1)
		go func(name string, checker HealthChecker) {
			defer wg.Done()

			// Use cached result if available and fresh
			if h.config.CacheResults {
				h.mu.RLock()
				cached := h.lastResults[name]
				h.mu.RUnlock()

				if cached != nil && time.Since(cached.LastChecked) < h.config.MaxCacheAge {
					results <- struct {
						name   string
						health *ComponentHealth
					}{name, cached}
					return
				}
			}

			// Perform health check
			health := checker.CheckHealth(ctx)

			// Cache result
			if h.config.CacheResults {
				h.mu.Lock()
				h.lastResults[name] = health
				h.mu.Unlock()
			}

			results <- struct {
				name   string
				health *ComponentHealth
			}{name, health}
		}(name, checker)
	}

	// Wait for all checks to complete
	go func() {
		wg.Wait()
		close(results)
	}()

	// Collect results
	upCount := 0
	downCount := 0
	warningCount := 0

	for result := range results {
		overall.Components[result.name] = result.health

		switch result.health.Status {
		case HealthStatusUp:
			upCount++
		case HealthStatusDown:
			downCount++
		case HealthStatusWarning:
			warningCount++
		}
	}

	// Determine overall status
	totalCount := len(overall.Components)
	if downCount > 0 {
		overall.Status = HealthStatusDown
	} else if warningCount > 0 {
		overall.Status = HealthStatusWarning
	} else {
		overall.Status = HealthStatusUp
	}

	// Add summary
	overall.Summary["total_components"] = totalCount
	overall.Summary["up_count"] = upCount
	overall.Summary["down_count"] = downCount
	overall.Summary["warning_count"] = warningCount
	overall.Summary["health_percentage"] = float64(upCount) / float64(totalCount) * 100

	return overall
}

// Start starts the health service with periodic checks
func (h *HealthService) Start(ctx context.Context) {
	if !h.config.Enabled {
		logger.Info("Health service is disabled")
		return
	}

	logger.Info("Starting health service with check interval: %v", h.config.CheckInterval)

	ticker := time.NewTicker(h.config.CheckInterval)
	go func() {
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				// Perform health checks in background
				go func() {
					checkCtx, cancel := context.WithTimeout(context.Background(), h.config.DefaultTimeout*2)
					defer cancel()

					overall := h.CheckHealth(checkCtx)

					// Log health status
					if overall.Status == HealthStatusDown {
						logger.Error("Health check failed - overall status: %s", overall.Status)
						for name, component := range overall.Components {
							if component.Status == HealthStatusDown {
								logger.Error("Component %s is down: %s", name, component.Message)
							}
						}
					} else if overall.Status == HealthStatusWarning {
						logger.Warn("Health check warning - overall status: %s", overall.Status)
						for name, component := range overall.Components {
							if component.Status == HealthStatusWarning {
								logger.Warn("Component %s has warning: %s", name, component.Message)
							}
						}
					}
				}()

			case <-ctx.Done():
				logger.Info("Health service stopped")
				return
			}
		}
	}()
}

// GetHealthHandler returns a Gin handler for health checks
func (h *HealthService) GetHealthHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), h.config.DefaultTimeout)
		defer cancel()

		health := h.CheckHealth(ctx)

		statusCode := http.StatusOK
		if health.Status == HealthStatusDown {
			statusCode = http.StatusServiceUnavailable
		} else if health.Status == HealthStatusWarning {
			statusCode = http.StatusOK // 200 but with warnings
		}

		c.Header("Cache-Control", "no-cache, no-store, must-revalidate")
		c.Header("Pragma", "no-cache")
		c.Header("Expires", "0")

		c.JSON(statusCode, health)
	}
}

// GetLivenessHandler returns a simple liveness probe handler
func (h *HealthService) GetLivenessHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "UP",
			"timestamp": time.Now(),
			"uptime":    time.Since(h.startTime).String(),
		})
	}
}

// GetReadinessHandler returns a readiness probe handler
func (h *HealthService) GetReadinessHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), h.config.DefaultTimeout)
		defer cancel()

		health := h.CheckHealth(ctx)

		// For readiness, we're more strict - any down component means not ready
		statusCode := http.StatusOK
		if health.Status == HealthStatusDown {
			statusCode = http.StatusServiceUnavailable
		}

		c.JSON(statusCode, gin.H{
			"status":     health.Status,
			"timestamp":  health.Timestamp,
			"ready":      health.Status != HealthStatusDown,
			"components": len(health.Components),
			"summary":    health.Summary,
		})
	}
}
