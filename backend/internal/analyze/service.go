package analyze

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
)

// Service represents the analyze service wrapper
type Service struct {
	client          *AnalyzeClient
	config          config.Config
	resultCache     map[string]*AnalysisResult
	cacheMutex      sync.RWMutex
	cacheTimeout    time.Duration
	maxCacheSize    int
	requestCounter  int64
	healthStatus    bool
	lastHealthCheck time.Time
	healthMutex     sync.RWMutex
}

// ServiceConfig holds configuration for the analyze service
type ServiceConfig struct {
	BaseURL             string        `mapstructure:"analyze_service_url"`
	Timeout             time.Duration `mapstructure:"analyze_service_timeout"`
	CacheTimeout        time.Duration `mapstructure:"analyze_cache_timeout"`
	MaxCacheSize        int           `mapstructure:"analyze_max_cache_size"`
	HealthCheckInterval time.Duration `mapstructure:"analyze_health_check_interval"`
}

// NewService creates a new analyze service wrapper
func NewService(cfg config.Config) *Service {
	// Set default values
	serviceConfig := ServiceConfig{
		BaseURL:             "http://localhost:9000", // Default analyze service URL
		Timeout:             30 * time.Second,
		CacheTimeout:        10 * time.Minute,
		MaxCacheSize:        1000,
		HealthCheckInterval: 30 * time.Second,
	}

	// Override with config values if available
	if cfg.AnalyzeServiceURL != "" {
		serviceConfig.BaseURL = cfg.AnalyzeServiceURL
	}
	if cfg.AnalyzeServiceTimeout > 0 {
		serviceConfig.Timeout = cfg.AnalyzeServiceTimeout
	}

	client := NewAnalyzeClient(serviceConfig.BaseURL, serviceConfig.Timeout)

	service := &Service{
		client:       client,
		config:       cfg,
		resultCache:  make(map[string]*AnalysisResult),
		cacheTimeout: serviceConfig.CacheTimeout,
		maxCacheSize: serviceConfig.MaxCacheSize,
		healthStatus: false,
	}

	// Start health monitoring
	go service.startHealthMonitoring(serviceConfig.HealthCheckInterval)

	logger.Info("Analyze service initialized with URL: %s", serviceConfig.BaseURL)
	return service
}

// startHealthMonitoring starts a goroutine to periodically check service health
func (s *Service) startHealthMonitoring(interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for range ticker.C {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		healthy := s.client.IsHealthy(ctx)
		cancel()

		s.healthMutex.Lock()
		s.healthStatus = healthy
		s.lastHealthCheck = time.Now()
		s.healthMutex.Unlock()

		if healthy {
			logger.Debug("Analyze service health check passed")
		} else {
			logger.Warn("Analyze service health check failed")
		}
	}
}

// IsHealthy returns the current health status of the analyze service
func (s *Service) IsHealthy() bool {
	s.healthMutex.RLock()
	defer s.healthMutex.RUnlock()
	return s.healthStatus
}

// GetHealthStatus returns detailed health information
func (s *Service) GetHealthStatus() (bool, time.Time) {
	s.healthMutex.RLock()
	defer s.healthMutex.RUnlock()
	return s.healthStatus, s.lastHealthCheck
}

// generateCacheKey generates a cache key for the request
func (s *Service) generateCacheKey(userID int32, text string, minLevel string) string {
	return fmt.Sprintf("%d:%s:%s", userID, text, minLevel)
}

// getCachedResult retrieves a cached result if available and not expired
func (s *Service) getCachedResult(key string) *AnalysisResult {
	s.cacheMutex.RLock()
	defer s.cacheMutex.RUnlock()

	result, exists := s.resultCache[key]
	if !exists {
		return nil
	}

	// Check if cache entry is expired
	if time.Since(result.Timestamp) > s.cacheTimeout {
		// Remove expired entry (will be cleaned up later)
		delete(s.resultCache, key)
		return nil
	}

	return result
}

// setCachedResult stores a result in the cache
func (s *Service) setCachedResult(key string, result *AnalysisResult) {
	s.cacheMutex.Lock()
	defer s.cacheMutex.Unlock()

	// If cache is full, remove oldest entries
	if len(s.resultCache) >= s.maxCacheSize {
		s.cleanupCache()
	}

	s.resultCache[key] = result
}

// cleanupCache removes expired entries and oldest entries if cache is full
func (s *Service) cleanupCache() {
	now := time.Now()
	for key, result := range s.resultCache {
		if now.Sub(result.Timestamp) > s.cacheTimeout {
			delete(s.resultCache, key)
		}
	}

	// If still too full, remove oldest entries
	if len(s.resultCache) >= s.maxCacheSize {
		// Convert to slice and sort by timestamp, remove oldest
		type entry struct {
			key    string
			result *AnalysisResult
		}

		entries := make([]entry, 0, len(s.resultCache))
		for k, v := range s.resultCache {
			entries = append(entries, entry{k, v})
		}

		// Remove oldest 25% of entries
		removeCount := len(entries) / 4
		if removeCount == 0 {
			removeCount = 1
		}

		// Sort by timestamp (oldest first)
		for i := 0; i < len(entries)-1; i++ {
			for j := i + 1; j < len(entries); j++ {
				if entries[i].result.Timestamp.After(entries[j].result.Timestamp) {
					entries[i], entries[j] = entries[j], entries[i]
				}
			}
		}

		// Remove oldest entries
		for i := 0; i < removeCount && i < len(entries); i++ {
			delete(s.resultCache, entries[i].key)
		}
	}
}

