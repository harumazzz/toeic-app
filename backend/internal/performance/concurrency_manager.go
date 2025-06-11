package performance

import (
	"context"
	"database/sql"
	"runtime"
	"sync"
	"sync/atomic"
	"time"

	"github.com/toeic-app/internal/logger"
)

// ConcurrencyManager manages concurrent operations and system resources
type ConcurrencyManager struct {
	// Worker pools for different types of operations
	dbWorkerPool    *WorkerPool
	httpWorkerPool  *WorkerPool
	cacheWorkerPool *WorkerPool

	// Connection pool monitoring
	dbStats *DatabaseStats
	db      *sql.DB

	// System resource monitoring
	systemStats *SystemStats

	// Semaphores for limiting concurrent operations
	dbSemaphore    chan struct{}
	httpSemaphore  chan struct{}
	cacheSemaphore chan struct{}

	// Metrics
	metrics *ConcurrencyMetrics

	// Configuration
	config ConcurrencyConfig

	// Cleanup
	ctx    context.Context
	cancel context.CancelFunc
	wg     sync.WaitGroup
}

// ConcurrencyConfig holds configuration for concurrency management
type ConcurrencyConfig struct {
	MaxDBWorkers          int
	MaxHTTPWorkers        int
	MaxCacheWorkers       int
	DBSemaphoreSize       int
	HTTPSemaphoreSize     int
	CacheSemaphoreSize    int
	MonitoringInterval    time.Duration
	MetricRetentionPeriod time.Duration
}

// WorkerPool represents a pool of workers for handling tasks
type WorkerPool struct {
	workers     int
	taskQueue   chan Task
	resultQueue chan ConcurrentTaskResult
	wg          sync.WaitGroup
	ctx         context.Context
	cancel      context.CancelFunc
	active      int64
	completed   int64
	failed      int64
}

// Task represents a unit of work
type Task struct {
	ID       string
	Type     string
	Handler  func(context.Context) (interface{}, error)
	Context  context.Context
	Timeout  time.Duration
	Priority int
}

// ConcurrentTaskResult represents the result of a concurrent task
type ConcurrentTaskResult struct {
	TaskID   string
	Result   interface{}
	Error    error
	Duration time.Duration
}

// DatabaseStats holds database connection pool statistics
type DatabaseStats struct {
	MaxOpenConnections int64
	OpenConnections    int64
	InUseConnections   int64
	IdleConnections    int64
	WaitCount          int64
	WaitDuration       time.Duration
	MaxIdleClosed      int64
	MaxLifetimeClosed  int64
	LastUpdate         time.Time
}

// SystemStats holds system resource statistics
type SystemStats struct {
	NumCPU        int
	NumGoroutines int
	MemoryUsage   uint64
	MemoryLimit   uint64
	LoadAverage   float64
	LastUpdate    time.Time
}

// ConcurrencyMetrics holds metrics for concurrency operations
type ConcurrencyMetrics struct {
	ActiveDBOperations    int64
	ActiveHTTPOperations  int64
	ActiveCacheOperations int64
	TotalDBOperations     int64
	TotalHTTPOperations   int64
	TotalCacheOperations  int64
	AvgDBLatency          time.Duration
	AvgHTTPLatency        time.Duration
	AvgCacheLatency       time.Duration
	mutex                 sync.RWMutex
}

