package monitoring

import (
	"context"
	"runtime"
	"sync"
	"sync/atomic"
	"time"

	"github.com/toeic-app/internal/logger"
)

// PerformanceOptimizer handles performance monitoring and optimization
type PerformanceOptimizer struct {
	metrics        *PerformanceMetrics
	config         *PerformanceConfig
	alertManager   *AlertManager
	running        bool
	stopCh         chan struct{}
	mutex          sync.RWMutex
	metricsHistory []PerformanceSnapshot
	maxHistorySize int
}

// PerformanceConfig holds performance optimization configuration
type PerformanceConfig struct {
	Enabled             bool
	MetricsInterval     time.Duration
	AlertingEnabled     bool
	OptimizationEnabled bool
	MaxHistorySize      int

	// Thresholds for performance alerts
	MaxResponseTime      time.Duration
	MaxErrorRate         float64
	MaxMemoryUsage       int64
	MinCacheHitRate      float64
	MaxDatabaseQueryTime time.Duration
	MaxConcurrentConns   int64
}

// PerformanceMetrics holds real-time performance data
type PerformanceMetrics struct {
	// Request metrics (atomic counters for thread safety)
	TotalRequests      int64
	SuccessfulRequests int64
	FailedRequests     int64

	// Timing metrics
	TotalResponseTime int64 // nanoseconds
	MinResponseTime   int64
	MaxResponseTime   int64

	// Concurrency metrics
	ActiveConnections int64
	PeakConnections   int64

	// Cache metrics
	CacheHits       int64
	CacheMisses     int64
	CacheOperations int64

	// Database metrics
	DatabaseQueries int64
	DatabaseErrors  int64
	TotalQueryTime  int64

	// Memory metrics
	MemoryAllocated int64
	MemoryUsed      int64
	GCPauses        int64

	// System metrics
	GoroutineCount int64
	CPUUsage       int64 // percentage * 100

	// Timestamps
	StartTime   time.Time
	LastUpdated time.Time
}

// PerformanceSnapshot represents metrics at a point in time
type PerformanceSnapshot struct {
	Timestamp           time.Time
	RequestsPerSecond   float64
	AverageResponseTime time.Duration
	ErrorRate           float64
	CacheHitRate        float64
	MemoryUsage         int64
	ActiveConnections   int64
}

// NewPerformanceOptimizer creates a new performance optimizer
func NewPerformanceOptimizer(config *PerformanceConfig) *PerformanceOptimizer {
	if config == nil {
		config = &PerformanceConfig{
			Enabled:              true,
			MetricsInterval:      30 * time.Second,
			AlertingEnabled:      true,
			OptimizationEnabled:  true,
			MaxHistorySize:       100,
			MaxResponseTime:      2 * time.Second,
			MaxErrorRate:         0.05,    // 5%
			MaxMemoryUsage:       1 << 30, // 1GB
			MinCacheHitRate:      0.80,    // 80%
			MaxDatabaseQueryTime: 500 * time.Millisecond,
			MaxConcurrentConns:   1000,
		}
	}
	return &PerformanceOptimizer{
		metrics: &PerformanceMetrics{
			StartTime:   time.Now(),
			LastUpdated: time.Now(),
		},
		config:         config,
		alertManager:   nil, // Remove alert manager dependency to fix compilation
		stopCh:         make(chan struct{}),
		maxHistorySize: config.MaxHistorySize,
	}
}

// Start begins performance monitoring and optimization
func (po *PerformanceOptimizer) Start(ctx context.Context) error {
	if !po.config.Enabled {
		logger.Info("Performance optimizer disabled")
		return nil
	}

	po.mutex.Lock()
	if po.running {
		po.mutex.Unlock()
		return nil
	}
	po.running = true
	po.mutex.Unlock()

	logger.InfoWithFields(logger.Fields{
		"component": "performance_optimizer",
		"interval":  po.config.MetricsInterval.String(),
		"alerting":  po.config.AlertingEnabled,
	}, "Starting performance optimizer")

	// Start metrics collection
	go po.metricsLoop(ctx)

	// Start optimization loop
	if po.config.OptimizationEnabled {
		go po.optimizationLoop(ctx)
	}

	return nil
}

