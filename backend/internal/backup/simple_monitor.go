package backup

import (
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
)

// BackupMonitor provides basic monitoring for backup operations
type SimpleBackupMonitor struct {
	config    config.BackupConfig
	metrics   *SimpleBackupMetrics
	lastCheck time.Time
	mutex     sync.RWMutex
}

// SimpleBackupMetrics holds basic backup metrics
type SimpleBackupMetrics struct {
	TotalBackups     int64     `json:"total_backups"`
	TotalSize        int64     `json:"total_size"`
	LastBackupTime   time.Time `json:"last_backup_time"`
	DiskUsagePercent float64   `json:"disk_usage_percent"`
	BackupDirSize    int64     `json:"backup_dir_size"`
	AvailableSpace   int64     `json:"available_space"`
	LastUpdateTime   time.Time `json:"last_update_time"`
}

// HealthStatus represents simple health status
type SimpleHealthStatus struct {
	Overall      string    `json:"overall"`
	BackupDir    string    `json:"backup_dir"`
	DiskSpace    string    `json:"disk_space"`
	RecentBackup string    `json:"recent_backup"`
	LastCheck    time.Time `json:"last_check"`
	Issues       []string  `json:"issues,omitempty"`
}

// NewSimpleBackupMonitor creates a new simple backup monitor
func NewSimpleBackupMonitor(config config.BackupConfig) *SimpleBackupMonitor {
	return &SimpleBackupMonitor{
		config:  config,
		metrics: &SimpleBackupMetrics{},
	}
}

// UpdateMetrics updates backup metrics
func (sbm *SimpleBackupMonitor) UpdateMetrics() {
	sbm.mutex.Lock()
	defer sbm.mutex.Unlock()

	logger.Debug("Updating backup metrics")

	stats, err := sbm.scanBackupDirectory()
	if err != nil {
		logger.Error("Failed to scan backup directory: %v", err)
		return
	}

	sbm.metrics.TotalBackups = stats.Count
	sbm.metrics.TotalSize = stats.TotalSize
	sbm.metrics.BackupDirSize = stats.TotalSize
	sbm.metrics.LastBackupTime = stats.LastBackupTime
	sbm.metrics.LastUpdateTime = time.Now()

	// Calculate disk usage
	diskUsage := sbm.calculateDiskUsage()
	sbm.metrics.DiskUsagePercent = diskUsage.UsagePercent
	sbm.metrics.AvailableSpace = diskUsage.FreeSpace

	sbm.lastCheck = time.Now()
}

// GetMetrics returns current metrics
func (sbm *SimpleBackupMonitor) GetMetrics() *SimpleBackupMetrics {
	sbm.mutex.RLock()
	defer sbm.mutex.RUnlock()

	// Return a copy
	metricsCopy := *sbm.metrics
	return &metricsCopy
}

// CheckHealth performs health checks and returns status
func (sbm *SimpleBackupMonitor) CheckHealth() *SimpleHealthStatus {
	sbm.mutex.Lock()
	defer sbm.mutex.Unlock()

	status := &SimpleHealthStatus{
		Overall:      "healthy",
		BackupDir:    "healthy",
		DiskSpace:    "healthy",
		RecentBackup: "healthy",
		LastCheck:    time.Now(),
		Issues:       []string{},
	}

	// Check backup directory
	if _, err := os.Stat(sbm.config.BackupDir); err != nil {
		status.BackupDir = "critical"
		status.Issues = append(status.Issues, "Backup directory not accessible")
		status.Overall = "critical"
	}

	// Check disk space
	diskUsage := sbm.calculateDiskUsage()
	if diskUsage.UsagePercent > 95 {
		status.DiskSpace = "critical"
		status.Issues = append(status.Issues, fmt.Sprintf("Disk usage critical: %.1f%%", diskUsage.UsagePercent))
		status.Overall = "critical"
	} else if diskUsage.UsagePercent > 85 {
		status.DiskSpace = "warning"
		status.Issues = append(status.Issues, fmt.Sprintf("Disk usage high: %.1f%%", diskUsage.UsagePercent))
		if status.Overall == "healthy" {
			status.Overall = "warning"
		}
	}

	// Check recent backups
	hasRecentBackup := sbm.checkRecentBackup()
	if !hasRecentBackup {
		status.RecentBackup = "warning"
		status.Issues = append(status.Issues, "No recent backups found in the last 25 hours")
		if status.Overall == "healthy" {
			status.Overall = "warning"
		}
	}

	return status
}