// NewConcurrencyManager creates a new concurrency manager
func NewConcurrencyManager(db *sql.DB, config ConcurrencyConfig) *ConcurrencyManager {
	ctx, cancel := context.WithCancel(context.Background())

	// Use optimal defaults if not configured
	if config.MaxDBWorkers == 0 {
		config.MaxDBWorkers = runtime.NumCPU() * 2
	}
	if config.MaxHTTPWorkers == 0 {
		config.MaxHTTPWorkers = runtime.NumCPU() * 4
	}
	if config.MaxCacheWorkers == 0 {
		config.MaxCacheWorkers = runtime.NumCPU() * 2
	}
	if config.DBSemaphoreSize == 0 {
		config.DBSemaphoreSize = config.MaxDBWorkers * 2
	}
	if config.HTTPSemaphoreSize == 0 {
		config.HTTPSemaphoreSize = config.MaxHTTPWorkers * 2
	}
	if config.CacheSemaphoreSize == 0 {
		config.CacheSemaphoreSize = config.MaxCacheWorkers * 2
	}
	if config.MonitoringInterval == 0 {
		config.MonitoringInterval = 30 * time.Second
	}
	if config.MetricRetentionPeriod == 0 {
		config.MetricRetentionPeriod = 24 * time.Hour
	}

	cm := &ConcurrencyManager{
		db:             db,
		config:         config,
		ctx:            ctx,
		cancel:         cancel,
		dbStats:        &DatabaseStats{},
		systemStats:    &SystemStats{},
		metrics:        &ConcurrencyMetrics{},
		dbSemaphore:    make(chan struct{}, config.DBSemaphoreSize),
		httpSemaphore:  make(chan struct{}, config.HTTPSemaphoreSize),
		cacheSemaphore: make(chan struct{}, config.CacheSemaphoreSize),
	}

	// Initialize worker pools
	cm.dbWorkerPool = NewWorkerPool(ctx, config.MaxDBWorkers, "db")
	cm.httpWorkerPool = NewWorkerPool(ctx, config.MaxHTTPWorkers, "http")
	cm.cacheWorkerPool = NewWorkerPool(ctx, config.MaxCacheWorkers, "cache")

	// Start monitoring
	cm.startMonitoring()

	logger.Info("Concurrency manager initialized with %d DB workers, %d HTTP workers, %d cache workers",
		config.MaxDBWorkers, config.MaxHTTPWorkers, config.MaxCacheWorkers)

	return cm
}

// NewWorkerPool creates a new worker pool
func NewWorkerPool(ctx context.Context, workers int, poolType string) *WorkerPool {
	poolCtx, cancel := context.WithCancel(ctx)

	wp := &WorkerPool{
		workers:     workers,
		taskQueue:   make(chan Task, workers*10), // Buffer for tasks
		resultQueue: make(chan ConcurrentTaskResult, workers*10),
		ctx:         poolCtx,
		cancel:      cancel,
	}

	// Start workers
	for i := 0; i < workers; i++ {
		wp.wg.Add(1)
		go wp.worker(i, poolType)
	}

	return wp
}

// worker processes tasks from the task queue
func (wp *WorkerPool) worker(id int, poolType string) {
	defer wp.wg.Done()

	for {
		select {
		case <-wp.ctx.Done():
			return
		case task := <-wp.taskQueue:
			atomic.AddInt64(&wp.active, 1)

			start := time.Now()
			result, err := wp.processTask(task)
			duration := time.Since(start)

			atomic.AddInt64(&wp.active, -1)

			if err != nil {
				atomic.AddInt64(&wp.failed, 1)
			} else {
				atomic.AddInt64(&wp.completed, 1)
			}

			// Send result if there's a result queue listener
			select {
			case wp.resultQueue <- ConcurrentTaskResult{
				TaskID:   task.ID,
				Result:   result,
				Error:    err,
				Duration: duration,
			}:
			default:
				// Result queue is full, continue without blocking
			}
		}
	}
}

// processTask processes a single task
func (wp *WorkerPool) processTask(task Task) (interface{}, error) {
	ctx := task.Context
	if ctx == nil {
		ctx = context.Background()
	}

	// Apply timeout if specified
	if task.Timeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, task.Timeout)
		defer cancel()
	}

	return task.Handler(ctx)
}

// SubmitDBTask submits a database task to the DB worker pool
func (cm *ConcurrencyManager) SubmitDBTask(task Task) error {
	select {
	case cm.dbSemaphore <- struct{}{}:
		defer func() { <-cm.dbSemaphore }()

		atomic.AddInt64(&cm.metrics.TotalDBOperations, 1)
		atomic.AddInt64(&cm.metrics.ActiveDBOperations, 1)
		defer atomic.AddInt64(&cm.metrics.ActiveDBOperations, -1)

		select {
		case cm.dbWorkerPool.taskQueue <- task:
			return nil
		case <-cm.ctx.Done():
			return cm.ctx.Err()
		}
	case <-cm.ctx.Done():
		return cm.ctx.Err()
	}
}