// Stop stops performance monitoring
func (po *PerformanceOptimizer) Stop() {
	po.mutex.Lock()
	defer po.mutex.Unlock()

	if !po.running {
		return
	}

	logger.Info("Stopping performance optimizer")
	close(po.stopCh)
	po.running = false
}

// RecordRequest records metrics for an HTTP request
func (po *PerformanceOptimizer) RecordRequest(duration time.Duration, success bool) {
	if !po.config.Enabled {
		return
	}

	durationNanos := duration.Nanoseconds()

	atomic.AddInt64(&po.metrics.TotalRequests, 1)
	atomic.AddInt64(&po.metrics.TotalResponseTime, durationNanos)

	// Update min/max response times
	for {
		current := atomic.LoadInt64(&po.metrics.MinResponseTime)
		if current == 0 || durationNanos < current {
			if atomic.CompareAndSwapInt64(&po.metrics.MinResponseTime, current, durationNanos) {
				break
			}
		} else {
			break
		}
	}

	for {
		current := atomic.LoadInt64(&po.metrics.MaxResponseTime)
		if durationNanos > current {
			if atomic.CompareAndSwapInt64(&po.metrics.MaxResponseTime, current, durationNanos) {
				break
			}
		} else {
			break
		}
	}

	if success {
		atomic.AddInt64(&po.metrics.SuccessfulRequests, 1)
	} else {
		atomic.AddInt64(&po.metrics.FailedRequests, 1)
	}
}

// RecordDatabaseQuery records database query metrics
func (po *PerformanceOptimizer) RecordDatabaseQuery(duration time.Duration, success bool) {
	if !po.config.Enabled {
		return
	}

	atomic.AddInt64(&po.metrics.DatabaseQueries, 1)
	atomic.AddInt64(&po.metrics.TotalQueryTime, duration.Nanoseconds())

	if !success {
		atomic.AddInt64(&po.metrics.DatabaseErrors, 1)
	}
}

// RecordCacheOperation records cache operation metrics
func (po *PerformanceOptimizer) RecordCacheOperation(hit bool) {
	if !po.config.Enabled {
		return
	}

	atomic.AddInt64(&po.metrics.CacheOperations, 1)

	if hit {
		atomic.AddInt64(&po.metrics.CacheHits, 1)
	} else {
		atomic.AddInt64(&po.metrics.CacheMisses, 1)
	}
}

// UpdateConnectionCount updates the active connection count
func (po *PerformanceOptimizer) UpdateConnectionCount(count int64) {
	if !po.config.Enabled {
		return
	}

	atomic.StoreInt64(&po.metrics.ActiveConnections, count)

	// Update peak connections
	for {
		current := atomic.LoadInt64(&po.metrics.PeakConnections)
		if count > current {
			if atomic.CompareAndSwapInt64(&po.metrics.PeakConnections, current, count) {
				break
			}
		} else {
			break
		}
	}
}

