package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/toeic-app/internal/logger"
)

// CacheManager coordinates all cache operations and provides advanced features
type CacheManager struct {
	primaryCache      Cache
	distributedCache  *DistributedCache
	warmer            *CacheWarmer
	config            CacheManagerConfig
	metrics           *CacheMetrics
	invalidationQueue chan InvalidationJob
	stopChan          chan struct{}
	isRunning         bool
	mutex             sync.RWMutex
}

// CacheManagerConfig holds configuration for the cache manager
type CacheManagerConfig struct {
	EnableDistributed     bool
	EnableWarming         bool
	EnableInvalidation    bool
	MetricsEnabled        bool
	InvalidationWorkers   int
	InvalidationQueueSize int

	// Advanced features
	CompressionEnabled   bool
	CompressionThreshold int // Compress values larger than this size

	// Cache policies
	MaxMemoryUsage int64  // Max memory usage in bytes
	EvictionPolicy string // "lru", "lfu", "ttl"

	// Monitoring
	AlertThresholds AlertThresholds
}

// CacheMetrics tracks cache performance metrics
type CacheMetrics struct {
	Hits            int64
	Misses          int64
	Sets            int64
	Deletes         int64
	Evictions       int64
	Errors          int64
	TotalOperations int64
	AverageLatency  time.Duration
	MemoryUsage     int64
	mutex           sync.RWMutex
	latencyHistory  []time.Duration
}

// AlertThresholds defines when to trigger alerts
type AlertThresholds struct {
	HitRateBelow     float64       // Alert if hit rate drops below this
	LatencyAbove     time.Duration // Alert if latency exceeds this
	ErrorRateAbove   float64       // Alert if error rate exceeds this
	MemoryUsageAbove float64       // Alert if memory usage exceeds this percent
}

// InvalidationJob represents a cache invalidation task
type InvalidationJob struct {
	Type      string // "key", "pattern", "tag"
	Target    string // Key, pattern, or tag
	Timestamp time.Time
	Priority  int
}

// NewCacheManager creates a new cache manager
func NewCacheManager(primaryCache Cache, config CacheManagerConfig) *CacheManager {
	cm := &CacheManager{
		primaryCache:      primaryCache,
		config:            config,
		metrics:           &CacheMetrics{latencyHistory: make([]time.Duration, 0, 100)},
		invalidationQueue: make(chan InvalidationJob, config.InvalidationQueueSize),
		stopChan:          make(chan struct{}),
	}

	// Start invalidation workers
	if config.EnableInvalidation {
		cm.startInvalidationWorkers()
	}

	return cm
}

// SetDistributedCache sets the distributed cache
func (cm *CacheManager) SetDistributedCache(dc *DistributedCache) {
	cm.distributedCache = dc
}

// SetWarmer sets the cache warmer
func (cm *CacheManager) SetWarmer(warmer *CacheWarmer) {
	cm.warmer = warmer
}

// Start starts the cache manager
func (cm *CacheManager) Start(ctx context.Context) error {
	cm.mutex.Lock()
	defer cm.mutex.Unlock()

	if cm.isRunning {
		return fmt.Errorf("cache manager is already running")
	}

	cm.isRunning = true

	// Start cache warmer if enabled
	if cm.config.EnableWarming && cm.warmer != nil {
		if err := cm.warmer.Start(ctx); err != nil {
			logger.Error("Failed to start cache warmer: %v", err)
		}
	}

	logger.Info("Cache manager started successfully")
	return nil
}

// Stop stops the cache manager
func (cm *CacheManager) Stop() {
	cm.mutex.Lock()
	defer cm.mutex.Unlock()

	if !cm.isRunning {
		return
	}

	close(cm.stopChan)
	cm.isRunning = false

	// Stop warmer
	if cm.warmer != nil {
		cm.warmer.Stop()
	}

	logger.Info("Cache manager stopped")
}

