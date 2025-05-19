package scheduler

import (
	"errors"
	"sync/atomic"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestBackupScheduler(t *testing.T) {
	// Counter for number of backups performed
	var counter int32

	// Mock backup function that increments counter
	mockBackup := func() error {
		atomic.AddInt32(&counter, 1)
		return nil
	}

	// Create scheduler with 50ms interval for testing
	scheduler := NewBackupScheduler(50*time.Millisecond, mockBackup, "Test backup")

	// Check initial state
	assert.False(t, scheduler.IsRunning())

	// Start scheduler
	err := scheduler.Start()
	assert.NoError(t, err)
	assert.True(t, scheduler.IsRunning())

	// Try to start again (should fail)
	err = scheduler.Start()
	assert.Error(t, err)

	// Wait for a few ticks
	time.Sleep(150 * time.Millisecond)

	// Stop scheduler
	err = scheduler.Stop()
	assert.NoError(t, err)
	assert.False(t, scheduler.IsRunning())

	// Check that backups were performed (should be at least 2: immediate + ticks)
	count := atomic.LoadInt32(&counter)
	assert.GreaterOrEqual(t, count, int32(2), "Expected at least 2 backups to run")
}

func TestBackupSchedulerFailure(t *testing.T) {
	// Mock backup function that always fails
	mockFailingBackup := func() error {
		return errors.New("backup failed")
	}

	// Create scheduler with 50ms interval for testing
	scheduler := NewBackupScheduler(50*time.Millisecond, mockFailingBackup, "Test failing backup")

	// Start scheduler
	err := scheduler.Start()
	assert.NoError(t, err)

	// Wait for a tick
	time.Sleep(100 * time.Millisecond)

	// Stop scheduler
	err = scheduler.Stop()
	assert.NoError(t, err)

	// The test passes if we reach here without panicking
}

func TestBackupSchedulerIntervalChange(t *testing.T) {
	// Counter for backups
	var counter int32

	// Mock backup function
	mockBackup := func() error {
		atomic.AddInt32(&counter, 1)
		return nil
	}

	// Create scheduler with 1 hour interval initially
	scheduler := NewBackupScheduler(1*time.Hour, mockBackup, "Test interval")

	// Start scheduler
	err := scheduler.Start()
	assert.NoError(t, err)

	// Change to a 10ms interval for testing
	scheduler.SetInterval(10 * time.Millisecond)

	// Wait for a few ticks with the new interval
	time.Sleep(50 * time.Millisecond)

	// Stop scheduler
	err = scheduler.Stop()
	assert.NoError(t, err)

	// Should have had multiple backups due to the shorter interval
	count := atomic.LoadInt32(&counter)
	assert.GreaterOrEqual(t, count, int32(2), "Expected multiple backups after interval change")
}
