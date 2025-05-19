package scheduler

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
)

// BackupScheduler manages scheduled database backups
type BackupScheduler struct {
	interval    time.Duration
	backupFunc  func() error
	stopChan    chan struct{}
	wg          *sync.WaitGroup
	isRunning   bool
	mutex       sync.Mutex
	description string
}

// NewBackupScheduler creates a new backup scheduler
func NewBackupScheduler(interval time.Duration, backupFunc func() error, description string) *BackupScheduler {
	return &BackupScheduler{
		interval:    interval,
		backupFunc:  backupFunc,
		stopChan:    make(chan struct{}),
		wg:          &sync.WaitGroup{},
		isRunning:   false,
		description: description,
	}
}

// Start begins the scheduled backups
func (bs *BackupScheduler) Start() error {
	bs.mutex.Lock()
	defer bs.mutex.Unlock()

	if bs.isRunning {
		return fmt.Errorf("backup scheduler is already running")
	}

	bs.wg.Add(1)
	bs.isRunning = true

	// Start the backup goroutine
	go bs.runBackups()

	logger.Info("Backup scheduler started with interval: %v, description: %s", bs.interval, bs.description)
	return nil
}

// Stop stops the scheduled backups
func (bs *BackupScheduler) Stop() error {
	bs.mutex.Lock()
	defer bs.mutex.Unlock()

	if !bs.isRunning {
		return fmt.Errorf("backup scheduler is not running")
	}

	bs.stopChan <- struct{}{}
	bs.wg.Wait()
	bs.isRunning = false

	logger.Info("Backup scheduler stopped: %s", bs.description)
	return nil
}

// IsRunning returns whether the scheduler is currently running
func (bs *BackupScheduler) IsRunning() bool {
	bs.mutex.Lock()
	defer bs.mutex.Unlock()
	return bs.isRunning
}

// SetInterval changes the backup interval
func (bs *BackupScheduler) SetInterval(interval time.Duration) {
	bs.mutex.Lock()
	defer bs.mutex.Unlock()

	if bs.interval != interval {
		bs.interval = interval
		logger.Info("Backup scheduler interval changed to: %v, description: %s", interval, bs.description)
	}
}

// runBackups is the main backup loop
func (bs *BackupScheduler) runBackups() {
	defer bs.wg.Done()

	// Create a ticker for the backup interval
	ticker := time.NewTicker(bs.interval)
	defer ticker.Stop()

	logger.Info("Starting backup scheduler loop with interval: %v", bs.interval)

	// Run first backup immediately
	bs.executeBackup()

	// Then run on schedule
	for {
		select {
		case <-ticker.C:
			bs.executeBackup()
		case <-bs.stopChan:
			logger.Info("Backup scheduler received stop signal")
			return
		}
	}
}

// executeBackup performs a single backup
func (bs *BackupScheduler) executeBackup() {
	logger.Info("Executing scheduled backup: %s", bs.description)

	if err := bs.backupFunc(); err != nil {
		logger.Error("Scheduled backup failed: %v", err)
	} else {
		logger.Info("Scheduled backup completed successfully: %s", bs.description)
	}
}

// DefaultDailyBackupSchedule returns a scheduler that runs daily backups
func DefaultDailyBackupSchedule(backupFunc func() error) *BackupScheduler {
	// Schedule for 3 AM every day
	return NewBackupScheduler(24*time.Hour, backupFunc, "Daily backup at 3 AM")
}

// StartBackupScheduler initializes and starts the backup scheduler
func StartBackupScheduler(ctx context.Context, cfg config.Config, backupFunc func() error) (*BackupScheduler, error) {
	// Parse backup schedule from config
	backupIntervalHours := 24 // Default to daily

	// Create scheduler with config
	scheduler := NewBackupScheduler(
		time.Duration(backupIntervalHours)*time.Hour,
		backupFunc,
		fmt.Sprintf("Scheduled backup every %d hours", backupIntervalHours),
	)

	// Start the scheduler
	if err := scheduler.Start(); err != nil {
		return nil, err
	}

	// Set up cancellation on context done
	go func() {
		<-ctx.Done()
		if scheduler.IsRunning() {
			logger.Info("Context cancelled, stopping backup scheduler")
			_ = scheduler.Stop()
		}
	}()

	return scheduler, nil
}
