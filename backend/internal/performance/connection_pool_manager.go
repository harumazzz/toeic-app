package performance

import (
	"database/sql"
	"sync"
	"time"

	"github.com/toeic-app/internal/logger"
)

// ConnectionPoolManager manages database connection pools with monitoring and auto-scaling
type ConnectionPoolManager struct {
	db              *sql.DB
	config          ConnectionPoolConfig
	stats           *PoolStats
	alertThresholds AlertThresholds

	// Monitoring
	monitorTicker  *time.Ticker
	stopMonitoring chan bool

	// Auto-scaling
	autoScaleEnabled bool
	scaleHistory     []ScaleEvent
	scaleMutex       sync.RWMutex

	// Circuit breaker
	circuitBreaker *CircuitBreaker
}

// ConnectionPoolConfig holds configuration for connection pool management
type ConnectionPoolConfig struct {
	InitialMaxOpen     int
	InitialMaxIdle     int
	MinMaxOpen         int
	MaxMaxOpen         int
	ScaleUpThreshold   float64 // Percentage of max connections in use to trigger scale up
	ScaleDownThreshold float64 // Percentage of max connections in use to trigger scale down
	ScaleStep          int     // Number of connections to add/remove during scaling
	MonitorInterval    time.Duration
	StatsRetention     time.Duration
}

// PoolStats holds connection pool statistics over time
type PoolStats struct {
	Current        sql.DBStats
	History        []PoolStatsSnapshot
	MaxConnUsage   float64 // Peak connection usage percentage
	AvgConnUsage   float64 // Average connection usage percentage
	LastScaleEvent time.Time
	ScaleEvents    int
	mutex          sync.RWMutex
}

// PoolStatsSnapshot represents pool stats at a point in time
type PoolStatsSnapshot struct {
	Timestamp       time.Time
	Stats           sql.DBStats
	UsagePercentage float64
}

// AlertThresholds defines thresholds for connection pool alerts
type AlertThresholds struct {
	HighUsageThreshold    float64       // Alert when usage exceeds this percentage
	LongWaitThreshold     time.Duration // Alert when wait time exceeds this duration
	TooManyWaitsThreshold int64         // Alert when wait count exceeds this number
}

// ScaleEvent represents a connection pool scaling event
type ScaleEvent struct {
	Timestamp    time.Time
	Type         string // "scale_up" or "scale_down"
	OldMaxOpen   int
	NewMaxOpen   int
	Reason       string
	UsagePercent float64
}

// CircuitBreaker prevents database overload
type CircuitBreaker struct {
	maxFailures  int
	resetTimeout time.Duration
	failures     int
	lastFailure  time.Time
	state        string // "closed", "open", "half-open"
	mutex        sync.RWMutex
}

// NewConnectionPoolManager creates a new connection pool manager
func NewConnectionPoolManager(db *sql.DB, config ConnectionPoolConfig) *ConnectionPoolManager {
	if config.MonitorInterval == 0 {
		config.MonitorInterval = 30 * time.Second
	}
	if config.StatsRetention == 0 {
		config.StatsRetention = 24 * time.Hour
	}
	if config.ScaleUpThreshold == 0 {
		config.ScaleUpThreshold = 80.0 // 80%
	}
	if config.ScaleDownThreshold == 0 {
		config.ScaleDownThreshold = 30.0 // 30%
	}
	if config.ScaleStep == 0 {
		config.ScaleStep = 5
	}

	cpm := &ConnectionPoolManager{
		db:               db,
		config:           config,
		stats:            &PoolStats{History: make([]PoolStatsSnapshot, 0)},
		stopMonitoring:   make(chan bool),
		autoScaleEnabled: true,
		alertThresholds: AlertThresholds{
			HighUsageThreshold:    90.0, // 90%
			LongWaitThreshold:     5 * time.Second,
			TooManyWaitsThreshold: 100,
		},
		circuitBreaker: &CircuitBreaker{
			maxFailures:  10,
			resetTimeout: 60 * time.Second,
			state:        "closed",
		},
	}

	// Start monitoring
	cpm.startMonitoring()

	logger.Info("Connection pool manager initialized with auto-scaling enabled")
	return cpm
}