// SubmitHTTPTask submits an HTTP task to the HTTP worker pool
func (cm *ConcurrencyManager) SubmitHTTPTask(task Task) error {
	select {
	case cm.httpSemaphore <- struct{}{}:
		defer func() { <-cm.httpSemaphore }()

		atomic.AddInt64(&cm.metrics.TotalHTTPOperations, 1)
		atomic.AddInt64(&cm.metrics.ActiveHTTPOperations, 1)
		defer atomic.AddInt64(&cm.metrics.ActiveHTTPOperations, -1)

		select {
		case cm.httpWorkerPool.taskQueue <- task:
			return nil
		case <-cm.ctx.Done():
			return cm.ctx.Err()
		}
	case <-cm.ctx.Done():
		return cm.ctx.Err()
	}
}

// SubmitCacheTask submits a cache task to the cache worker pool
func (cm *ConcurrencyManager) SubmitCacheTask(task Task) error {
	select {
	case cm.cacheSemaphore <- struct{}{}:
		defer func() { <-cm.cacheSemaphore }()

		atomic.AddInt64(&cm.metrics.TotalCacheOperations, 1)
		atomic.AddInt64(&cm.metrics.ActiveCacheOperations, 1)
		defer atomic.AddInt64(&cm.metrics.ActiveCacheOperations, -1)

		select {
		case cm.cacheWorkerPool.taskQueue <- task:
			return nil
		case <-cm.ctx.Done():
			return cm.ctx.Err()
		}
	case <-cm.ctx.Done():
		return cm.ctx.Err()
	}
}

// startMonitoring starts the monitoring routines
func (cm *ConcurrencyManager) startMonitoring() {
	cm.wg.Add(1)
	go cm.monitoringLoop()
}

// monitoringLoop continuously monitors system resources and connection pools
func (cm *ConcurrencyManager) monitoringLoop() {
	defer cm.wg.Done()

	ticker := time.NewTicker(cm.config.MonitoringInterval)
	defer ticker.Stop()

	for {
		select {
		case <-cm.ctx.Done():
			return
		case <-ticker.C:
			cm.updateDatabaseStats()
			cm.updateSystemStats()
			cm.logMetrics()
		}
	}
}

// updateDatabaseStats updates database connection pool statistics
func (cm *ConcurrencyManager) updateDatabaseStats() {
	if cm.db == nil {
		return
	}

	stats := cm.db.Stats()
	cm.dbStats.MaxOpenConnections = int64(stats.MaxOpenConnections)
	cm.dbStats.OpenConnections = int64(stats.OpenConnections)
	cm.dbStats.InUseConnections = int64(stats.InUse)
	cm.dbStats.IdleConnections = int64(stats.Idle)
	cm.dbStats.WaitCount = stats.WaitCount
	cm.dbStats.WaitDuration = stats.WaitDuration
	cm.dbStats.MaxIdleClosed = stats.MaxIdleClosed
	cm.dbStats.MaxLifetimeClosed = stats.MaxLifetimeClosed
	cm.dbStats.LastUpdate = time.Now()
}

// updateSystemStats updates system resource statistics
func (cm *ConcurrencyManager) updateSystemStats() {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	cm.systemStats.NumCPU = runtime.NumCPU()
	cm.systemStats.NumGoroutines = runtime.NumGoroutine()
	cm.systemStats.MemoryUsage = m.Alloc
	cm.systemStats.MemoryLimit = m.Sys
	cm.systemStats.LastUpdate = time.Now()
}

// logMetrics logs current metrics
func (cm *ConcurrencyManager) logMetrics() {
	cm.metrics.mutex.RLock()
	defer cm.metrics.mutex.RUnlock()

	logger.Info("Concurrency Metrics - DB: %d active, %d total | HTTP: %d active, %d total | Cache: %d active, %d total | Goroutines: %d | Memory: %d MB",
		atomic.LoadInt64(&cm.metrics.ActiveDBOperations),
		atomic.LoadInt64(&cm.metrics.TotalDBOperations),
		atomic.LoadInt64(&cm.metrics.ActiveHTTPOperations),
		atomic.LoadInt64(&cm.metrics.TotalHTTPOperations),
		atomic.LoadInt64(&cm.metrics.ActiveCacheOperations),
		atomic.LoadInt64(&cm.metrics.TotalCacheOperations),
		cm.systemStats.NumGoroutines,
		cm.systemStats.MemoryUsage/1024/1024)

	// Log database pool stats
	logger.Info("DB Pool Stats - Open: %d/%d, InUse: %d, Idle: %d, Wait Count: %d, Wait Duration: %v",
		cm.dbStats.OpenConnections,
		cm.dbStats.MaxOpenConnections,
		cm.dbStats.InUseConnections,
		cm.dbStats.IdleConnections,
		cm.dbStats.WaitCount,
		cm.dbStats.WaitDuration)
}

