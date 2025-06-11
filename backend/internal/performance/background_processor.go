package performance

import (
	"context"
	"runtime"
	"sync"
	"sync/atomic"
	"time"

	"github.com/toeic-app/internal/logger"
)

// BackgroundProcessor handles heavy operations in background goroutines with advanced concurrency
type BackgroundProcessor struct {
	// Worker management
	workers        []*Worker
	workerPool     chan chan BackgroundTask
	taskQueue      chan BackgroundTask
	priorityQueues map[int]chan BackgroundTask

	// Lifecycle management
	quit   chan bool
	wg     sync.WaitGroup
	ctx    context.Context
	cancel context.CancelFunc

	// Configuration
	maxWorkers       int
	minWorkers       int
	autoScale        bool
	scalingThreshold float64

	// Statistics and monitoring
	stats    *ProcessorStats
	statsMux sync.RWMutex

	// Performance optimization
	batchProcessor *BatchProcessor
	rateLimiter    chan struct{}

	// Worker lifecycle
	workerLifecycle map[int]*WorkerLifecycle
	lifecycleMux    sync.RWMutex
}

// GetQueueHealth returns a map with health information about the queue.
func (bp *BackgroundProcessor) GetQueueHealth() map[string]interface{} {
	return map[string]interface{}{
		"health":      "ok",
		"queue_size":  len(bp.taskQueue),
		"max_workers": bp.maxWorkers,
	}
}

// BackgroundTask represents a task to be processed in the background
type BackgroundTask struct {
	ID            string
	Type          string
	Data          interface{}
	Handler       func(context.Context, interface{}) error
	Priority      int
	Created       time.Time
	Timeout       time.Duration
	Retries       int
	MaxRetries    int
	RetryDelay    time.Duration
	Context       context.Context
	ResultChannel chan TaskResult
	Tags          map[string]string
}

// TaskResult represents the result of a background task
type TaskResult struct {
	TaskID    string
	Success   bool
	Result    interface{}
	Error     error
	Duration  time.Duration
	Worker    int
	Retries   int
	Timestamp time.Time
}

// ProcessorStats holds comprehensive statistics about the background processor
type ProcessorStats struct {
	TotalTasks        int64            `json:"total_tasks"`
	CompletedTasks    int64            `json:"completed_tasks"`
	FailedTasks       int64            `json:"failed_tasks"`
	RetriedTasks      int64            `json:"retried_tasks"`
	QueuedTasks       int64            `json:"queued_tasks"`
	ActiveTasks       int64            `json:"active_tasks"`
	AverageTime       time.Duration    `json:"average_time"`
	MinTime           time.Duration    `json:"min_time"`
	MaxTime           time.Duration    `json:"max_time"`
	QueueSize         int              `json:"queue_size"`
	ActiveWorkers     int              `json:"active_workers"`
	TotalWorkers      int              `json:"total_workers"`
	WorkerUtilization float64          `json:"worker_utilization"`
	TaskThroughput    float64          `json:"task_throughput"` // tasks per second
	LastReset         time.Time        `json:"last_reset"`
	TasksByType       map[string]int64 `json:"tasks_by_type"`
	TasksByPriority   map[int]int64    `json:"tasks_by_priority"`
}

// Worker represents a background worker with enhanced capabilities
type Worker struct {
	ID              int
	TaskChannel     chan BackgroundTask
	QuitChannel     chan bool
	processor       *BackgroundProcessor
	isActive        int32
	tasksProcessed  int64
	lastActivity    time.Time
	startTime       time.Time
	totalIdleTime   time.Duration
	totalActiveTime time.Duration
	lifecycle       *WorkerLifecycle
}

// WorkerLifecycle tracks worker lifecycle events
type WorkerLifecycle struct {
	WorkerID   int
	StartTime  time.Time
	LastTask   time.Time
	TaskCount  int64
	ErrorCount int64
	IdleTime   time.Duration
	State      string // "idle", "active", "stopping", "stopped"
	mutex      sync.RWMutex
}

// BatchProcessor handles batch processing of similar tasks
type BatchProcessor struct {
	batches      map[string]*TaskBatch
	batchMutex   sync.RWMutex
	batchTimeout time.Duration
	maxBatchSize int
}

// TaskBatch represents a batch of similar tasks
type TaskBatch struct {
	Type      string
	Tasks     []BackgroundTask
	CreatedAt time.Time
	mutex     sync.Mutex
}