// Get retrieves a value with metrics tracking
func (cm *CacheManager) Get(ctx context.Context, key string) ([]byte, error) {
	start := time.Now()

	var data []byte
	var err error

	// Try distributed cache first if enabled
	if cm.config.EnableDistributed && cm.distributedCache != nil {
		data, err = cm.distributedCache.Get(ctx, key)
	} else {
		data, err = cm.primaryCache.Get(ctx, key)
	}

	// Update metrics
	cm.updateMetrics(start, err == nil, false, false, false)

	// Decompress if needed
	if err == nil && cm.config.CompressionEnabled {
		data = cm.decompress(data)
	}

	return data, err
}

// Set stores a value with compression and metrics
func (cm *CacheManager) Set(ctx context.Context, key string, value []byte, expiration time.Duration) error {
	start := time.Now()

	// Compress if enabled and value is large enough
	if cm.config.CompressionEnabled && len(value) > cm.config.CompressionThreshold {
		value = cm.compress(value)
	}

	var err error
	if cm.config.EnableDistributed && cm.distributedCache != nil {
		err = cm.distributedCache.Set(ctx, key, value, expiration)
	} else {
		err = cm.primaryCache.Set(ctx, key, value, expiration)
	}

	cm.updateMetrics(start, false, true, false, false)
	return err
}

// SetWithTags sets a value with tags for advanced invalidation
func (cm *CacheManager) SetWithTags(ctx context.Context, key string, value []byte, expiration time.Duration, tags []string) error {
	// If using Redis cache with tag support
	if redisCache, ok := cm.primaryCache.(*RedisCache); ok {
		return redisCache.SetWithTags(ctx, key, value, expiration, tags)
	}

	// Fallback to regular set
	return cm.Set(ctx, key, value, expiration)
}

// Delete removes a key
func (cm *CacheManager) Delete(ctx context.Context, key string) error {
	start := time.Now()

	var err error
	if cm.config.EnableDistributed && cm.distributedCache != nil {
		err = cm.distributedCache.Delete(ctx, key)
	} else {
		err = cm.primaryCache.Delete(ctx, key)
	}

	cm.updateMetrics(start, false, false, true, false)
	return err
}

// InvalidateByTag invalidates all keys with a specific tag
func (cm *CacheManager) InvalidateByTag(ctx context.Context, tag string) error {
	if redisCache, ok := cm.primaryCache.(*RedisCache); ok {
		return redisCache.InvalidateByTag(ctx, tag)
	}

	// For other cache types, this is a no-op
	logger.Warn("Tag-based invalidation not supported for cache type")
	return nil
}

// InvalidateByPattern invalidates keys matching a pattern
func (cm *CacheManager) InvalidateByPattern(ctx context.Context, pattern string) error {
	if redisCache, ok := cm.primaryCache.(*RedisCache); ok {
		return redisCache.DeleteByPattern(ctx, pattern)
	}

	// Fallback to clearing all cache
	return cm.primaryCache.Clear(ctx)
}

// QueueInvalidation queues an invalidation job for async processing
func (cm *CacheManager) QueueInvalidation(invalidationType, target string, priority int) {
	if !cm.config.EnableInvalidation {
		return
	}

	job := InvalidationJob{
		Type:      invalidationType,
		Target:    target,
		Timestamp: time.Now(),
		Priority:  priority,
	}

	select {
	case cm.invalidationQueue <- job:
		// Queued successfully
	default:
		logger.Warn("Invalidation queue is full, dropping job: %s %s", invalidationType, target)
	}
}

// GetOrSetWithCallback retrieves from cache or calls function and caches result
func (cm *CacheManager) GetOrSetWithCallback(ctx context.Context, key string, ttl time.Duration,
	fetchFunc func() (interface{}, error), result interface{}) error {

	// Try to get from cache first
	data, err := cm.Get(ctx, key)
	if err == nil {
		return json.Unmarshal(data, result)
	}

	// Cache miss, execute function
	fetchedData, err := fetchFunc()
	if err != nil {
		return err
	}

	// Cache the result asynchronously
	go func() {
		if jsonData, err := json.Marshal(fetchedData); err == nil {
			cm.Set(context.Background(), key, jsonData, ttl)
		}
	}()

	// Set the result
	return cm.setResult(fetchedData, result)
}