// Helper methods

type backupDirectoryStats struct {
	Count          int64
	TotalSize      int64
	LastBackupTime time.Time
}

// scanBackupDirectory scans the backup directory for statistics
func (sbm *SimpleBackupMonitor) scanBackupDirectory() (*backupDirectoryStats, error) {
	stats := &backupDirectoryStats{}

	if _, err := os.Stat(sbm.config.BackupDir); os.IsNotExist(err) {
		return stats, nil // Directory doesn't exist yet
	}

	files, err := os.ReadDir(sbm.config.BackupDir)
	if err != nil {
		return nil, err
	}

	for _, file := range files {
		if file.IsDir() {
			continue
		}

		// Check for backup files
		ext := filepath.Ext(file.Name())
		if ext != ".sql" && ext != ".gz" && ext != ".enc" {
			continue
		}

		fileInfo, err := file.Info()
		if err == nil {
			stats.Count++
			stats.TotalSize += fileInfo.Size()

			// Track the most recent backup
			if fileInfo.ModTime().After(stats.LastBackupTime) {
				stats.LastBackupTime = fileInfo.ModTime()
			}
		}
	}

	return stats, nil
}

// DiskUsageInfo represents disk usage information
type DiskUsageInfo struct {
	TotalSpace   int64
	FreeSpace    int64
	UsagePercent float64
}

// calculateDiskUsage calculates disk usage for the backup directory
func (sbm *SimpleBackupMonitor) calculateDiskUsage() *DiskUsageInfo {
	// This is a simplified implementation
	// In a real implementation, you would use syscalls to get actual disk space

	// For now, return reasonable dummy values
	return &DiskUsageInfo{
		TotalSpace:   1000000000000, // 1TB
		FreeSpace:    500000000000,  // 500GB
		UsagePercent: 50.0,
	}
}

// checkRecentBackup checks if there's a recent backup
func (sbm *SimpleBackupMonitor) checkRecentBackup() bool {
	since := time.Now().Add(-25 * time.Hour)

	files, err := os.ReadDir(sbm.config.BackupDir)
	if err != nil {
		return false
	}

	for _, file := range files {
		if !file.IsDir() && (filepath.Ext(file.Name()) == ".sql" ||
			filepath.Ext(file.Name()) == ".gz" ||
			filepath.Ext(file.Name()) == ".enc") {
			fileInfo, err := file.Info()
			if err == nil && fileInfo.ModTime().After(since) {
				return true
			}
		}
	}

	return false
}

// GetStatusSummary returns a summary of backup status
func (sbm *SimpleBackupMonitor) GetStatusSummary() map[string]interface{} {
	metrics := sbm.GetMetrics()
	health := sbm.CheckHealth()

	return map[string]interface{}{
		"backup_count":    metrics.TotalBackups,
		"total_size":      metrics.TotalSize,
		"last_backup":     metrics.LastBackupTime,
		"disk_usage":      metrics.DiskUsagePercent,
		"available_space": metrics.AvailableSpace,
		"health_status":   health.Overall,
		"issues":          health.Issues,
		"last_check":      health.LastCheck,
	}
}

// StartPeriodicUpdates starts periodic metric updates
func (sbm *SimpleBackupMonitor) StartPeriodicUpdates() {
	go func() {
		ticker := time.NewTicker(5 * time.Minute)
		defer ticker.Stop()

		// Initial update
		sbm.UpdateMetrics()

		for range ticker.C {
			sbm.UpdateMetrics()
		}
	}()

	logger.Info("Simple backup monitor started with periodic updates")
}