// AnalyzeTextSync performs synchronous text analysis with caching
func (s *Service) AnalyzeTextSync(ctx context.Context, userID int32, text string, minSynonymLevel string) (*AnalysisResult, error) {
	// Check cache first
	cacheKey := s.generateCacheKey(userID, text, minSynonymLevel)
	if cached := s.getCachedResult(cacheKey); cached != nil {
		logger.Debug("Returning cached analysis result for user %d", userID)
		return cached, nil
	}

	// Check if service is healthy
	if !s.IsHealthy() {
		return nil, fmt.Errorf("analyze service is not healthy")
	}

	request := TextAnalysisRequest{
		Text:            text,
		MinSynonymLevel: minSynonymLevel,
	}

	analysisResponse, err := s.client.AnalyzeText(ctx, request)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze text: %w", err)
	}

	result := &AnalysisResult{
		UserID:    userID,
		Text:      text,
		Result:    analysisResponse,
		Timestamp: time.Now(),
	}

	// Cache the result
	s.setCachedResult(cacheKey, result)

	logger.Debug("Text analysis completed for user %d", userID)
	return result, nil
}

// AnalyzeTextAsync performs asynchronous text analysis
func (s *Service) AnalyzeTextAsync(ctx context.Context, userID int32, text string, minSynonymLevel string, callback func(*AnalysisResult, error)) {
	go func() {
		logger.Debug("Starting async text analysis for user %d", userID)

		result, err := s.AnalyzeTextSync(ctx, userID, text, minSynonymLevel)

		// Call the callback function with the result
		if callback != nil {
			callback(result, err)
		}
	}()
}

// AnalyzeTextWithChannel performs asynchronous text analysis using channels
func (s *Service) AnalyzeTextWithChannel(ctx context.Context, userID int32, text string, minSynonymLevel string) <-chan struct {
	Result *AnalysisResult
	Error  error
} {
	resultChan := make(chan struct {
		Result *AnalysisResult
		Error  error
	}, 1)

	go func() {
		defer close(resultChan)

		result, err := s.AnalyzeTextSync(ctx, userID, text, minSynonymLevel)

		select {
		case resultChan <- struct {
			Result *AnalysisResult
			Error  error
		}{result, err}:
		case <-ctx.Done():
			logger.Warn("Context cancelled during async analysis for user %d", userID)
		}
	}()

	return resultChan
}

// AnalyzeMultipleTexts performs analysis of multiple texts concurrently
func (s *Service) AnalyzeMultipleTexts(ctx context.Context, userID int32, texts []string, minSynonymLevel string) <-chan struct {
	Results []AnalysisResult
	Error   error
} {
	resultChan := make(chan struct {
		Results []AnalysisResult
		Error   error
	}, 1)

	go func() {
		defer close(resultChan)

		if !s.IsHealthy() {
			select {
			case resultChan <- struct {
				Results []AnalysisResult
				Error   error
			}{nil, fmt.Errorf("analyze service is not healthy")}:
			case <-ctx.Done():
			}
			return
		}

		results := make([]AnalysisResult, len(texts))

		// Use a worker pool to limit concurrent requests
		maxWorkers := 3
		if len(texts) < maxWorkers {
			maxWorkers = len(texts)
		}

		type job struct {
			index int
			text  string
		}

		jobs := make(chan job, len(texts))
		resultsChan := make(chan struct {
			index  int
			result AnalysisResult
			err    error
		}, len(texts))

		// Start workers
		for w := 0; w < maxWorkers; w++ {
			go func() {
				for j := range jobs {
					result, err := s.AnalyzeTextSync(ctx, userID, j.text, minSynonymLevel)

					var analysisResult AnalysisResult
					if err != nil {
						analysisResult = AnalysisResult{
							UserID:    userID,
							Text:      j.text,
							Error:     err.Error(),
							Timestamp: time.Now(),
						}
					} else {
						analysisResult = *result
					}

					select {
					case resultsChan <- struct {
						index  int
						result AnalysisResult
						err    error
					}{j.index, analysisResult, err}:
					case <-ctx.Done():
						return
					}
				}
			}()
		}

		// Send jobs
		for i, text := range texts {
			select {
			case jobs <- job{i, text}:
			case <-ctx.Done():
				close(jobs)
				return
			}
		}
		close(jobs)

		// Collect results
		for i := 0; i < len(texts); i++ {
			select {
			case res := <-resultsChan:
				results[res.index] = res.result
			case <-ctx.Done():
				return
			}
		}

		select {
		case resultChan <- struct {
			Results []AnalysisResult
			Error   error
		}{results, nil}:
		case <-ctx.Done():
		}
	}()

	return resultChan
}

// GetCacheStats returns cache statistics
func (s *Service) GetCacheStats() map[string]interface{} {
	s.cacheMutex.RLock()
	defer s.cacheMutex.RUnlock()

	return map[string]interface{}{
		"cache_size":     len(s.resultCache),
		"max_cache_size": s.maxCacheSize,
		"cache_timeout":  s.cacheTimeout.String(),
	}
}

// ClearCache clears all cached results
func (s *Service) ClearCache() {
	s.cacheMutex.Lock()
	defer s.cacheMutex.Unlock()

	s.resultCache = make(map[string]*AnalysisResult)
	logger.Info("Analyze service cache cleared")
}

// GetStats returns service statistics
func (s *Service) GetStats() map[string]interface{} {
	healthy, lastCheck := s.GetHealthStatus()
	cacheStats := s.GetCacheStats()

	stats := map[string]interface{}{
		"healthy":           healthy,
		"last_health_check": lastCheck.Format(time.RFC3339),
		"request_count":     s.requestCounter,
		"service_url":       s.client.baseURL,
		"timeout":           s.client.timeout.String(),
	}

	// Merge cache stats
	for k, v := range cacheStats {
		stats[k] = v
	}

	return stats
}