// ProcessorConfig holds configuration for the background processor
type ProcessorConfig struct {
	MaxWorkers       int
	MinWorkers       int
	AutoScale        bool
	ScalingThreshold float64
	QueueSize        int
	EnablePriority   bool
	BatchTimeout     time.Duration
	MaxBatchSize     int
	RateLimit        int // Tasks per second
}

// NewBackgroundProcessor creates a new enhanced background processor
func NewBackgroundProcessor(maxWorkers, queueSize int) *BackgroundProcessor {
	return NewBackgroundProcessorWithConfig(ProcessorConfig{
		MaxWorkers:       maxWorkers,
		MinWorkers:       max(1, maxWorkers/2),
		AutoScale:        true,
		ScalingThreshold: 0.8, // Scale up when 80% of workers are busy
		QueueSize:        queueSize,
		EnablePriority:   true,
		BatchTimeout:     5 * time.Second,
		MaxBatchSize:     10,
		RateLimit:        100, // 100 tasks per second
	})
}

// NewBackgroundProcessorWithConfig creates a new background processor with custom configuration
func NewBackgroundProcessorWithConfig(config ProcessorConfig) *BackgroundProcessor {
	// Set defaults
	if config.MaxWorkers == 0 {
		config.MaxWorkers = runtime.NumCPU() * 2
	}
	if config.MinWorkers == 0 {
		config.MinWorkers = max(1, config.MaxWorkers/2)
	}
	if config.QueueSize == 0 {
		config.QueueSize = config.MaxWorkers * 10
	}
	if config.BatchTimeout == 0 {
		config.BatchTimeout = 5 * time.Second
	}
	if config.MaxBatchSize == 0 {
		config.MaxBatchSize = 10
	}
	if config.RateLimit == 0 {
		config.RateLimit = 100
	}

	ctx, cancel := context.WithCancel(context.Background())

	bp := &BackgroundProcessor{
		maxWorkers:       config.MaxWorkers,
		minWorkers:       config.MinWorkers,
		autoScale:        config.AutoScale,
		scalingThreshold: config.ScalingThreshold,
		workers:          make([]*Worker, 0, config.MaxWorkers),
		workerPool:       make(chan chan BackgroundTask, config.MaxWorkers),
		taskQueue:        make(chan BackgroundTask, config.QueueSize),
		priorityQueues:   make(map[int]chan BackgroundTask),
		quit:             make(chan bool),
		ctx:              ctx,
		cancel:           cancel,
		stats: &ProcessorStats{
			TasksByType:     make(map[string]int64),
			TasksByPriority: make(map[int]int64),
			LastReset:       time.Now(),
		},
		workerLifecycle: make(map[int]*WorkerLifecycle),
		batchProcessor: &BatchProcessor{
			batches:      make(map[string]*TaskBatch),
			batchTimeout: config.BatchTimeout,
			maxBatchSize: config.MaxBatchSize,
		},
	}

	// Create rate limiter if configured
	if config.RateLimit > 0 {
		bp.rateLimiter = make(chan struct{}, config.RateLimit)
		go bp.rateLimiterRefill(config.RateLimit)
	}

	// Initialize priority queues if enabled
	if config.EnablePriority {
		bp.initializePriorityQueues()
	}

	// Start with minimum workers
	bp.startWorkers(config.MinWorkers)

	// Start monitoring and scaling
	bp.startMonitoring()

	logger.Info("Enhanced background processor initialized with %d workers (min: %d, max: %d, auto-scale: %v)",
		config.MinWorkers, config.MinWorkers, config.MaxWorkers, config.AutoScale)

	return bp
}

// max returns the maximum of two integers
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

// initializePriorityQueues initializes priority-based task queues
func (bp *BackgroundProcessor) initializePriorityQueues() {
	// High priority (urgent tasks)
	bp.priorityQueues[3] = make(chan BackgroundTask, 100)
	// Medium priority (normal tasks)
	bp.priorityQueues[2] = make(chan BackgroundTask, 200)
	// Low priority (background maintenance)
	bp.priorityQueues[1] = make(chan BackgroundTask, 300)

	// Start priority queue dispatcher
	go bp.dispatchPriorityTasks()
}

// rateLimiterRefill refills the rate limiter token bucket
func (bp *BackgroundProcessor) rateLimiterRefill(rate int) {
	ticker := time.NewTicker(time.Second / time.Duration(rate))
	defer ticker.Stop()

	for {
		select {
		case <-bp.ctx.Done():
			return
		case <-ticker.C:
			select {
			case bp.rateLimiter <- struct{}{}:
			default:
				// Rate limiter is full, skip
			}
		}
	}
}