// startMonitoring starts the connection pool monitoring routine
func (cpm *ConnectionPoolManager) startMonitoring() {
	cpm.monitorTicker = time.NewTicker(cpm.config.MonitorInterval)

	go func() {
		for {
			select {
			case <-cpm.monitorTicker.C:
				cpm.collectStats()
				cpm.checkAndScale()
				cpm.checkAlerts()
			case <-cpm.stopMonitoring:
				cpm.monitorTicker.Stop()
				return
			}
		}
	}()
}

// collectStats collects current connection pool statistics
func (cpm *ConnectionPoolManager) collectStats() {
	cpm.stats.mutex.Lock()
	defer cpm.stats.mutex.Unlock()

	cpm.stats.Current = cpm.db.Stats()

	// Calculate usage percentage
	var usagePercent float64
	if cpm.stats.Current.MaxOpenConnections > 0 {
		usagePercent = float64(cpm.stats.Current.InUse) / float64(cpm.stats.Current.MaxOpenConnections) * 100
	}

	// Add to history
	snapshot := PoolStatsSnapshot{
		Timestamp:       time.Now(),
		Stats:           cpm.stats.Current,
		UsagePercentage: usagePercent,
	}

	cpm.stats.History = append(cpm.stats.History, snapshot)

	// Update peak and average usage
	if usagePercent > cpm.stats.MaxConnUsage {
		cpm.stats.MaxConnUsage = usagePercent
	}

	// Calculate rolling average (last 10 samples)
	if len(cpm.stats.History) > 0 {
		samples := len(cpm.stats.History)
		if samples > 10 {
			samples = 10
		}

		total := 0.0
		for i := len(cpm.stats.History) - samples; i < len(cpm.stats.History); i++ {
			total += cpm.stats.History[i].UsagePercentage
		}
		cpm.stats.AvgConnUsage = total / float64(samples)
	}

	// Clean old history
	cpm.cleanOldStats()
}

// cleanOldStats removes old statistics beyond retention period
func (cpm *ConnectionPoolManager) cleanOldStats() {
	cutoff := time.Now().Add(-cpm.config.StatsRetention)

	// Find the first index to keep
	keepFrom := 0
	for i, snapshot := range cpm.stats.History {
		if snapshot.Timestamp.After(cutoff) {
			keepFrom = i
			break
		}
	}

	// Keep only recent stats
	if keepFrom > 0 {
		cpm.stats.History = cpm.stats.History[keepFrom:]
	}
}

// checkAndScale checks if scaling is needed and performs it
func (cpm *ConnectionPoolManager) checkAndScale() {
	if !cpm.autoScaleEnabled {
		return
	}

	cpm.stats.mutex.RLock()
	currentUsage := cpm.stats.AvgConnUsage
	maxOpen := cpm.stats.Current.MaxOpenConnections
	cpm.stats.mutex.RUnlock()

	// Prevent too frequent scaling
	if time.Since(cpm.stats.LastScaleEvent) < 2*time.Minute {
		return
	}

	// Scale up if usage is high
	if currentUsage > cpm.config.ScaleUpThreshold && maxOpen < cpm.config.MaxMaxOpen {
		newMaxOpen := maxOpen + cpm.config.ScaleStep
		if newMaxOpen > cpm.config.MaxMaxOpen {
			newMaxOpen = cpm.config.MaxMaxOpen
		}

		cpm.scaleUp(newMaxOpen, currentUsage)
	}

	// Scale down if usage is low
	if currentUsage < cpm.config.ScaleDownThreshold && maxOpen > cpm.config.MinMaxOpen {
		newMaxOpen := maxOpen - cpm.config.ScaleStep
		if newMaxOpen < cpm.config.MinMaxOpen {
			newMaxOpen = cpm.config.MinMaxOpen
		}

		cpm.scaleDown(newMaxOpen, currentUsage)
	}
}

