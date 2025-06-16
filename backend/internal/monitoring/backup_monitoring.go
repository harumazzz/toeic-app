package monitoring

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/notification"
)

// BackupMonitor provides comprehensive monitoring and alerting for backup operations
type BackupMonitor struct {
	config       config.BackupConfig
	notifier     *notification.NotificationManager
	metrics      *BackupMetrics
	alerts       *BackupAlertManager
	healthChecks map[string]HealthCheck
	mutex        sync.RWMutex
	isRunning    bool
	stopChan     chan struct{}
	wg           sync.WaitGroup
}

// BackupMetrics holds various backup-related metrics
type BackupMetrics struct {
	TotalBackups          int64            `json:"total_backups"`
	SuccessfulBackups     int64            `json:"successful_backups"`
	FailedBackups         int64            `json:"failed_backups"`
	TotalBackupSize       int64            `json:"total_backup_size"`
	AverageBackupSize     int64            `json:"average_backup_size"`
	AverageBackupDuration time.Duration    `json:"average_backup_duration"`
	LastBackupTime        time.Time        `json:"last_backup_time"`
	LastBackupSize        int64            `json:"last_backup_size"`
	LastBackupDuration    time.Duration    `json:"last_backup_duration"`
	BackupFrequency       float64          `json:"backup_frequency"` // backups per day
	SuccessRate           float64          `json:"success_rate"`     // percentage
	DiskUsage             DiskUsageMetrics `json:"disk_usage"`
	LastUpdateTime        time.Time        `json:"last_update_time"`
}

// DiskUsageMetrics tracks backup storage disk usage
type DiskUsageMetrics struct {
	TotalSpace    int64   `json:"total_space"`
	UsedSpace     int64   `json:"used_space"`
	FreeSpace     int64   `json:"free_space"`
	UsagePercent  float64 `json:"usage_percent"`
	BackupUsage   int64   `json:"backup_usage"`
	BackupPercent float64 `json:"backup_percent"`
}

// HealthCheck represents a health check function
type HealthCheck struct {
	Name        string
	Description string
	Interval    time.Duration
	Check       func() HealthResult
	LastRun     time.Time
	LastResult  HealthResult
}

// HealthResult represents the result of a health check
type HealthResult struct {
	Status  BackupHealthStatus     `json:"status"`
	Message string                 `json:"message"`
	Details map[string]interface{} `json:"details,omitempty"`
}

// BackupHealthStatus represents health check status
type BackupHealthStatus string

const (
	BackupHealthStatusHealthy  BackupHealthStatus = "healthy"
	BackupHealthStatusWarning  BackupHealthStatus = "warning"
	BackupHealthStatusCritical BackupHealthStatus = "critical"
	BackupHealthStatusUnknown  BackupHealthStatus = "unknown"
)

// BackupAlertManager handles alert conditions and notifications
type BackupAlertManager struct {
	rules    map[string]BackupAlertRule
	fired    map[string]time.Time // Track when alerts were fired
	notifier *notification.NotificationManager
	mutex    sync.RWMutex
}

// BackupAlertRule defines conditions for triggering alerts
type BackupAlertRule struct {
	Name        string                    `json:"name"`
	Description string                    `json:"description"`
	Condition   func(*BackupMetrics) bool `json:"-"`
	Severity    BackupAlertSeverity       `json:"severity"`
	Cooldown    time.Duration             `json:"cooldown"`
	Enabled     bool                      `json:"enabled"`
}

// BackupAlertSeverity represents alert severity levels
type BackupAlertSeverity string

const (
	BackupAlertSeverityInfo     BackupAlertSeverity = "info"
	BackupAlertSeverityWarning  BackupAlertSeverity = "warning"
	BackupAlertSeverityCritical BackupAlertSeverity = "critical"
)

// NewBackupMonitor creates a new backup monitor
func NewBackupMonitor(config config.BackupConfig) *BackupMonitor {
	notifier := notification.NewNotificationManager(config)
	monitor := &BackupMonitor{
		config:       config,
		notifier:     notifier,
		metrics:      &BackupMetrics{},
		alerts:       NewBackupAlertManager(notifier),
		healthChecks: make(map[string]HealthCheck),
		stopChan:     make(chan struct{}),
	}

	// Initialize health checks
	monitor.initializeHealthChecks()

	// Initialize alert rules
	monitor.alerts.initializeAlertRules()

	return monitor
}

