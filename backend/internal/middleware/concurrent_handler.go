package middleware

import (
	"context"
	"net/http"
	"runtime"
	"strconv"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
)

// ConcurrentRequestHandler manages concurrent HTTP requests with advanced patterns
type ConcurrentRequestHandler struct {
	// Request limiting
	maxConcurrentRequests int64
	currentRequests       int64

	// Request tracking
	requestStats *RequestStats

	// Graceful degradation
	degradationThreshold int64
	degradationMode      int32 // 0: normal, 1: degraded

	// Circuit breaker
	circuitBreaker *HTTPCircuitBreaker

	// Request prioritization
	priorityQueues map[int]*RequestQueue
	queueMutex     sync.RWMutex

	// Health checking
	healthCheck HealthChecker

	// Configuration
	config ConcurrentHandlerConfig
}

// ConcurrentHandlerConfig holds configuration for concurrent request handling
type ConcurrentHandlerConfig struct {
	MaxConcurrentRequests   int64
	DegradationThreshold    int64 // Percentage of max requests to trigger degradation
	CircuitBreakerThreshold int   // Number of failures to open circuit breaker
	CircuitBreakerTimeout   time.Duration
	HealthCheckInterval     time.Duration
	RequestTimeout          time.Duration
	SlowRequestThreshold    time.Duration
	EnablePrioritization    bool
}

// RequestStats holds statistics about HTTP requests
type RequestStats struct {
	TotalRequests       int64
	ActiveRequests      int64
	CompletedRequests   int64
	FailedRequests      int64
	TimeoutRequests     int64
	DegradedRequests    int64
	AverageResponseTime time.Duration
	MaxResponseTime     time.Duration
	LastUpdateTime      time.Time
	mutex               sync.RWMutex
}

// HTTPCircuitBreaker prevents server overload
type HTTPCircuitBreaker struct {
	maxFailures  int
	resetTimeout time.Duration
	failures     int32
	lastFailure  time.Time
	state        int32 // 0: closed, 1: open, 2: half-open
	mutex        sync.RWMutex
}

// RequestQueue handles prioritized requests
type RequestQueue struct {
	requests chan *PrioritizedRequest
	priority int
	maxSize  int
}

// PrioritizedRequest represents a request with priority
type PrioritizedRequest struct {
	Context    *gin.Context
	Handler    gin.HandlerFunc
	Priority   int
	ReceivedAt time.Time
	UserID     int64
	RequestID  string
}

// HealthChecker interface for health checking
type HealthChecker interface {
	IsHealthy() bool
	GetHealthStatus() map[string]interface{}
}

// DefaultHealthChecker provides basic health checking
type DefaultHealthChecker struct {
	memoryThreshold    uint64
	goroutineThreshold int
}

// NewConcurrentRequestHandler creates a new concurrent request handler
func NewConcurrentRequestHandler(config ConcurrentHandlerConfig) *ConcurrentRequestHandler {
	// Set defaults
	if config.MaxConcurrentRequests == 0 {
		config.MaxConcurrentRequests = int64(runtime.NumCPU() * 100) // 100 requests per CPU core
	}
	if config.DegradationThreshold == 0 {
		config.DegradationThreshold = 80 // 80% of max requests
	}
	if config.CircuitBreakerThreshold == 0 {
		config.CircuitBreakerThreshold = 10
	}
	if config.CircuitBreakerTimeout == 0 {
		config.CircuitBreakerTimeout = 60 * time.Second
	}
	if config.RequestTimeout == 0 {
		config.RequestTimeout = 30 * time.Second
	}
	if config.SlowRequestThreshold == 0 {
		config.SlowRequestThreshold = 5 * time.Second
	}

	crh := &ConcurrentRequestHandler{
		maxConcurrentRequests: config.MaxConcurrentRequests,
		degradationThreshold:  (config.MaxConcurrentRequests * config.DegradationThreshold) / 100,
		requestStats:          &RequestStats{},
		circuitBreaker: &HTTPCircuitBreaker{
			maxFailures:  config.CircuitBreakerThreshold,
			resetTimeout: config.CircuitBreakerTimeout,
		},
		priorityQueues: make(map[int]*RequestQueue),
		healthCheck: &DefaultHealthChecker{
			memoryThreshold:    1024 * 1024 * 1024, // 1GB
			goroutineThreshold: 10000,              // 10k goroutines
		},
		config: config,
	}

	// Initialize priority queues if enabled
	if config.EnablePrioritization {
		crh.initializePriorityQueues()
	}

	logger.Info("Concurrent request handler initialized with max %d concurrent requests",
		config.MaxConcurrentRequests)

	return crh
}