// scaleUp increases the maximum number of open connections
func (cpm *ConnectionPoolManager) scaleUp(newMaxOpen int, currentUsage float64) {
	cpm.scaleMutex.Lock()
	defer cpm.scaleMutex.Unlock()

	oldMaxOpen := cpm.db.Stats().MaxOpenConnections
	cpm.db.SetMaxOpenConns(newMaxOpen)

	// Also scale idle connections proportionally
	newMaxIdle := newMaxOpen / 3
	if newMaxIdle < 5 {
		newMaxIdle = 5
	}
	cpm.db.SetMaxIdleConns(newMaxIdle)

	// Record scale event
	event := ScaleEvent{
		Timestamp:    time.Now(),
		Type:         "scale_up",
		OldMaxOpen:   oldMaxOpen,
		NewMaxOpen:   newMaxOpen,
		Reason:       "high_usage",
		UsagePercent: currentUsage,
	}

	cpm.scaleHistory = append(cpm.scaleHistory, event)
	cpm.stats.LastScaleEvent = time.Now()
	cpm.stats.ScaleEvents++

	logger.Info("Scaled up connection pool: %d -> %d connections (usage: %.1f%%)",
		oldMaxOpen, newMaxOpen, currentUsage)
}

// scaleDown decreases the maximum number of open connections
func (cpm *ConnectionPoolManager) scaleDown(newMaxOpen int, currentUsage float64) {
	cpm.scaleMutex.Lock()
	defer cpm.scaleMutex.Unlock()

	oldMaxOpen := cpm.db.Stats().MaxOpenConnections
	cpm.db.SetMaxOpenConns(newMaxOpen)

	// Also scale idle connections proportionally
	newMaxIdle := newMaxOpen / 3
	if newMaxIdle < 5 {
		newMaxIdle = 5
	}
	cpm.db.SetMaxIdleConns(newMaxIdle)

	// Record scale event
	event := ScaleEvent{
		Timestamp:    time.Now(),
		Type:         "scale_down",
		OldMaxOpen:   oldMaxOpen,
		NewMaxOpen:   newMaxOpen,
		Reason:       "low_usage",
		UsagePercent: currentUsage,
	}

	cpm.scaleHistory = append(cpm.scaleHistory, event)
	cpm.stats.LastScaleEvent = time.Now()
	cpm.stats.ScaleEvents++

	logger.Info("Scaled down connection pool: %d -> %d connections (usage: %.1f%%)",
		oldMaxOpen, newMaxOpen, currentUsage)
}

// checkAlerts checks for conditions that require alerts
func (cpm *ConnectionPoolManager) checkAlerts() {
	cpm.stats.mutex.RLock()
	stats := cpm.stats.Current
	cpm.stats.mutex.RUnlock()

	// High usage alert
	if stats.MaxOpenConnections > 0 {
		usagePercent := float64(stats.InUse) / float64(stats.MaxOpenConnections) * 100
		if usagePercent > cpm.alertThresholds.HighUsageThreshold {
			logger.Warn("High database connection usage: %.1f%% (%d/%d connections)",
				usagePercent, stats.InUse, stats.MaxOpenConnections)
		}
	}

	// Long wait time alert
	if stats.WaitDuration > cpm.alertThresholds.LongWaitThreshold {
		logger.Warn("Long database connection wait time: %v (wait count: %d)",
			stats.WaitDuration, stats.WaitCount)
	}

	// Too many waits alert
	if stats.WaitCount > cpm.alertThresholds.TooManyWaitsThreshold {
		logger.Warn("High database connection wait count: %d", stats.WaitCount)
	}
}

// GetStats returns current connection pool statistics
func (cpm *ConnectionPoolManager) GetStats() *PoolStats {
	cpm.stats.mutex.RLock()
	defer cpm.stats.mutex.RUnlock()

	// Return a copy to avoid race conditions
	stats := &PoolStats{
		Current:        cpm.stats.Current,
		MaxConnUsage:   cpm.stats.MaxConnUsage,
		AvgConnUsage:   cpm.stats.AvgConnUsage,
		LastScaleEvent: cpm.stats.LastScaleEvent,
		ScaleEvents:    cpm.stats.ScaleEvents,
	}

	// Copy history
	stats.History = make([]PoolStatsSnapshot, len(cpm.stats.History))
	copy(stats.History, cpm.stats.History)

	return stats
}