// dispatchPriorityTasks dispatches tasks from priority queues to workers
func (bp *BackgroundProcessor) dispatchPriorityTasks() {
	for {
		select {
		case <-bp.quit:
			return
		default:
			// Process high priority first, then medium, then low
			dispatched := false

			// Try high priority
			select {
			case task := <-bp.priorityQueues[3]:
				bp.dispatchTask(task)
				dispatched = true
			default:
			}

			if !dispatched {
				// Try medium priority
				select {
				case task := <-bp.priorityQueues[2]:
					bp.dispatchTask(task)
					dispatched = true
				default:
				}
			}

			if !dispatched {
				// Try low priority
				select {
				case task := <-bp.priorityQueues[1]:
					bp.dispatchTask(task)
					dispatched = true
				default:
				}
			}

			if !dispatched {
				// No tasks available, sleep briefly
				time.Sleep(10 * time.Millisecond)
			}
		}
	}
}

// dispatchTask dispatches a task to an available worker
func (bp *BackgroundProcessor) dispatchTask(task BackgroundTask) {
	select {
	case bp.taskQueue <- task:
		atomic.AddInt64(&bp.stats.QueuedTasks, 1)
	default:
		// Queue is full, log and potentially scale up
		logger.Warn("Task queue is full, dropping task: %s", task.ID)
		atomic.AddInt64(&bp.stats.FailedTasks, 1)

		if bp.autoScale && len(bp.workers) < bp.maxWorkers {
			bp.scaleUp()
		}
	}
}

// startWorkers starts the initial set of workers
func (bp *BackgroundProcessor) startWorkers(count int) {
	for i := 0; i < count; i++ {
		bp.addWorker()
	}

	// Start the main dispatcher
	bp.wg.Add(1)
	go bp.dispatcher()
}

// addWorker adds a new worker to the pool
func (bp *BackgroundProcessor) addWorker() {
	workerID := len(bp.workers)
	worker := &Worker{
		ID:           workerID,
		TaskChannel:  make(chan BackgroundTask),
		QuitChannel:  make(chan bool),
		processor:    bp,
		startTime:    time.Now(),
		lastActivity: time.Now(),
	}

	// Create lifecycle tracker
	lifecycle := &WorkerLifecycle{
		WorkerID:  workerID,
		StartTime: time.Now(),
		State:     "idle",
	}

	bp.lifecycleMux.Lock()
	bp.workerLifecycle[workerID] = lifecycle
	bp.lifecycleMux.Unlock()

	worker.lifecycle = lifecycle
	bp.workers = append(bp.workers, worker)

	// Start the worker
	worker.start()

	logger.Debug("Added worker %d to processor", workerID)
}

// dispatcher is the main task dispatcher
func (bp *BackgroundProcessor) dispatcher() {
	defer bp.wg.Done()

	for {
		select {
		case task := <-bp.taskQueue:
			// Apply rate limiting if configured
			if bp.rateLimiter != nil {
				<-bp.rateLimiter
			}

			// Get an available worker
			go func(task BackgroundTask) {
				workerChannel := <-bp.workerPool
				workerChannel <- task
			}(task)

		case <-bp.quit:
			return
		}
	}
}

// start starts a worker
func (w *Worker) start() {
	go func() {
		for {
			// Register this worker in the worker pool
			w.processor.workerPool <- w.TaskChannel

			select {
			case task := <-w.TaskChannel:
				w.processTask(task)
			case <-w.QuitChannel:
				w.lifecycle.mutex.Lock()
				w.lifecycle.State = "stopped"
				w.lifecycle.mutex.Unlock()
				return
			}
		}
	}()
}

// processTask processes a single task
func (w *Worker) processTask(task BackgroundTask) {
	start := time.Now()
	atomic.StoreInt32(&w.isActive, 1)
	atomic.AddInt64(&w.tasksProcessed, 1)
	w.lastActivity = start

	// Update lifecycle
	w.lifecycle.mutex.Lock()
	w.lifecycle.State = "active"
	w.lifecycle.LastTask = start
	w.lifecycle.TaskCount++
	w.lifecycle.mutex.Unlock()

	// Update processor stats
	atomic.AddInt64(&w.processor.stats.ActiveTasks, 1)
	atomic.AddInt64(&w.processor.stats.TotalTasks, 1)

	defer func() {
		atomic.StoreInt32(&w.isActive, 0)
		atomic.AddInt64(&w.processor.stats.ActiveTasks, -1)

		w.lifecycle.mutex.Lock()
		w.lifecycle.State = "idle"
		w.lifecycle.mutex.Unlock()
	}()

	// Create context with timeout
	ctx := task.Context
	if ctx == nil {
		ctx = context.Background()
	}

	if task.Timeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, task.Timeout)
		defer cancel()
	}

	// Process the task
	var err error
	var result interface{}

	done := make(chan struct{})
	go func() {
		defer close(done)
		result, err = w.executeTask(ctx, task)
	}()

	select {
	case <-done:
		// Task completed normally
		duration := time.Since(start)
		w.handleTaskResult(task, result, err, duration)

	case <-ctx.Done():
		// Task timed out or was cancelled
		duration := time.Since(start)
		err = ctx.Err()
		w.handleTaskResult(task, nil, err, duration)
	}
}

