package monitoring

import (
	"database/sql"
	"runtime"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/toeic-app/internal/cache"
	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
)

// Metrics holds all Prometheus metrics
type Metrics struct {
	// HTTP Request metrics
	RequestsTotal   *prometheus.CounterVec
	RequestDuration *prometheus.HistogramVec
	RequestSize     *prometheus.HistogramVec
	ResponseSize    *prometheus.HistogramVec

	// Error metrics
	ErrorsTotal *prometheus.CounterVec
	ErrorRate   *prometheus.GaugeVec

	// Database metrics
	DBConnections   *prometheus.GaugeVec
	DBQueryDuration *prometheus.HistogramVec
	DBQueryTotal    *prometheus.CounterVec

	// Cache metrics
	CacheHits              *prometheus.CounterVec
	CacheMisses            *prometheus.CounterVec
	CacheOperationDuration *prometheus.HistogramVec

	// Application metrics
	ActiveUsers        *prometheus.GaugeVec
	BusinessOperations *prometheus.CounterVec

	// System metrics
	MemoryUsage    *prometheus.GaugeVec
	CPUUsage       *prometheus.GaugeVec
	GoroutineCount *prometheus.GaugeVec

	// Custom business metrics
	ExamsCompleted    *prometheus.CounterVec
	UserRegistrations *prometheus.CounterVec
	AudioUploads      *prometheus.CounterVec

	mu sync.RWMutex
}

// NewMetrics creates a new Metrics instance with all Prometheus metrics
func NewMetrics() *Metrics {
	return &Metrics{
		// HTTP Request metrics
		RequestsTotal: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "http_requests_total",
				Help: "Total number of HTTP requests",
			},
			[]string{"method", "endpoint", "status_code"},
		),
		RequestDuration: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "http_request_duration_seconds",
				Help:    "Duration of HTTP requests in seconds",
				Buckets: prometheus.DefBuckets,
			},
			[]string{"method", "endpoint", "status_code"},
		),
		RequestSize: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "http_request_size_bytes",
				Help:    "Size of HTTP requests in bytes",
				Buckets: prometheus.ExponentialBuckets(1024, 2, 10),
			},
			[]string{"method", "endpoint"},
		),
		ResponseSize: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "http_response_size_bytes",
				Help:    "Size of HTTP responses in bytes",
				Buckets: prometheus.ExponentialBuckets(1024, 2, 10),
			},
			[]string{"method", "endpoint", "status_code"},
		),

		// Error metrics
		ErrorsTotal: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "errors_total",
				Help: "Total number of errors",
			},
			[]string{"type", "severity", "endpoint"},
		),
		ErrorRate: promauto.NewGaugeVec(
			prometheus.GaugeOpts{
				Name: "error_rate",
				Help: "Current error rate as a percentage",
			},
			[]string{"endpoint", "time_window"},
		),

		// Database metrics
		DBConnections: promauto.NewGaugeVec(
			prometheus.GaugeOpts{
				Name: "db_connections",
				Help: "Number of database connections",
			},
			[]string{"state"}, // open, idle, in_use
		),
		DBQueryDuration: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "db_query_duration_seconds",
				Help:    "Duration of database queries in seconds",
				Buckets: prometheus.DefBuckets,
			},
			[]string{"operation", "table"},
		),
		DBQueryTotal: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "db_queries_total",
				Help: "Total number of database queries",
			},
			[]string{"operation", "table", "status"},
		),

		// Cache metrics
		CacheHits: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "cache_hits_total",
				Help: "Total number of cache hits",
			},
			[]string{"cache_type", "key_pattern"},
		),
		CacheMisses: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "cache_misses_total",
				Help: "Total number of cache misses",
			},
			[]string{"cache_type", "key_pattern"},
		),
		CacheOperationDuration: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "cache_operation_duration_seconds",
				Help:    "Duration of cache operations in seconds",
				Buckets: prometheus.DefBuckets,
			},
			[]string{"operation", "cache_type"},
		),

		// Application metrics
		ActiveUsers: promauto.NewGaugeVec(
			prometheus.GaugeOpts{
				Name: "active_users",
				Help: "Number of currently active users",
			},
			[]string{"time_window"}, // 5m, 15m, 1h, 24h
		),
		BusinessOperations: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "business_operations_total",
				Help: "Total number of business operations",
			},
			[]string{"operation", "status", "user_type"},
		),

		// System metrics
		MemoryUsage: promauto.NewGaugeVec(
			prometheus.GaugeOpts{
				Name: "memory_usage_bytes",
				Help: "Memory usage in bytes",
			},
			[]string{"type"}, // heap, stack, gc
		),
		CPUUsage: promauto.NewGaugeVec(
			prometheus.GaugeOpts{
				Name: "cpu_usage_percent",
				Help: "CPU usage percentage",
			},
			[]string{"core"},
		),
		GoroutineCount: promauto.NewGaugeVec(
			prometheus.GaugeOpts{
				Name: "goroutines_count",
				Help: "Number of goroutines",
			},
			[]string{},
		),

		// Custom business metrics
		ExamsCompleted: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "exams_completed_total",
				Help: "Total number of completed exams",
			},
			[]string{"exam_type", "difficulty"},
		),
		UserRegistrations: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "user_registrations_total",
				Help: "Total number of user registrations",
			},
			[]string{"source", "role"},
		),
		AudioUploads: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "audio_uploads_total",
				Help: "Total number of audio uploads",
			},
			[]string{"status", "format"},
		),
	}
}