// GetScaleHistory returns the scaling history
func (cpm *ConnectionPoolManager) GetScaleHistory() []ScaleEvent {
	cpm.scaleMutex.RLock()
	defer cpm.scaleMutex.RUnlock()

	history := make([]ScaleEvent, len(cpm.scaleHistory))
	copy(history, cpm.scaleHistory)
	return history
}

// SetAutoScaling enables or disables auto-scaling
func (cpm *ConnectionPoolManager) SetAutoScaling(enabled bool) {
	cpm.autoScaleEnabled = enabled
	logger.Info("Connection pool auto-scaling: %v", enabled)
}

// IsCircuitBreakerOpen checks if the circuit breaker is open
func (cpm *ConnectionPoolManager) IsCircuitBreakerOpen() bool {
	cpm.circuitBreaker.mutex.RLock()
	defer cpm.circuitBreaker.mutex.RUnlock()

	// Reset circuit breaker if timeout has passed
	if cpm.circuitBreaker.state == "open" &&
		time.Since(cpm.circuitBreaker.lastFailure) > cpm.circuitBreaker.resetTimeout {
		cpm.circuitBreaker.state = "half-open"
		cpm.circuitBreaker.failures = 0
	}

	return cpm.circuitBreaker.state == "open"
}

// RecordFailure records a database operation failure
func (cpm *ConnectionPoolManager) RecordFailure() {
	cpm.circuitBreaker.mutex.Lock()
	defer cpm.circuitBreaker.mutex.Unlock()

	cpm.circuitBreaker.failures++
	cpm.circuitBreaker.lastFailure = time.Now()

	if cpm.circuitBreaker.failures >= cpm.circuitBreaker.maxFailures {
		cpm.circuitBreaker.state = "open"
		logger.Warn("Database circuit breaker opened due to %d failures", cpm.circuitBreaker.failures)
	}
}

// RecordSuccess records a successful database operation
func (cpm *ConnectionPoolManager) RecordSuccess() {
	cpm.circuitBreaker.mutex.Lock()
	defer cpm.circuitBreaker.mutex.Unlock()

	if cpm.circuitBreaker.state == "half-open" {
		cpm.circuitBreaker.state = "closed"
		cpm.circuitBreaker.failures = 0
		logger.Info("Database circuit breaker closed after successful operation")
	}
}

// Stop stops the connection pool monitoring
func (cpm *ConnectionPoolManager) Stop() {
	close(cpm.stopMonitoring)
	logger.Info("Connection pool manager stopped")
}

// ResetStats resets all connection pool statistics
func (cpm *ConnectionPoolManager) ResetStats() error {
	logger.Info("Resetting connection pool statistics...")

	cpm.stats.mutex.Lock()
	defer cpm.stats.mutex.Unlock()

	// Reset statistics
	cpm.stats.MaxConnUsage = 0
	cpm.stats.AvgConnUsage = 0
	cpm.stats.LastScaleEvent = time.Time{}
	cpm.stats.ScaleEvents = 0

	// Clear history
	cpm.stats.History = make([]PoolStatsSnapshot, 0)
	// Reset scale history
	cpm.scaleMutex.Lock()
	cpm.scaleHistory = make([]ScaleEvent, 0)
	cpm.scaleMutex.Unlock()

	// Reset circuit breaker
	cpm.circuitBreaker.mutex.Lock()
	cpm.circuitBreaker.failures = 0
	cpm.circuitBreaker.lastFailure = time.Time{}
	cpm.circuitBreaker.state = "closed"
	cpm.circuitBreaker.mutex.Unlock()

	logger.Info("Connection pool statistics reset successfully")
	return nil
}