// initializePriorityQueues initializes request priority queues
func (crh *ConcurrentRequestHandler) initializePriorityQueues() {
	// High priority queue (authenticated users, premium features)
	crh.priorityQueues[3] = &RequestQueue{
		requests: make(chan *PrioritizedRequest, 100),
		priority: 3,
		maxSize:  100,
	}

	// Medium priority queue (authenticated users)
	crh.priorityQueues[2] = &RequestQueue{
		requests: make(chan *PrioritizedRequest, 200),
		priority: 2,
		maxSize:  200,
	}

	// Low priority queue (anonymous users)
	crh.priorityQueues[1] = &RequestQueue{
		requests: make(chan *PrioritizedRequest, 300),
		priority: 1,
		maxSize:  300,
	}

	// Start queue processors
	for _, queue := range crh.priorityQueues {
		go crh.processQueue(queue)
	}
}

// Middleware returns the concurrent request handling middleware
func (crh *ConcurrentRequestHandler) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Check circuit breaker
		if crh.isCircuitBreakerOpen() {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"error":   "Service temporarily unavailable",
				"message": "System is experiencing high load. Please try again later.",
			})
			c.Abort()
			return
		}

		// Check health
		if !crh.healthCheck.IsHealthy() {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"error":   "Service health check failed",
				"message": "System is not healthy. Please try again later.",
			})
			c.Abort()
			return
		}

		// Check concurrent request limit
		currentReqs := atomic.LoadInt64(&crh.currentRequests)
		if currentReqs >= crh.maxConcurrentRequests {
			atomic.AddInt64(&crh.requestStats.FailedRequests, 1)
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":       "Too many concurrent requests",
				"message":     "Server is currently handling maximum concurrent requests. Please try again later.",
				"retry_after": "30",
			})
			c.Abort()
			return
		}

		// Increment active requests
		atomic.AddInt64(&crh.currentRequests, 1)
		atomic.AddInt64(&crh.requestStats.TotalRequests, 1)
		atomic.AddInt64(&crh.requestStats.ActiveRequests, 1)

		// Check for degradation mode
		if currentReqs >= crh.degradationThreshold {
			atomic.StoreInt32(&crh.degradationMode, 1)
		} else {
			atomic.StoreInt32(&crh.degradationMode, 0)
		}

		// Add request timeout
		ctx, cancel := context.WithTimeout(c.Request.Context(), crh.config.RequestTimeout)
		defer cancel()
		c.Request = c.Request.WithContext(ctx)

		// Track request timing
		start := time.Now()

		// Set degradation headers if in degraded mode
		if atomic.LoadInt32(&crh.degradationMode) == 1 {
			c.Header("X-Service-Mode", "degraded")
			c.Header("X-Degradation-Notice", "Service is running in degraded mode due to high load")
			atomic.AddInt64(&crh.requestStats.DegradedRequests, 1)
		}

		// Add request tracking headers
		c.Header("X-Request-ID", generateRequestID())
		c.Header("X-Active-Requests", strconv.FormatInt(currentReqs, 10))

		// Handle request with priority if enabled
		if crh.config.EnablePrioritization {
			crh.handlePrioritizedRequest(c)
		} else {
			// Process request normally
			c.Next()
		}

		// Update statistics
		duration := time.Since(start)
		crh.updateRequestStats(duration, c.Writer.Status() >= 400)
		// Check for slow requests
		if duration > crh.config.SlowRequestThreshold {
			fields := logger.Fields{
				"component":    "concurrent_handler",
				"method":       c.Request.Method,
				"path":         c.Request.URL.Path,
				"duration_ms":  duration.Milliseconds(),
				"duration":     duration.String(),
				"threshold_ms": crh.config.SlowRequestThreshold.Milliseconds(),
				"slow_request": true,
				"client_ip":    c.ClientIP(),
				"user_agent":   c.GetHeader("User-Agent"),
				"request_id":   c.GetHeader("X-Request-ID"),
			}
			logger.WarnWithFields(fields, "Slow request detected")
		}

		// Decrement active requests
		atomic.AddInt64(&crh.currentRequests, -1)
		atomic.AddInt64(&crh.requestStats.ActiveRequests, -1)
		atomic.AddInt64(&crh.requestStats.CompletedRequests, 1)

		// Handle context timeout
		if ctx.Err() == context.DeadlineExceeded {
			atomic.AddInt64(&crh.requestStats.TimeoutRequests, 1)
			crh.recordFailure()
		} else if c.Writer.Status() >= 400 {
			crh.recordFailure()
		} else {
			crh.recordSuccess()
		}
	}
}