// MetricsConfig holds configuration for metrics collection
type MetricsConfig struct {
	Enabled                 bool
	CollectionInterval      time.Duration
	DBMonitoringEnabled     bool
	CacheMonitoringEnabled  bool
	SystemMonitoringEnabled bool
	CustomLabels            map[string]string
}

// DefaultMetricsConfig returns default metrics configuration
func DefaultMetricsConfig() *MetricsConfig {
	return &MetricsConfig{
		Enabled:                 true,
		CollectionInterval:      30 * time.Second,
		DBMonitoringEnabled:     true,
		CacheMonitoringEnabled:  true,
		SystemMonitoringEnabled: true,
		CustomLabels:            make(map[string]string),
	}
}

// Monitor is the main monitoring service
type Monitor struct {
	metrics   *Metrics
	config    *MetricsConfig
	db        *sql.DB
	cache     cache.Cache
	appConfig config.Config

	// For tracking request metrics
	activeRequests sync.Map
	errorWindow    *ErrorWindow
}

// ErrorWindow tracks errors in a time window for calculating error rates
type ErrorWindow struct {
	mu     sync.RWMutex
	errors []time.Time
	window time.Duration
}

// NewErrorWindow creates a new error window
func NewErrorWindow(window time.Duration) *ErrorWindow {
	return &ErrorWindow{
		errors: make([]time.Time, 0),
		window: window,
	}
}

// AddError adds an error to the window
func (ew *ErrorWindow) AddError() {
	ew.mu.Lock()
	defer ew.mu.Unlock()

	now := time.Now()
	ew.errors = append(ew.errors, now)

	// Clean old errors
	ew.cleanOldErrors(now)
}

// GetErrorRate returns the current error rate (errors per minute)
func (ew *ErrorWindow) GetErrorRate() float64 {
	ew.mu.RLock()
	defer ew.mu.RUnlock()

	now := time.Now()
	ew.cleanOldErrors(now)

	if len(ew.errors) == 0 {
		return 0
	}

	// Calculate rate as errors per minute
	windowMinutes := ew.window.Minutes()
	return float64(len(ew.errors)) / windowMinutes
}

func (ew *ErrorWindow) cleanOldErrors(now time.Time) {
	cutoff := now.Add(-ew.window)
	i := 0
	for i < len(ew.errors) && ew.errors[i].Before(cutoff) {
		i++
	}
	if i > 0 {
		ew.errors = ew.errors[i:]
	}
}

// NewMonitor creates a new monitoring service
func NewMonitor(db *sql.DB, cache cache.Cache, appConfig config.Config, metricsConfig *MetricsConfig) *Monitor {
	if metricsConfig == nil {
		metricsConfig = DefaultMetricsConfig()
	}

	return &Monitor{
		metrics:     NewMetrics(),
		config:      metricsConfig,
		db:          db,
		cache:       cache,
		appConfig:   appConfig,
		errorWindow: NewErrorWindow(5 * time.Minute),
	}
}

// GetMetrics returns the metrics instance
func (m *Monitor) GetMetrics() *Metrics {
	return m.metrics
}

// GetPrometheusMetrics returns a Gin handler for Prometheus metrics endpoint
func (m *Monitor) GetPrometheusMetrics() gin.HandlerFunc {
	handler := promhttp.Handler()
	return gin.WrapH(handler)
}