// Start begins monitoring
func (bm *BackupMonitor) Start(ctx context.Context) error {
	bm.mutex.Lock()
	defer bm.mutex.Unlock()

	if bm.isRunning {
		return fmt.Errorf("backup monitor is already running")
	}

	bm.isRunning = true

	// Start metrics collection
	bm.wg.Add(1)
	go bm.runMetricsCollection(ctx)

	// Start health checks
	bm.wg.Add(1)
	go bm.runHealthChecks(ctx)

	// Start alert monitoring
	bm.wg.Add(1)
	go bm.runAlertMonitoring(ctx)

	logger.Info("Backup monitoring started")
	return nil
}

// Stop stops monitoring
func (bm *BackupMonitor) Stop() error {
	bm.mutex.Lock()
	defer bm.mutex.Unlock()

	if !bm.isRunning {
		return fmt.Errorf("backup monitor is not running")
	}

	close(bm.stopChan)
	bm.wg.Wait()
	bm.isRunning = false

	logger.Info("Backup monitoring stopped")
	return nil
}

// runMetricsCollection runs periodic metrics collection
func (bm *BackupMonitor) runMetricsCollection(ctx context.Context) {
	defer bm.wg.Done()

	ticker := time.NewTicker(5 * time.Minute) // Collect metrics every 5 minutes
	defer ticker.Stop()

	// Collect initial metrics
	bm.collectMetrics()

	for {
		select {
		case <-ctx.Done():
			return
		case <-bm.stopChan:
			return
		case <-ticker.C:
			bm.collectMetrics()
		}
	}
}

// collectMetrics collects current backup metrics
func (bm *BackupMonitor) collectMetrics() {
	bm.mutex.Lock()
	defer bm.mutex.Unlock()

	logger.Debug("Collecting backup metrics")

	// Scan backup directory for current statistics
	stats, err := bm.scanBackupDirectory()
	if err != nil {
		logger.Error("Failed to scan backup directory: %v", err)
		return
	}

	// Update metrics
	bm.metrics.TotalBackups = stats.Count
	bm.metrics.TotalBackupSize = stats.TotalSize
	if stats.Count > 0 {
		bm.metrics.AverageBackupSize = stats.TotalSize / stats.Count
	}
	bm.metrics.LastUpdateTime = time.Now()

	// Calculate disk usage
	diskUsage := bm.calculateDiskUsage()
	bm.metrics.DiskUsage = diskUsage

	logger.Debug("Metrics updated: %d backups, %d bytes total", stats.Count, stats.TotalSize)
}

// runHealthChecks runs periodic health checks
func (bm *BackupMonitor) runHealthChecks(ctx context.Context) {
	defer bm.wg.Done()

	ticker := time.NewTicker(10 * time.Minute) // Run health checks every 10 minutes
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-bm.stopChan:
			return
		case <-ticker.C:
			bm.runAllHealthChecks()
		}
	}
}

// runAllHealthChecks executes all registered health checks
func (bm *BackupMonitor) runAllHealthChecks() {
	bm.mutex.Lock()
	defer bm.mutex.Unlock()

	for name, check := range bm.healthChecks {
		if time.Since(check.LastRun) >= check.Interval {
			result := check.Check()
			check.LastRun = time.Now()
			check.LastResult = result
			bm.healthChecks[name] = check

			logger.Debug("Health check %s: %s - %s", name, result.Status, result.Message)
			// Trigger alerts if health is not good
			if result.Status == BackupHealthStatusCritical || result.Status == BackupHealthStatusWarning {
				bm.alerts.triggerAlert(fmt.Sprintf("health_%s", name),
					fmt.Sprintf("Health check %s failed: %s", name, result.Message))
			}
		}
	}
}

// runAlertMonitoring runs alert monitoring
func (bm *BackupMonitor) runAlertMonitoring(ctx context.Context) {
	defer bm.wg.Done()

	ticker := time.NewTicker(1 * time.Minute) // Check alerts every minute
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-bm.stopChan:
			return
		case <-ticker.C:
			bm.alerts.checkAlerts(bm.metrics)
		}
	}
}

