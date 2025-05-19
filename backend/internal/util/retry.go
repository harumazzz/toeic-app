package util

import (
	"fmt"
	"time"

	"github.com/toeic-app/internal/logger"
)

// RetryConfig defines configuration for retry operations
type RetryConfig struct {
	MaxRetries  int
	InitialWait time.Duration
	MaxWait     time.Duration
	Factor      float64 // Backoff factor (e.g., 2.0 means double the wait time after each failure)
}

// DefaultRetryConfig returns a default retry configuration
func DefaultRetryConfig() RetryConfig {
	return RetryConfig{
		MaxRetries:  3,
		InitialWait: 500 * time.Millisecond,
		MaxWait:     10 * time.Second,
		Factor:      2.0,
	}
}

// RetryOperation retries a function with exponential backoff
func RetryOperation(operation func() error, config RetryConfig) error {
	var err error
	wait := config.InitialWait

	for attempt := 1; attempt <= config.MaxRetries; attempt++ {
		err = operation()
		if err == nil {
			// Operation successful
			return nil
		}

		// If this was the last attempt, return the error
		if attempt == config.MaxRetries {
			return fmt.Errorf("operation failed after %d attempts: %w", config.MaxRetries, err)
		}

		// Log the retry
		logger.Warn("Operation failed (attempt %d/%d), retrying in %v: %v",
			attempt, config.MaxRetries, wait, err)

		// Wait before retrying
		time.Sleep(wait)

		// Increase the wait time for the next attempt, up to MaxWait
		nextWait := time.Duration(float64(wait) * config.Factor)
		if nextWait > config.MaxWait {
			wait = config.MaxWait
		} else {
			wait = nextWait
		}
	}

	// This should not be reached, but just in case
	return err
}