// handlePrioritizedRequest handles requests with prioritization
func (crh *ConcurrentRequestHandler) handlePrioritizedRequest(c *gin.Context) {
	priority := crh.determineRequestPriority(c)

	// Create prioritized request
	req := &PrioritizedRequest{
		Context:    c,
		Priority:   priority,
		ReceivedAt: time.Now(),
		RequestID:  c.GetHeader("X-Request-ID"),
	}

	// Get user ID if available
	if userID, exists := c.Get("user_id"); exists {
		if id, ok := userID.(int64); ok {
			req.UserID = id
		}
	}

	// Try to queue the request
	crh.queueMutex.RLock()
	queue, exists := crh.priorityQueues[priority]
	crh.queueMutex.RUnlock()

	if !exists {
		// Fallback to normal processing
		c.Next()
		return
	}

	// Try to add to queue (non-blocking)
	select {
	case queue.requests <- req:
		// Request queued successfully, wait for processing
		<-c.Done()
	default:
		// Queue is full, handle immediately
		c.Next()
	}
}

// processQueue processes requests from a priority queue
func (crh *ConcurrentRequestHandler) processQueue(queue *RequestQueue) {
	for req := range queue.requests { // Process the request
		req.Context.Next()

		// Request completed - context cleanup happens automatically
	}
}

// determineRequestPriority determines the priority of a request
func (crh *ConcurrentRequestHandler) determineRequestPriority(c *gin.Context) int {
	// Check if user is authenticated
	if _, exists := c.Get("authorization_payload"); exists {
		// Check for premium endpoints or admin routes
		path := c.Request.URL.Path
		if isHighPriorityPath(path) {
			return 3 // High priority
		}
		return 2 // Medium priority (authenticated)
	}

	return 1 // Low priority (anonymous)
}

// isHighPriorityPath checks if a path should have high priority
func isHighPriorityPath(path string) bool {
	highPriorityPaths := []string{
		"/api/v1/admin/",
		"/api/v1/backup/",
		"/api/v1/health",
		"/api/v1/metrics",
	}

	for _, highPath := range highPriorityPaths {
		if len(path) >= len(highPath) && path[:len(highPath)] == highPath {
			return true
		}
	}

	return false
}

// updateRequestStats updates request statistics
func (crh *ConcurrentRequestHandler) updateRequestStats(duration time.Duration, isError bool) {
	crh.requestStats.mutex.Lock()
	defer crh.requestStats.mutex.Unlock()

	if isError {
		crh.requestStats.FailedRequests++
	}

	// Update timing statistics
	if duration > crh.requestStats.MaxResponseTime {
		crh.requestStats.MaxResponseTime = duration
	}

	// Simple moving average for response time
	if crh.requestStats.AverageResponseTime == 0 {
		crh.requestStats.AverageResponseTime = duration
	} else {
		crh.requestStats.AverageResponseTime = (crh.requestStats.AverageResponseTime + duration) / 2
	}

	crh.requestStats.LastUpdateTime = time.Now()
}

// isCircuitBreakerOpen checks if the circuit breaker is open
func (crh *ConcurrentRequestHandler) isCircuitBreakerOpen() bool {
	crh.circuitBreaker.mutex.RLock()
	defer crh.circuitBreaker.mutex.RUnlock()

	state := atomic.LoadInt32(&crh.circuitBreaker.state)

	// Reset circuit breaker if timeout has passed
	if state == 1 && time.Since(crh.circuitBreaker.lastFailure) > crh.circuitBreaker.resetTimeout {
		atomic.StoreInt32(&crh.circuitBreaker.state, 2) // Half-open
		atomic.StoreInt32(&crh.circuitBreaker.failures, 0)
	}

	return state == 1 // Open
}

// recordFailure records a request failure
func (crh *ConcurrentRequestHandler) recordFailure() {
	failures := atomic.AddInt32(&crh.circuitBreaker.failures, 1)
	crh.circuitBreaker.mutex.Lock()
	crh.circuitBreaker.lastFailure = time.Now()
	crh.circuitBreaker.mutex.Unlock()

	if failures >= int32(crh.circuitBreaker.maxFailures) {
		atomic.StoreInt32(&crh.circuitBreaker.state, 1) // Open
		fields := logger.Fields{
			"component":    "circuit_breaker",
			"failures":     failures,
			"max_failures": crh.circuitBreaker.maxFailures,
			"state":        "open",
			"last_failure": time.Now().Format(time.RFC3339),
		}
		logger.WarnWithFields(fields, "HTTP circuit breaker opened due to failures")
	}
}