// GetCurrentMetrics returns current performance metrics
func (po *PerformanceOptimizer) GetCurrentMetrics() PerformanceSnapshot {
	totalRequests := atomic.LoadInt64(&po.metrics.TotalRequests)
	successfulRequests := atomic.LoadInt64(&po.metrics.SuccessfulRequests)
	totalResponseTime := atomic.LoadInt64(&po.metrics.TotalResponseTime)
	cacheHits := atomic.LoadInt64(&po.metrics.CacheHits)
	cacheOperations := atomic.LoadInt64(&po.metrics.CacheOperations)
	activeConnections := atomic.LoadInt64(&po.metrics.ActiveConnections)

	uptime := time.Since(po.metrics.StartTime)

	var requestsPerSecond float64
	if uptime.Seconds() > 0 {
		requestsPerSecond = float64(totalRequests) / uptime.Seconds()
	}

	var averageResponseTime time.Duration
	if totalRequests > 0 {
		averageResponseTime = time.Duration(totalResponseTime / totalRequests)
	}

	var errorRate float64
	if totalRequests > 0 {
		errorRate = float64(totalRequests-successfulRequests) / float64(totalRequests)
	}

	var cacheHitRate float64
	if cacheOperations > 0 {
		cacheHitRate = float64(cacheHits) / float64(cacheOperations)
	}

	return PerformanceSnapshot{
		Timestamp:           time.Now(),
		RequestsPerSecond:   requestsPerSecond,
		AverageResponseTime: averageResponseTime,
		ErrorRate:           errorRate,
		CacheHitRate:        cacheHitRate,
		MemoryUsage:         atomic.LoadInt64(&po.metrics.MemoryUsed),
		ActiveConnections:   activeConnections,
	}
}

// metricsLoop periodically collects and logs performance metrics
func (po *PerformanceOptimizer) metricsLoop(ctx context.Context) {
	ticker := time.NewTicker(po.config.MetricsInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-po.stopCh:
			return
		case <-ticker.C:
			po.collectSystemMetrics()
			snapshot := po.GetCurrentMetrics()
			po.addToHistory(snapshot)
			po.logMetrics(snapshot)

			if po.config.AlertingEnabled {
				po.checkPerformanceAlerts(snapshot)
			}
		}
	}
}

// optimizationLoop performs automatic performance optimizations
func (po *PerformanceOptimizer) optimizationLoop(ctx context.Context) {
	ticker := time.NewTicker(5 * time.Minute) // Check every 5 minutes
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-po.stopCh:
			return
		case <-ticker.C:
			po.performOptimizations()
		}
	}
}

// collectSystemMetrics collects system-level metrics
func (po *PerformanceOptimizer) collectSystemMetrics() {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	atomic.StoreInt64(&po.metrics.MemoryAllocated, int64(m.Alloc))
	atomic.StoreInt64(&po.metrics.MemoryUsed, int64(m.Sys))
	atomic.StoreInt64(&po.metrics.GCPauses, int64(m.PauseTotalNs))
	atomic.StoreInt64(&po.metrics.GoroutineCount, int64(runtime.NumGoroutine()))

	po.metrics.LastUpdated = time.Now()
}

// addToHistory adds a snapshot to the metrics history
func (po *PerformanceOptimizer) addToHistory(snapshot PerformanceSnapshot) {
	po.mutex.Lock()
	defer po.mutex.Unlock()

	po.metricsHistory = append(po.metricsHistory, snapshot)

	// Keep only the last N snapshots
	if len(po.metricsHistory) > po.maxHistorySize {
		po.metricsHistory = po.metricsHistory[1:]
	}
}

// logMetrics logs current performance metrics
func (po *PerformanceOptimizer) logMetrics(snapshot PerformanceSnapshot) {
	logger.InfoWithFields(logger.Fields{
		"component":           "performance_optimizer",
		"requests_per_second": snapshot.RequestsPerSecond,
		"avg_response_time":   snapshot.AverageResponseTime.String(),
		"error_rate":          snapshot.ErrorRate,
		"cache_hit_rate":      snapshot.CacheHitRate,
		"memory_usage_mb":     snapshot.MemoryUsage / 1024 / 1024,
		"active_connections":  snapshot.ActiveConnections,
		"goroutines":          atomic.LoadInt64(&po.metrics.GoroutineCount),
	}, "Performance metrics")
}