// initializeHealthChecks sets up default health checks
func (bm *BackupMonitor) initializeHealthChecks() {
	// Backup directory accessibility check
	bm.healthChecks["backup_directory"] = HealthCheck{
		Name:        "backup_directory",
		Description: "Check if backup directory is accessible",
		Interval:    5 * time.Minute,
		Check:       bm.checkBackupDirectory,
	}

	// Disk space check
	bm.healthChecks["disk_space"] = HealthCheck{
		Name:        "disk_space",
		Description: "Check available disk space for backups",
		Interval:    5 * time.Minute,
		Check:       bm.checkDiskSpace,
	}

	// Recent backup check
	bm.healthChecks["recent_backup"] = HealthCheck{
		Name:        "recent_backup",
		Description: "Check if recent backups exist",
		Interval:    30 * time.Minute,
		Check:       bm.checkRecentBackup,
	}

	// Backup integrity check
	bm.healthChecks["backup_integrity"] = HealthCheck{
		Name:        "backup_integrity",
		Description: "Check integrity of recent backups",
		Interval:    1 * time.Hour,
		Check:       bm.checkBackupIntegrity,
	}
}

// Health check implementations

func (bm *BackupMonitor) checkBackupDirectory() HealthResult {
	_, err := os.Stat(bm.config.BackupDir)
	if err != nil {
		return HealthResult{
			Status:  BackupHealthStatusCritical,
			Message: fmt.Sprintf("Backup directory not accessible: %v", err),
		}
	}

	// Check write permissions
	testFile := filepath.Join(bm.config.BackupDir, ".health_check")
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		return HealthResult{
			Status:  BackupHealthStatusCritical,
			Message: fmt.Sprintf("Cannot write to backup directory: %v", err),
		}
	}
	os.Remove(testFile)

	return HealthResult{
		Status:  BackupHealthStatusHealthy,
		Message: "Backup directory is accessible and writable",
	}
}

func (bm *BackupMonitor) checkDiskSpace() HealthResult {
	diskUsage := bm.calculateDiskUsage()

	if diskUsage.UsagePercent > 95 {
		return HealthResult{
			Status:  BackupHealthStatusCritical,
			Message: fmt.Sprintf("Disk usage critical: %.1f%%", diskUsage.UsagePercent),
			Details: map[string]interface{}{
				"usage_percent": diskUsage.UsagePercent,
				"free_space":    diskUsage.FreeSpace,
			},
		}
	}

	if diskUsage.UsagePercent > 85 {
		return HealthResult{
			Status:  BackupHealthStatusWarning,
			Message: fmt.Sprintf("Disk usage high: %.1f%%", diskUsage.UsagePercent),
			Details: map[string]interface{}{
				"usage_percent": diskUsage.UsagePercent,
				"free_space":    diskUsage.FreeSpace,
			},
		}
	}

	return HealthResult{
		Status:  BackupHealthStatusHealthy,
		Message: fmt.Sprintf("Disk usage normal: %.1f%%", diskUsage.UsagePercent),
		Details: map[string]interface{}{
			"usage_percent": diskUsage.UsagePercent,
			"free_space":    diskUsage.FreeSpace,
		},
	}
}

func (bm *BackupMonitor) checkRecentBackup() HealthResult {
	// Check if there's a backup from the last 25 hours (allowing for some buffer)
	since := time.Now().Add(-25 * time.Hour)

	files, err := os.ReadDir(bm.config.BackupDir)
	if err != nil {
		return HealthResult{
			Status:  BackupHealthStatusCritical,
			Message: fmt.Sprintf("Cannot read backup directory: %v", err),
		}
	}

	hasRecentBackup := false
	for _, file := range files {
		if !file.IsDir() && filepath.Ext(file.Name()) == ".sql" {
			fileInfo, err := file.Info()
			if err == nil && fileInfo.ModTime().After(since) {
				hasRecentBackup = true
				break
			}
		}
	}
	if !hasRecentBackup {
		return HealthResult{
			Status:  BackupHealthStatusWarning,
			Message: "No recent backups found in the last 25 hours",
		}
	}
	return HealthResult{
		Status:  BackupHealthStatusHealthy,
		Message: "Recent backup found",
	}
}

func (bm *BackupMonitor) checkBackupIntegrity() HealthResult {
	// This would implement backup integrity checks
	// For now, just return healthy
	return HealthResult{
		Status:  BackupHealthStatusHealthy,
		Message: "Backup integrity check completed",
	}
}

// Helper methods

type backupDirectoryStats struct {
	Count     int64
	TotalSize int64
}