// RecordRequest records HTTP request metrics
func (m *Monitor) RecordRequest(method, endpoint, statusCode string, duration time.Duration, requestSize, responseSize int64) {
	if !m.config.Enabled {
		return
	}

	m.metrics.RequestsTotal.WithLabelValues(method, endpoint, statusCode).Inc()
	m.metrics.RequestDuration.WithLabelValues(method, endpoint, statusCode).Observe(duration.Seconds())
	m.metrics.RequestSize.WithLabelValues(method, endpoint).Observe(float64(requestSize))
	m.metrics.ResponseSize.WithLabelValues(method, endpoint, statusCode).Observe(float64(responseSize))
}

// RecordError records error metrics
func (m *Monitor) RecordError(errorType, severity, endpoint string) {
	if !m.config.Enabled {
		return
	}

	m.metrics.ErrorsTotal.WithLabelValues(errorType, severity, endpoint).Inc()
	m.errorWindow.AddError()

	// Update error rate
	errorRate := m.errorWindow.GetErrorRate()
	m.metrics.ErrorRate.WithLabelValues(endpoint, "5m").Set(errorRate)
}

// RecordDBQuery records database query metrics
func (m *Monitor) RecordDBQuery(operation, table, status string, duration time.Duration) {
	if !m.config.Enabled || !m.config.DBMonitoringEnabled {
		return
	}

	m.metrics.DBQueryTotal.WithLabelValues(operation, table, status).Inc()
	m.metrics.DBQueryDuration.WithLabelValues(operation, table).Observe(duration.Seconds())
}

// RecordCacheOperation records cache operation metrics
func (m *Monitor) RecordCacheOperation(operation, cacheType string, hit bool, duration time.Duration) {
	if !m.config.Enabled || !m.config.CacheMonitoringEnabled {
		return
	}

	m.metrics.CacheOperationDuration.WithLabelValues(operation, cacheType).Observe(duration.Seconds())

	if hit {
		m.metrics.CacheHits.WithLabelValues(cacheType, "general").Inc()
	} else {
		m.metrics.CacheMisses.WithLabelValues(cacheType, "general").Inc()
	}
}

// RecordBusinessOperation records business operation metrics
func (m *Monitor) RecordBusinessOperation(operation, status, userType string) {
	if !m.config.Enabled {
		return
	}

	m.metrics.BusinessOperations.WithLabelValues(operation, status, userType).Inc()
}

// Start starts the monitoring service with periodic collection
func (m *Monitor) Start() {
	if !m.config.Enabled {
		logger.Info("Monitoring is disabled")
		return
	}

	logger.Info("Starting monitoring service with collection interval: %v", m.config.CollectionInterval)

	ticker := time.NewTicker(m.config.CollectionInterval)
	go func() {
		for range ticker.C {
			m.collectSystemMetrics()
			m.collectDBMetrics()
		}
	}()
}

// collectSystemMetrics collects system-level metrics
func (m *Monitor) collectSystemMetrics() {
	if !m.config.SystemMonitoringEnabled {
		return
	}

	// Collect runtime metrics
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)

	m.metrics.MemoryUsage.WithLabelValues("heap").Set(float64(memStats.HeapAlloc))
	m.metrics.MemoryUsage.WithLabelValues("heap_sys").Set(float64(memStats.HeapSys))
	m.metrics.MemoryUsage.WithLabelValues("stack").Set(float64(memStats.StackSys))

	m.metrics.GoroutineCount.WithLabelValues().Set(float64(runtime.NumGoroutine()))
}

// collectDBMetrics collects database metrics
func (m *Monitor) collectDBMetrics() {
	if !m.config.DBMonitoringEnabled || m.db == nil {
		return
	}

	stats := m.db.Stats()
	m.metrics.DBConnections.WithLabelValues("open").Set(float64(stats.OpenConnections))
	m.metrics.DBConnections.WithLabelValues("idle").Set(float64(stats.Idle))
	m.metrics.DBConnections.WithLabelValues("in_use").Set(float64(stats.InUse))
}

// Middleware returns a Gin middleware for automatic metrics collection
func (m *Monitor) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !m.config.Enabled {
			c.Next()
			return
		}

		start := time.Now()
		path := c.Request.URL.Path
		method := c.Request.Method

		// Get request size
		requestSize := c.Request.ContentLength
		if requestSize < 0 {
			requestSize = 0
		}

		c.Next()

		duration := time.Since(start)
		statusCode := string(rune(c.Writer.Status()))

		// Get response size
		responseSize := int64(c.Writer.Size())

		// Record metrics
		m.RecordRequest(method, path, statusCode, duration, requestSize, responseSize)

		// Record error if status code indicates an error
		if c.Writer.Status() >= 400 {
			severity := "low"
			if c.Writer.Status() >= 500 {
				severity = "high"
			}
			m.RecordError("http_error", severity, path)
		}
	}
}
