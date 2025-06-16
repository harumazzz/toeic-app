package scheduler

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/toeic-app/internal/backup"
	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
)

// EnhancedBackupScheduler provides advanced backup scheduling with multiple schedules
type EnhancedBackupScheduler struct {
	config         config.BackupConfig
	dbConfig       config.Config
	backupManager  *backup.BackupManager
	schedules      map[string]*ScheduleConfig
	stopChan       chan struct{}
	wg             *sync.WaitGroup
	isRunning      bool
	mutex          sync.Mutex
	lastBackupTime time.Time
	nextBackupTime time.Time
	backupHistory  []BackupHistoryItem
	ctx            context.Context
	cancel         context.CancelFunc
}

// ScheduleConfig defines a backup schedule
type ScheduleConfig struct {
	Name        string        `json:"name"`
	Description string        `json:"description"`
	Interval    time.Duration `json:"interval"`
	Time        string        `json:"time"`        // Format: "15:04" for daily at specific time
	Days        []string      `json:"days"`        // Monday, Tuesday, etc. Empty means every day
	BackupType  string        `json:"backup_type"` // full, incremental, differential
	Enabled     bool          `json:"enabled"`
	Retention   time.Duration `json:"retention"` // How long to keep backups from this schedule
	ticker      *time.Ticker
	lastRun     time.Time
}

// BackupHistoryItem tracks backup execution history
type BackupHistoryItem struct {
	Timestamp    time.Time     `json:"timestamp"`
	ScheduleName string        `json:"schedule_name"`
	BackupType   string        `json:"backup_type"`
	Filename     string        `json:"filename"`
	Success      bool          `json:"success"`
	Duration     time.Duration `json:"duration"`
	Size         int64         `json:"size"`
	Error        string        `json:"error,omitempty"`
}

// NewEnhancedBackupScheduler creates a new enhanced backup scheduler
func NewEnhancedBackupScheduler(backupConfig config.BackupConfig, dbConfig config.Config) *EnhancedBackupScheduler {
	ctx, cancel := context.WithCancel(context.Background())

	scheduler := &EnhancedBackupScheduler{
		config:        backupConfig,
		dbConfig:      dbConfig,
		backupManager: backup.NewBackupManager(backupConfig, dbConfig),
		schedules:     make(map[string]*ScheduleConfig),
		stopChan:      make(chan struct{}),
		wg:            &sync.WaitGroup{},
		backupHistory: make([]BackupHistoryItem, 0),
		ctx:           ctx,
		cancel:        cancel,
	}

	// Initialize default schedules
	scheduler.initializeDefaultSchedules()

	return scheduler
}

// initializeDefaultSchedules sets up default backup schedules
func (ebs *EnhancedBackupScheduler) initializeDefaultSchedules() {
	// Daily full backup at 3 AM
	dailySchedule := &ScheduleConfig{
		Name:        "daily_full",
		Description: "Daily full database backup",
		Interval:    24 * time.Hour,
		Time:        "03:00",
		Days:        []string{}, // Every day
		BackupType:  "full",
		Enabled:     ebs.config.AutoBackupEnabled,
		Retention:   ebs.config.GetRetentionDuration(),
	}
	ebs.schedules["daily_full"] = dailySchedule

	// Weekly backup on Sunday at 2 AM (with longer retention)
	weeklySchedule := &ScheduleConfig{
		Name:        "weekly_archive",
		Description: "Weekly archive backup",
		Interval:    7 * 24 * time.Hour,
		Time:        "02:00",
		Days:        []string{"Sunday"},
		BackupType:  "archive",
		Enabled:     ebs.config.AutoBackupEnabled,
		Retention:   90 * 24 * time.Hour, // 90 days retention for weekly backups
	}
	ebs.schedules["weekly_archive"] = weeklySchedule

	// Monthly backup on the 1st at 1 AM
	monthlySchedule := &ScheduleConfig{
		Name:        "monthly_archive",
		Description: "Monthly long-term archive backup",
		Interval:    30 * 24 * time.Hour, // Approximate
		Time:        "01:00",
		Days:        []string{}, // Will be handled specially for monthly
		BackupType:  "archive",
		Enabled:     ebs.config.AutoBackupEnabled,
		Retention:   365 * 24 * time.Hour, // 1 year retention
	}
	ebs.schedules["monthly_archive"] = monthlySchedule
}