// GetMultiple retrieves multiple keys at once (Redis optimization)
func (cm *CacheManager) GetMultiple(ctx context.Context, keys []string) (map[string][]byte, error) {
	if redisCache, ok := cm.primaryCache.(*RedisCache); ok {
		return redisCache.GetMultiple(ctx, keys)
	}

	// Fallback for other cache types
	result := make(map[string][]byte)
	for _, key := range keys {
		if data, err := cm.Get(ctx, key); err == nil {
			result[key] = data
		}
	}
	return result, nil
}

// SetMultiple sets multiple keys at once (Redis optimization)
func (cm *CacheManager) SetMultiple(ctx context.Context, items map[string][]byte, expiration time.Duration) error {
	if redisCache, ok := cm.primaryCache.(*RedisCache); ok {
		return redisCache.SetMultiple(ctx, items, expiration)
	}

	// Fallback for other cache types
	for key, value := range items {
		if err := cm.Set(ctx, key, value, expiration); err != nil {
			return err
		}
	}
	return nil
}

// WarmCache manually triggers cache warming
func (cm *CacheManager) WarmCache(ctx context.Context) error {
	if cm.warmer == nil {
		return fmt.Errorf("cache warmer not configured")
	}

	// This would trigger an immediate warmup
	logger.Info("Manual cache warming triggered")
	return nil // Implementation would call warmer.performWarmup
}

// GetStats returns comprehensive cache statistics
func (cm *CacheManager) GetStats(ctx context.Context) map[string]interface{} {
	stats := make(map[string]interface{})

	// Primary cache stats
	if cm.primaryCache != nil {
		// This would require extending the Cache interface to include GetStats
		stats["primary_cache"] = "active"
	}

	// Distributed cache stats
	if cm.distributedCache != nil {
		stats["distributed_cache"] = cm.distributedCache.GetStats(ctx)
	}

	// Warmer stats
	if cm.warmer != nil {
		stats["cache_warmer"] = cm.warmer.GetStats()
	}

	// Metrics
	cm.metrics.mutex.RLock()
	stats["metrics"] = map[string]interface{}{
		"hits":             cm.metrics.Hits,
		"misses":           cm.metrics.Misses,
		"sets":             cm.metrics.Sets,
		"deletes":          cm.metrics.Deletes,
		"evictions":        cm.metrics.Evictions,
		"errors":           cm.metrics.Errors,
		"total_operations": cm.metrics.TotalOperations,
		"hit_rate":         cm.getHitRate(),
		"average_latency":  cm.metrics.AverageLatency.String(),
		"memory_usage":     cm.metrics.MemoryUsage,
	}
	cm.metrics.mutex.RUnlock()

	return stats
}

// GetHealthStatus returns health status of all cache components
func (cm *CacheManager) GetHealthStatus(ctx context.Context) map[string]interface{} {
	health := make(map[string]interface{})

	// Test primary cache
	testKey := "health_check_" + fmt.Sprintf("%d", time.Now().Unix())
	testValue := []byte("health_check")

	if err := cm.primaryCache.Set(ctx, testKey, testValue, time.Minute); err != nil {
		health["primary_cache"] = "unhealthy: " + err.Error()
	} else {
		if _, err := cm.primaryCache.Get(ctx, testKey); err != nil {
			health["primary_cache"] = "unhealthy: read failed"
		} else {
			health["primary_cache"] = "healthy"
			cm.primaryCache.Delete(ctx, testKey) // Cleanup
		}
	}

	// Distributed cache health
	if cm.distributedCache != nil {
		health["distributed_cache"] = cm.distributedCache.GetHealthStatus()
	}

	// Cache warmer health
	if cm.warmer != nil {
		warmerStats := cm.warmer.GetStats()
		health["cache_warmer"] = map[string]interface{}{
			"last_run":     warmerStats.LastRun,
			"success_rate": warmerStats.SuccessRate,
			"error_count":  warmerStats.ErrorCount,
		}
	}

	return health
}