// checkPerformanceAlerts checks if any performance thresholds are exceeded
func (po *PerformanceOptimizer) checkPerformanceAlerts(snapshot PerformanceSnapshot) {
	if snapshot.AverageResponseTime > po.config.MaxResponseTime {
		logger.Warn("Performance Alert: Average response time %v exceeds threshold %v",
			snapshot.AverageResponseTime, po.config.MaxResponseTime)
	}

	if snapshot.ErrorRate > po.config.MaxErrorRate {
		logger.Error("Performance Alert: Error rate %.2f%% exceeds threshold %.2f%%",
			snapshot.ErrorRate*100, po.config.MaxErrorRate*100)
	}
	if snapshot.CacheHitRate < po.config.MinCacheHitRate && snapshot.CacheHitRate > 0 {
		logger.Warn("Performance Alert: Cache hit rate %.2f%% below threshold %.2f%%",
			snapshot.CacheHitRate*100, po.config.MinCacheHitRate*100)
	}
}

// performOptimizations performs automatic performance optimizations
func (po *PerformanceOptimizer) performOptimizations() {
	snapshot := po.GetCurrentMetrics()

	logger.DebugWithFields(logger.Fields{
		"component": "performance_optimizer",
		"operation": "auto_optimization",
	}, "Running automatic performance optimizations")

	// Trigger garbage collection if memory usage is high
	if snapshot.MemoryUsage > po.config.MaxMemoryUsage/2 {
		runtime.GC()
		logger.InfoWithFields(logger.Fields{
			"component": "performance_optimizer",
			"operation": "gc_trigger",
			"reason":    "high_memory_usage",
		}, "Triggered garbage collection")
	}

	// Log optimization recommendations
	po.logOptimizationRecommendations(snapshot)
}

// logOptimizationRecommendations logs performance optimization recommendations
func (po *PerformanceOptimizer) logOptimizationRecommendations(snapshot PerformanceSnapshot) {
	recommendations := []string{}

	if snapshot.CacheHitRate < 0.8 && snapshot.CacheHitRate > 0 {
		recommendations = append(recommendations, "Consider cache warming or increasing cache TTL")
	}

	if snapshot.AverageResponseTime > time.Second {
		recommendations = append(recommendations, "Consider adding database indexes or optimizing queries")
	}

	if snapshot.ErrorRate > 0.01 {
		recommendations = append(recommendations, "Investigate error patterns and add circuit breakers")
	}

	if len(recommendations) > 0 {
		logger.InfoWithFields(logger.Fields{
			"component":       "performance_optimizer",
			"recommendations": recommendations,
		}, "Performance optimization recommendations")
	}
}

// GetMetricsHistory returns the metrics history
func (po *PerformanceOptimizer) GetMetricsHistory() []PerformanceSnapshot {
	po.mutex.RLock()
	defer po.mutex.RUnlock()

	// Return a copy to avoid race conditions
	history := make([]PerformanceSnapshot, len(po.metricsHistory))
	copy(history, po.metricsHistory)
	return history
}

// ResetMetrics resets all performance metrics
func (po *PerformanceOptimizer) ResetMetrics() {
	atomic.StoreInt64(&po.metrics.TotalRequests, 0)
	atomic.StoreInt64(&po.metrics.SuccessfulRequests, 0)
	atomic.StoreInt64(&po.metrics.FailedRequests, 0)
	atomic.StoreInt64(&po.metrics.TotalResponseTime, 0)
	atomic.StoreInt64(&po.metrics.MinResponseTime, 0)
	atomic.StoreInt64(&po.metrics.MaxResponseTime, 0)
	atomic.StoreInt64(&po.metrics.CacheHits, 0)
	atomic.StoreInt64(&po.metrics.CacheMisses, 0)
	atomic.StoreInt64(&po.metrics.CacheOperations, 0)
	atomic.StoreInt64(&po.metrics.DatabaseQueries, 0)
	atomic.StoreInt64(&po.metrics.DatabaseErrors, 0)
	atomic.StoreInt64(&po.metrics.TotalQueryTime, 0)

	po.metrics.StartTime = time.Now()
	po.metrics.LastUpdated = time.Now()

	po.mutex.Lock()
	po.metricsHistory = make([]PerformanceSnapshot, 0)
	po.mutex.Unlock()

	logger.Info("Performance metrics reset")
}