// recordSuccess records a successful request
func (crh *ConcurrentRequestHandler) recordSuccess() {
	state := atomic.LoadInt32(&crh.circuitBreaker.state)
	if state == 2 { // Half-open
		atomic.StoreInt32(&crh.circuitBreaker.state, 0) // Closed
		atomic.StoreInt32(&crh.circuitBreaker.failures, 0)
		fields := logger.Fields{
			"component": "circuit_breaker",
			"state":     "closed",
			"event":     "recovery",
		}
		logger.InfoWithFields(fields, "HTTP circuit breaker closed after successful request")
	}
}

// GetStats returns current request statistics
func (crh *ConcurrentRequestHandler) GetStats() *RequestStats {
	crh.requestStats.mutex.RLock()
	defer crh.requestStats.mutex.RUnlock()

	return &RequestStats{
		TotalRequests:       atomic.LoadInt64(&crh.requestStats.TotalRequests),
		ActiveRequests:      atomic.LoadInt64(&crh.requestStats.ActiveRequests),
		CompletedRequests:   atomic.LoadInt64(&crh.requestStats.CompletedRequests),
		FailedRequests:      atomic.LoadInt64(&crh.requestStats.FailedRequests),
		TimeoutRequests:     atomic.LoadInt64(&crh.requestStats.TimeoutRequests),
		DegradedRequests:    atomic.LoadInt64(&crh.requestStats.DegradedRequests),
		AverageResponseTime: crh.requestStats.AverageResponseTime,
		MaxResponseTime:     crh.requestStats.MaxResponseTime,
		LastUpdateTime:      crh.requestStats.LastUpdateTime,
	}
}

// ResetStats resets all request statistics
func (crh *ConcurrentRequestHandler) ResetStats() error {
	logger.Info("Resetting concurrent request handler statistics...")

	crh.requestStats.mutex.Lock()
	defer crh.requestStats.mutex.Unlock()

	// Reset atomic counters
	atomic.StoreInt64(&crh.requestStats.TotalRequests, 0)
	atomic.StoreInt64(&crh.requestStats.ActiveRequests, 0)
	atomic.StoreInt64(&crh.requestStats.CompletedRequests, 0)
	atomic.StoreInt64(&crh.requestStats.FailedRequests, 0)
	atomic.StoreInt64(&crh.requestStats.TimeoutRequests, 0)
	atomic.StoreInt64(&crh.requestStats.DegradedRequests, 0)

	// Reset response time metrics
	crh.requestStats.AverageResponseTime = 0
	crh.requestStats.MaxResponseTime = 0
	crh.requestStats.LastUpdateTime = time.Now()

	// Reset degradation mode
	atomic.StoreInt32(&crh.degradationMode, 0)
	// Reset circuit breaker
	if crh.circuitBreaker != nil {
		crh.circuitBreaker.mutex.Lock()
		atomic.StoreInt32(&crh.circuitBreaker.failures, 0)
		atomic.StoreInt32(&crh.circuitBreaker.state, 0) // closed
		crh.circuitBreaker.lastFailure = time.Time{}
		crh.circuitBreaker.mutex.Unlock()
	}

	// Clear priority queues
	crh.queueMutex.Lock()
	for priority := range crh.priorityQueues {
		// Drain the queue
		for len(crh.priorityQueues[priority].requests) > 0 {
			<-crh.priorityQueues[priority].requests
		}
	}
	crh.queueMutex.Unlock()

	logger.Info("Concurrent request handler statistics reset successfully")
	return nil
}

// IsHealthy implements HealthChecker interface
func (dhc *DefaultHealthChecker) IsHealthy() bool {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	// Check memory usage
	if m.Alloc > dhc.memoryThreshold {
		return false
	}

	// Check goroutine count
	if runtime.NumGoroutine() > dhc.goroutineThreshold {
		return false
	}

	return true
}

// GetHealthStatus implements HealthChecker interface
func (dhc *DefaultHealthChecker) GetHealthStatus() map[string]interface{} {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	return map[string]interface{}{
		"memory_allocated":    m.Alloc,
		"memory_threshold":    dhc.memoryThreshold,
		"goroutines":          runtime.NumGoroutine(),
		"goroutine_threshold": dhc.goroutineThreshold,
		"healthy":             dhc.IsHealthy(),
	}
}

// generateRequestID generates a unique request ID
func generateRequestID() string {
	return strconv.FormatInt(time.Now().UnixNano(), 36)
}