// executeTask executes the actual task handler
func (w *Worker) executeTask(ctx context.Context, task BackgroundTask) (interface{}, error) {
	defer func() {
		if r := recover(); r != nil {
			logger.Error("Worker %d: Task %s panicked: %v", w.ID, task.ID, r)
		}
	}()

	return nil, task.Handler(ctx, task.Data)
}

// handleTaskResult handles the result of a task execution
func (w *Worker) handleTaskResult(task BackgroundTask, result interface{}, err error, duration time.Duration) {
	success := err == nil

	// Update processor statistics
	if success {
		atomic.AddInt64(&w.processor.stats.CompletedTasks, 1)
	} else {
		atomic.AddInt64(&w.processor.stats.FailedTasks, 1)
		w.lifecycle.mutex.Lock()
		w.lifecycle.ErrorCount++
		w.lifecycle.mutex.Unlock()

		// Handle retries
		if task.Retries < task.MaxRetries && task.MaxRetries > 0 {
			w.retryTask(task)
			return
		}
	}

	// Update timing statistics
	w.processor.updateTimingStats(duration)

	// Send result if channel is provided
	if task.ResultChannel != nil {
		select {
		case task.ResultChannel <- TaskResult{
			TaskID:    task.ID,
			Success:   success,
			Result:    result,
			Error:     err,
			Duration:  duration,
			Worker:    w.ID,
			Retries:   task.Retries,
			Timestamp: time.Now(),
		}:
		default:
			// Result channel is full or closed
		}
	}

	// Log result
	if success {
		logger.Debug("Worker %d: Task %s completed successfully (took %v)", w.ID, task.ID, duration)
	} else {
		logger.Error("Worker %d: Task %s failed: %v (took %v)", w.ID, task.ID, err, duration)
	}
}

// retryTask retries a failed task
func (w *Worker) retryTask(task BackgroundTask) {
	atomic.AddInt64(&w.processor.stats.RetriedTasks, 1)
	task.Retries++

	// Apply retry delay
	if task.RetryDelay > 0 {
		time.Sleep(task.RetryDelay)
	}

	// Resubmit the task
	go func() {
		time.Sleep(time.Duration(task.Retries) * time.Second) // Exponential backoff
		w.processor.SubmitTask(task)
	}()
}

// updateTimingStats updates processor timing statistics
func (bp *BackgroundProcessor) updateTimingStats(duration time.Duration) {
	bp.statsMux.Lock()
	defer bp.statsMux.Unlock()

	// Update min/max times
	if bp.stats.MinTime == 0 || duration < bp.stats.MinTime {
		bp.stats.MinTime = duration
	}
	if duration > bp.stats.MaxTime {
		bp.stats.MaxTime = duration
	}

	// Update average time (simple moving average)
	if bp.stats.CompletedTasks == 1 {
		bp.stats.AverageTime = duration
	} else {
		bp.stats.AverageTime = (bp.stats.AverageTime + duration) / 2
	}
}

// startMonitoring starts the monitoring and auto-scaling routines
func (bp *BackgroundProcessor) startMonitoring() {
	bp.wg.Add(1)
	go func() {
		defer bp.wg.Done()
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				bp.monitorAndScale()
			case <-bp.quit:
				return
			}
		}
	}()
}