// updateMetrics updates cache performance metrics
func (cm *CacheManager) updateMetrics(start time.Time, hit, set, delete, eviction bool) {
	if !cm.config.MetricsEnabled {
		return
	}

	latency := time.Since(start)

	cm.metrics.mutex.Lock()
	defer cm.metrics.mutex.Unlock()

	cm.metrics.TotalOperations++

	if hit {
		cm.metrics.Hits++
	} else if !set && !delete {
		cm.metrics.Misses++
	}

	if set {
		cm.metrics.Sets++
	}

	if delete {
		cm.metrics.Deletes++
	}

	if eviction {
		cm.metrics.Evictions++
	}

	// Update latency
	cm.metrics.latencyHistory = append(cm.metrics.latencyHistory, latency)
	if len(cm.metrics.latencyHistory) > 100 {
		cm.metrics.latencyHistory = cm.metrics.latencyHistory[1:]
	}

	// Calculate average latency
	var total time.Duration
	for _, l := range cm.metrics.latencyHistory {
		total += l
	}
	cm.metrics.AverageLatency = total / time.Duration(len(cm.metrics.latencyHistory))
}

// getHitRate calculates the cache hit rate
func (cm *CacheManager) getHitRate() float64 {
	total := cm.metrics.Hits + cm.metrics.Misses
	if total == 0 {
		return 0
	}
	return float64(cm.metrics.Hits) / float64(total) * 100
}

// startInvalidationWorkers starts background workers for async invalidation
func (cm *CacheManager) startInvalidationWorkers() {
	for i := 0; i < cm.config.InvalidationWorkers; i++ {
		go func(workerID int) {
			logger.Debug("Starting cache invalidation worker %d", workerID)
			for {
				select {
				case job := <-cm.invalidationQueue:
					cm.processInvalidationJob(job)
				case <-cm.stopChan:
					logger.Debug("Stopping cache invalidation worker %d", workerID)
					return
				}
			}
		}(i)
	}
}

// processInvalidationJob processes a cache invalidation job
func (cm *CacheManager) processInvalidationJob(job InvalidationJob) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	switch job.Type {
	case "key":
		cm.Delete(ctx, job.Target)
	case "pattern":
		cm.InvalidateByPattern(ctx, job.Target)
	case "tag":
		cm.InvalidateByTag(ctx, job.Target)
	default:
		logger.Warn("Unknown invalidation job type: %s", job.Type)
	}
}

// Helper methods

func (cm *CacheManager) compress(data []byte) []byte {
	// Implement compression (e.g., gzip)
	// For now, return as-is
	return data
}

func (cm *CacheManager) decompress(data []byte) []byte {
	// Implement decompression
	// For now, return as-is
	return data
}

func (cm *CacheManager) setResult(data interface{}, result interface{}) error {
	// JSON marshal/unmarshal for type conversion
	jsonData, err := json.Marshal(data)
	if err != nil {
		return err
	}
	return json.Unmarshal(jsonData, result)
}

// DefaultCacheManagerConfig returns default configuration
func DefaultCacheManagerConfig() CacheManagerConfig {
	return CacheManagerConfig{
		EnableDistributed:     false,
		EnableWarming:         true,
		EnableInvalidation:    true,
		MetricsEnabled:        true,
		InvalidationWorkers:   3,
		InvalidationQueueSize: 1000,
		CompressionEnabled:    false,
		CompressionThreshold:  1024,              // 1KB
		MaxMemoryUsage:        100 * 1024 * 1024, // 100MB
		EvictionPolicy:        "lru",
		AlertThresholds: AlertThresholds{
			HitRateBelow:     80.0, // Alert if hit rate below 80%
			LatencyAbove:     100 * time.Millisecond,
			ErrorRateAbove:   5.0,
			MemoryUsageAbove: 90.0,
		},
	}
}