// GetMetrics returns current concurrency metrics
func (cm *ConcurrencyManager) GetMetrics() *ConcurrencyMetrics {
	cm.metrics.mutex.RLock()
	defer cm.metrics.mutex.RUnlock()

	return &ConcurrencyMetrics{
		ActiveDBOperations:    atomic.LoadInt64(&cm.metrics.ActiveDBOperations),
		ActiveHTTPOperations:  atomic.LoadInt64(&cm.metrics.ActiveHTTPOperations),
		ActiveCacheOperations: atomic.LoadInt64(&cm.metrics.ActiveCacheOperations),
		TotalDBOperations:     atomic.LoadInt64(&cm.metrics.TotalDBOperations),
		TotalHTTPOperations:   atomic.LoadInt64(&cm.metrics.TotalHTTPOperations),
		TotalCacheOperations:  atomic.LoadInt64(&cm.metrics.TotalCacheOperations),
		AvgDBLatency:          cm.metrics.AvgDBLatency,
		AvgHTTPLatency:        cm.metrics.AvgHTTPLatency,
		AvgCacheLatency:       cm.metrics.AvgCacheLatency,
	}
}

// GetDatabaseStats returns database statistics
func (cm *ConcurrencyManager) GetDatabaseStats() *DatabaseStats {
	return cm.dbStats
}

// GetSystemStats returns system statistics
func (cm *ConcurrencyManager) GetSystemStats() *SystemStats {
	return cm.systemStats
}

// Shutdown gracefully shuts down the concurrency manager
func (cm *ConcurrencyManager) Shutdown(ctx context.Context) error {
	logger.Info("Shutting down concurrency manager...")

	// Cancel context to stop all operations
	cm.cancel()

	// Wait for all monitoring goroutines to finish
	done := make(chan struct{})
	go func() {
		cm.wg.Wait()
		cm.dbWorkerPool.wg.Wait()
		cm.httpWorkerPool.wg.Wait()
		cm.cacheWorkerPool.wg.Wait()
		close(done)
	}()

	// Wait for shutdown or timeout
	select {
	case <-done:
		logger.Info("Concurrency manager shut down successfully")
		return nil
	case <-ctx.Done():
		logger.Warn("Concurrency manager shutdown timed out")
		return ctx.Err()
	}
}

// ResetMetrics resets all concurrency metrics and statistics
func (cm *ConcurrencyManager) ResetMetrics() error {
	logger.Info("Resetting concurrency manager metrics...")

	cm.metrics.mutex.Lock()
	defer cm.metrics.mutex.Unlock()

	// Reset atomic counters
	atomic.StoreInt64(&cm.metrics.ActiveDBOperations, 0)
	atomic.StoreInt64(&cm.metrics.ActiveHTTPOperations, 0)
	atomic.StoreInt64(&cm.metrics.ActiveCacheOperations, 0)
	atomic.StoreInt64(&cm.metrics.TotalDBOperations, 0)
	atomic.StoreInt64(&cm.metrics.TotalHTTPOperations, 0)
	atomic.StoreInt64(&cm.metrics.TotalCacheOperations, 0)

	// Reset latency metrics
	cm.metrics.AvgDBLatency = 0
	cm.metrics.AvgHTTPLatency = 0
	cm.metrics.AvgCacheLatency = 0

	// Reset worker pool statistics
	if cm.dbWorkerPool != nil {
		atomic.StoreInt64(&cm.dbWorkerPool.completed, 0)
		atomic.StoreInt64(&cm.dbWorkerPool.failed, 0)
	}

	if cm.httpWorkerPool != nil {
		atomic.StoreInt64(&cm.httpWorkerPool.completed, 0)
		atomic.StoreInt64(&cm.httpWorkerPool.failed, 0)
	}

	if cm.cacheWorkerPool != nil {
		atomic.StoreInt64(&cm.cacheWorkerPool.completed, 0)
		atomic.StoreInt64(&cm.cacheWorkerPool.failed, 0)
	}

	logger.Info("Concurrency manager metrics reset successfully")
	return nil
}