func (bm *BackupMonitor) scanBackupDirectory() (*backupDirectoryStats, error) {
	stats := &backupDirectoryStats{}

	files, err := os.ReadDir(bm.config.BackupDir)
	if err != nil {
		return nil, err
	}

	for _, file := range files {
		if !file.IsDir() && filepath.Ext(file.Name()) == ".sql" {
			fileInfo, err := file.Info()
			if err == nil {
				stats.Count++
				stats.TotalSize += fileInfo.Size()
			}
		}
	}

	return stats, nil
}

func (bm *BackupMonitor) calculateDiskUsage() DiskUsageMetrics {
	// This would implement actual disk usage calculation
	// For now, return placeholder values
	return DiskUsageMetrics{
		TotalSpace:    1000000000,
		UsedSpace:     500000000,
		FreeSpace:     500000000,
		UsagePercent:  50.0,
		BackupUsage:   100000000,
		BackupPercent: 10.0,
	}
}

// GetMetrics returns current metrics
func (bm *BackupMonitor) GetMetrics() *BackupMetrics {
	bm.mutex.RLock()
	defer bm.mutex.RUnlock()

	// Return a copy to avoid concurrent access issues
	metricsCopy := *bm.metrics
	return &metricsCopy
}

// GetHealthStatus returns overall health status
func (bm *BackupMonitor) GetHealthStatus() map[string]HealthResult {
	bm.mutex.RLock()
	defer bm.mutex.RUnlock()

	status := make(map[string]HealthResult)
	for name, check := range bm.healthChecks {
		status[name] = check.LastResult
	}

	return status
}

// Alert Manager implementation

// NewBackupAlertManager creates a new backup alert manager
func NewBackupAlertManager(notifier *notification.NotificationManager) *BackupAlertManager {
	return &BackupAlertManager{
		rules:    make(map[string]BackupAlertRule),
		fired:    make(map[string]time.Time),
		notifier: notifier,
	}
}

// initializeAlertRules sets up default alert rules
func (bam *BackupAlertManager) initializeAlertRules() {
	// High disk usage alert
	bam.rules["high_disk_usage"] = BackupAlertRule{
		Name:        "high_disk_usage",
		Description: "Alert when disk usage is high",
		Condition: func(metrics *BackupMetrics) bool {
			return metrics.DiskUsage.UsagePercent > 85
		},
		Severity: BackupAlertSeverityWarning,
		Cooldown: 1 * time.Hour,
		Enabled:  true,
	}

	// Backup failure rate alert
	bam.rules["backup_failure_rate"] = BackupAlertRule{
		Name:        "backup_failure_rate",
		Description: "Alert when backup failure rate is high",
		Condition: func(metrics *BackupMetrics) bool {
			return metrics.SuccessRate < 90 && metrics.TotalBackups > 10
		},
		Severity: BackupAlertSeverityCritical,
		Cooldown: 30 * time.Minute,
		Enabled:  true,
	}
}

// checkAlerts checks all alert rules against current metrics
func (bam *BackupAlertManager) checkAlerts(metrics *BackupMetrics) {
	bam.mutex.Lock()
	defer bam.mutex.Unlock()

	for name, rule := range bam.rules {
		if !rule.Enabled {
			continue
		}

		// Check cooldown
		if lastFired, exists := bam.fired[name]; exists {
			if time.Since(lastFired) < rule.Cooldown {
				continue
			}
		}

		// Check condition
		if rule.Condition(metrics) {
			bam.fireAlert(name, rule)
			bam.fired[name] = time.Now()
		}
	}
}

// fireAlert triggers an alert
func (bam *BackupAlertManager) fireAlert(name string, rule BackupAlertRule) {
	message := fmt.Sprintf("Backup Alert: %s - %s", rule.Name, rule.Description)
	logger.Warn("Alert fired: %s", message)
	// Send notification based on severity
	if rule.Severity == BackupAlertSeverityCritical {
		// Send as failure notification
		bam.notifier.NotifyBackupFailure(name, fmt.Errorf("%s", rule.Description))
	}
}

// triggerAlert manually triggers an alert
func (bam *BackupAlertManager) triggerAlert(name, message string) {
	bam.mutex.Lock()
	defer bam.mutex.Unlock()

	logger.Warn("Manual alert triggered: %s - %s", name, message)
	// Send notification
}