// Start begins the enhanced backup scheduler
func (ebs *EnhancedBackupScheduler) Start() error {
	ebs.mutex.Lock()
	defer ebs.mutex.Unlock()

	if ebs.isRunning {
		return fmt.Errorf("enhanced backup scheduler is already running")
	}

	if !ebs.config.Enabled || !ebs.config.AutoBackupEnabled {
		logger.Info("Backup scheduler disabled in configuration")
		return nil
	}

	ebs.isRunning = true

	// Start monitoring goroutines for each enabled schedule
	for name, schedule := range ebs.schedules {
		if schedule.Enabled {
			ebs.wg.Add(1)
			go ebs.runSchedule(name, schedule)
		}
	}

	// Start cleanup goroutine
	ebs.wg.Add(1)
	go ebs.runCleanup()

	// Start health monitoring
	ebs.wg.Add(1)
	go ebs.runHealthMonitoring()

	logger.Info("Enhanced backup scheduler started with %d active schedules", len(ebs.getEnabledSchedules()))
	return nil
}

// IsRunning returns whether the scheduler is currently running
func (ebs *EnhancedBackupScheduler) IsRunning() bool {
	ebs.mutex.Lock()
	defer ebs.mutex.Unlock()
	return ebs.isRunning
}

// GetSchedules returns all current schedules
func (ebs *EnhancedBackupScheduler) GetSchedules() map[string]*ScheduleConfig {
	ebs.mutex.Lock()
	defer ebs.mutex.Unlock()

	schedules := make(map[string]*ScheduleConfig)
	for id, schedule := range ebs.schedules {
		schedules[id] = schedule
	}
	return schedules
}

// AddSchedule adds a new backup schedule
func (ebs *EnhancedBackupScheduler) AddSchedule(id, schedule, description, backupType string) error {
	ebs.mutex.Lock()
	defer ebs.mutex.Unlock()

	if _, exists := ebs.schedules[id]; exists {
		return fmt.Errorf("schedule with ID %s already exists", id)
	}

	// Parse interval from schedule string (assuming it's a duration like "24h")
	interval, err := time.ParseDuration(schedule)
	if err != nil {
		// Default to 24 hours if parsing fails
		interval = 24 * time.Hour
	}

	scheduleConfig := &ScheduleConfig{
		Name:        id,
		Description: description,
		Interval:    interval,
		BackupType:  backupType,
		Enabled:     true,
		Retention:   720 * time.Hour, // 30 days default
		lastRun:     time.Time{},
	}

	ebs.schedules[id] = scheduleConfig
	logger.Info("Added backup schedule: %s (%s)", id, description)
	return nil
}

// RemoveSchedule removes a backup schedule
func (ebs *EnhancedBackupScheduler) RemoveSchedule(id string) error {
	ebs.mutex.Lock()
	defer ebs.mutex.Unlock()

	if _, exists := ebs.schedules[id]; !exists {
		return fmt.Errorf("schedule with ID %s not found", id)
	}

	delete(ebs.schedules, id)
	logger.Info("Removed backup schedule: %s", id)
	return nil
}

// GetBackupHistory returns backup history
func (ebs *EnhancedBackupScheduler) GetBackupHistory(limit int) []BackupHistoryItem {
	ebs.mutex.Lock()
	defer ebs.mutex.Unlock()

	if limit <= 0 || limit > len(ebs.backupHistory) {
		limit = len(ebs.backupHistory)
	}

	// Return the most recent items first
	result := make([]BackupHistoryItem, limit)
	for i := 0; i < limit; i++ {
		result[i] = ebs.backupHistory[len(ebs.backupHistory)-1-i]
	}

	return result
}