// monitorAndScale monitors worker utilization and scales if needed
func (bp *BackgroundProcessor) monitorAndScale() {
	activeWorkers := atomic.LoadInt64(&bp.stats.ActiveTasks)
	totalWorkers := int64(len(bp.workers))
	utilization := float64(activeWorkers) / float64(totalWorkers)

	bp.statsMux.Lock()
	bp.stats.WorkerUtilization = utilization
	bp.stats.TotalWorkers = int(totalWorkers)
	bp.stats.ActiveWorkers = int(activeWorkers)
	bp.statsMux.Unlock()

	if !bp.autoScale {
		return
	}

	// Scale up if utilization is high and we can add more workers
	if utilization > bp.scalingThreshold && len(bp.workers) < bp.maxWorkers {
		bp.scaleUp()
	}

	// Scale down if utilization is low and we have more than minimum workers
	if utilization < 0.3 && len(bp.workers) > bp.minWorkers {
		bp.scaleDown()
	}
}

// scaleUp adds more workers
func (bp *BackgroundProcessor) scaleUp() {
	currentWorkers := len(bp.workers)
	newWorkers := min(bp.maxWorkers-currentWorkers, max(1, currentWorkers/4)) // Add 25% more workers

	for i := 0; i < newWorkers; i++ {
		bp.addWorker()
	}

	logger.Info("Scaled up background processor: %d -> %d workers", currentWorkers, len(bp.workers))
}

// scaleDown removes workers
func (bp *BackgroundProcessor) scaleDown() {
	currentWorkers := len(bp.workers)
	workersToRemove := min(currentWorkers-bp.minWorkers, max(1, currentWorkers/4)) // Remove 25% of workers

	for i := 0; i < workersToRemove; i++ {
		if len(bp.workers) > bp.minWorkers {
			worker := bp.workers[len(bp.workers)-1]
			bp.workers = bp.workers[:len(bp.workers)-1]
			worker.QuitChannel <- true
		}
	}

	logger.Info("Scaled down background processor: %d -> %d workers", currentWorkers, len(bp.workers))
}

// min returns the minimum of two integers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// SubmitTask submits a task for background processing
func (bp *BackgroundProcessor) SubmitTask(task BackgroundTask) error {
	task.Created = time.Now()
	if task.ID == "" {
		task.ID = generateTaskID()
	}
	if task.Timeout == 0 {
		task.Timeout = 30 * time.Second
	}

	// Update task type statistics
	bp.statsMux.Lock()
	bp.stats.TasksByType[task.Type]++
	bp.stats.TasksByPriority[task.Priority]++
	bp.statsMux.Unlock()

	// Submit to appropriate queue
	if len(bp.priorityQueues) > 0 {
		queue, exists := bp.priorityQueues[task.Priority]
		if exists {
			select {
			case queue <- task:
				return nil
			default:
				// Priority queue is full, fallback to main queue
			}
		}
	}

	// Submit to main queue
	select {
	case bp.taskQueue <- task:
		return nil
	default:
		atomic.AddInt64(&bp.stats.FailedTasks, 1)
		return ErrQueueFull
	}
}

// SubmitTaskWithResult submits a task and returns a result channel
func (bp *BackgroundProcessor) SubmitTaskWithResult(task BackgroundTask) (<-chan TaskResult, error) {
	resultChannel := make(chan TaskResult, 1)
	task.ResultChannel = resultChannel

	err := bp.SubmitTask(task)
	if err != nil {
		close(resultChannel)
		return nil, err
	}

	return resultChannel, nil
}

// Stop gracefully stops the background processor
func (bp *BackgroundProcessor) Stop() error {
	logger.Info("Stopping background processor...")

	// Signal shutdown
	bp.cancel()
	close(bp.quit)

	// Stop all workers
	for _, worker := range bp.workers {
		worker.QuitChannel <- true
	}

	// Wait for all goroutines to finish
	bp.wg.Wait()

	logger.Info("Background processor stopped")
	return nil
}

// GetStats returns current processor statistics
func (bp *BackgroundProcessor) GetStats() ProcessorStats {
	bp.statsMux.RLock()
	defer bp.statsMux.RUnlock()

	stats := *bp.stats
	stats.QueueSize = len(bp.taskQueue)

	// Calculate throughput
	elapsed := time.Since(stats.LastReset)
	if elapsed > 0 {
		stats.TaskThroughput = float64(stats.CompletedTasks) / elapsed.Seconds()
	}

	return stats
}

// generateTaskID generates a unique task ID
func generateTaskID() string {
	return "task_" + time.Now().Format("20060102_150405_") + string(rune(time.Now().Nanosecond()%1000))
}

// Error definitions
var (
	ErrQueueFull = &ProcessorError{Code: "QUEUE_FULL", Message: "Task queue is full"}
)

// ProcessorError represents a processor-specific error
type ProcessorError struct {
	Code    string
	Message string
}

func (e *ProcessorError) Error() string {
	return e.Message
}