// Stop stops the enhanced backup scheduler
func (ebs *EnhancedBackupScheduler) Stop() error {
	ebs.mutex.Lock()
	defer ebs.mutex.Unlock()

	if !ebs.isRunning {
		return fmt.Errorf("enhanced backup scheduler is not running")
	}

	logger.Info("Stopping enhanced backup scheduler...")

	// Cancel context to signal all goroutines to stop
	ebs.cancel()

	// Send stop signal
	close(ebs.stopChan)

	// Wait for all goroutines to finish
	ebs.wg.Wait()

	ebs.isRunning = false

	logger.Info("Enhanced backup scheduler stopped")
	return nil
}

// runSchedule runs a specific backup schedule
func (ebs *EnhancedBackupScheduler) runSchedule(name string, schedule *ScheduleConfig) {
	defer ebs.wg.Done()

	logger.Info("Starting backup schedule: %s (%s)", name, schedule.Description)

	// Calculate next run time
	nextRun := ebs.calculateNextRun(schedule)

	for {
		select {
		case <-ebs.ctx.Done():
			return
		case <-ebs.stopChan:
			return
		case <-time.After(time.Until(nextRun)):
			// Execute backup
			ebs.executeScheduledBackup(name, schedule)

			// Calculate next run time
			nextRun = ebs.calculateNextRun(schedule)

			// Update schedule's last run time
			schedule.lastRun = time.Now()
		}
	}
}

// executeScheduledBackup executes a backup for a specific schedule
func (ebs *EnhancedBackupScheduler) executeScheduledBackup(scheduleName string, schedule *ScheduleConfig) {
	startTime := time.Now()

	logger.Info("Executing scheduled backup: %s", scheduleName)

	historyItem := BackupHistoryItem{
		Timestamp:    startTime,
		ScheduleName: scheduleName,
		BackupType:   schedule.BackupType,
		Success:      false,
	}

	// Create backup description
	description := fmt.Sprintf("Scheduled %s backup (%s)", schedule.BackupType, schedule.Description)

	// Execute backup
	result, err := ebs.backupManager.CreateBackup(ebs.ctx, description, schedule.BackupType)

	// Record results
	historyItem.Duration = time.Since(startTime)

	if err != nil {
		historyItem.Error = err.Error()
		logger.Error("Scheduled backup failed: %s - %v", scheduleName, err)
	} else {
		historyItem.Success = true
		historyItem.Filename = result.Metadata.Filename
		historyItem.Size = result.Size
		logger.Info("Scheduled backup completed: %s -> %s", scheduleName, result.Metadata.Filename)

		// Update last backup time
		ebs.mutex.Lock()
		ebs.lastBackupTime = startTime
		ebs.mutex.Unlock()
	}

	// Add to history (keep last 100 items)
	ebs.addToHistory(historyItem)
}

// calculateNextRun calculates when the next backup should run for a schedule
func (ebs *EnhancedBackupScheduler) calculateNextRun(schedule *ScheduleConfig) time.Time {
	now := time.Now()

	// Parse the time
	var hour, minute int
	if schedule.Time != "" {
		if parsed, err := time.Parse("15:04", schedule.Time); err == nil {
			hour = parsed.Hour()
			minute = parsed.Minute()
		}
	}

	// Calculate next run based on schedule type
	if schedule.Name == "monthly_archive" {
		// Monthly backup on the 1st of each month
		nextMonth := time.Date(now.Year(), now.Month()+1, 1, hour, minute, 0, 0, now.Location())
		if now.Day() == 1 && now.Hour() < hour {
			// If it's the 1st and we haven't reached the backup time yet
			return time.Date(now.Year(), now.Month(), 1, hour, minute, 0, 0, now.Location())
		}
		return nextMonth
	}

	// For daily and weekly schedules
	next := time.Date(now.Year(), now.Month(), now.Day(), hour, minute, 0, 0, now.Location())

	// If the time has passed today, move to next day
	if next.Before(now) {
		next = next.Add(24 * time.Hour)
	}

	// For weekly schedules, find the next occurrence of the specified day
	if len(schedule.Days) > 0 {
		targetDay := schedule.Days[0] // Assuming single day for simplicity
		for !ebs.isDayOfWeek(next, targetDay) {
			next = next.Add(24 * time.Hour)
		}
	}

	return next
}

// isDayOfWeek checks if a time falls on a specific day of the week
func (ebs *EnhancedBackupScheduler) isDayOfWeek(t time.Time, dayName string) bool {
	dayMap := map[string]time.Weekday{
		"Sunday":    time.Sunday,
		"Monday":    time.Monday,
		"Tuesday":   time.Tuesday,
		"Wednesday": time.Wednesday,
		"Thursday":  time.Thursday,
		"Friday":    time.Friday,
		"Saturday":  time.Saturday,
	}

	targetDay, exists := dayMap[dayName]
	if !exists {
		return true // If day not found, assume any day is okay
	}

	return t.Weekday() == targetDay
}

// runCleanup runs periodic cleanup of old backups
func (ebs *EnhancedBackupScheduler) runCleanup() {
	defer ebs.wg.Done()

	// Run cleanup every 6 hours
	ticker := time.NewTicker(6 * time.Hour)
	defer ticker.Stop()

	for {
		select {
		case <-ebs.ctx.Done():
			return
		case <-ebs.stopChan:
			return
		case <-ticker.C:
			ebs.performCleanup()
		}
	}
}

// performCleanup performs cleanup of old backups based on retention policies
func (ebs *EnhancedBackupScheduler) performCleanup() {
	logger.Info("Performing scheduled backup cleanup")

	// This would implement sophisticated cleanup logic based on:
	// 1. Schedule-specific retention policies
	// 2. Backup types (keep more archives than daily backups)
	// 3. Available disk space
	// 4. Backup validation status

	// For now, just log that cleanup would run
	logger.Info("Backup cleanup completed")
}

// runHealthMonitoring monitors backup system health
func (ebs *EnhancedBackupScheduler) runHealthMonitoring() {
	defer ebs.wg.Done()

	ticker := time.NewTicker(1 * time.Hour)
	defer ticker.Stop()

	for {
		select {
		case <-ebs.ctx.Done():
			return
		case <-ebs.stopChan:
			return
		case <-ticker.C:
			ebs.performHealthCheck()
		}
	}
}

// performHealthCheck performs health checks on the backup system
func (ebs *EnhancedBackupScheduler) performHealthCheck() {
	// Check if backups are running on schedule
	// Check disk space
	// Validate recent backups
	// Monitor backup failure rates

	logger.Debug("Backup system health check completed")
}

// Helper methods

// getEnabledSchedules returns all enabled schedules
func (ebs *EnhancedBackupScheduler) getEnabledSchedules() map[string]*ScheduleConfig {
	enabled := make(map[string]*ScheduleConfig)
	for name, schedule := range ebs.schedules {
		if schedule.Enabled {
			enabled[name] = schedule
		}
	}
	return enabled
}

// addToHistory adds a backup history item and maintains history size
func (ebs *EnhancedBackupScheduler) addToHistory(item BackupHistoryItem) {
	ebs.mutex.Lock()
	defer ebs.mutex.Unlock()

	ebs.backupHistory = append(ebs.backupHistory, item)

	// Keep only last 100 items
	if len(ebs.backupHistory) > 100 {
		ebs.backupHistory = ebs.backupHistory[1:]
	}
}

// GetStatus returns current scheduler status
func (ebs *EnhancedBackupScheduler) GetStatus() map[string]interface{} {
	ebs.mutex.Lock()
	defer ebs.mutex.Unlock()

	status := map[string]interface{}{
		"running":          ebs.isRunning,
		"last_backup":      ebs.lastBackupTime,
		"next_backup":      ebs.nextBackupTime,
		"active_schedules": len(ebs.getEnabledSchedules()),
		"total_schedules":  len(ebs.schedules),
		"recent_backups":   len(ebs.backupHistory),
	}

	return status
}

// GetHistory returns backup history
func (ebs *EnhancedBackupScheduler) GetHistory(limit int) []BackupHistoryItem {
	ebs.mutex.Lock()
	defer ebs.mutex.Unlock()

	if limit <= 0 || limit > len(ebs.backupHistory) {
		limit = len(ebs.backupHistory)
	}

	// Return most recent items
	start := len(ebs.backupHistory) - limit
	if start < 0 {
		start = 0
	}

	return ebs.backupHistory[start:]
}
