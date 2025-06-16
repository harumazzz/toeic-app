package config

import (
	"database/sql"
	"time"

	"github.com/toeic-app/internal/logger"
)

// EnhancedPoolConfig holds enhanced database connection pool configuration
type EnhancedPoolConfig struct {
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
	ConnMaxIdleTime time.Duration

	// Performance optimizations
	HealthCheckInterval time.Duration
	RetryAttempts       int
	RetryDelay          time.Duration

	// Monitoring
	EnableMonitoring   bool
	LogSlowQueries     bool
	SlowQueryThreshold time.Duration
}

// DefaultEnhancedPoolConfig returns optimized default configuration for high performance
func DefaultEnhancedPoolConfig() EnhancedPoolConfig {
	return EnhancedPoolConfig{
		// Connection pool settings optimized for performance
		MaxOpenConns:    50,               // Increased for higher concurrency
		MaxIdleConns:    25,               // Half of max open connections
		ConnMaxLifetime: 60 * time.Minute, // 1 hour
		ConnMaxIdleTime: 15 * time.Minute, // 15 minutes

		// Health and retry settings
		HealthCheckInterval: 30 * time.Second,
		RetryAttempts:       3,
		RetryDelay:          100 * time.Millisecond,

		// Monitoring settings
		EnableMonitoring:   true,
		LogSlowQueries:     true,
		SlowQueryThreshold: 100 * time.Millisecond,
	}
}

// SetupEnhancedPool configures the database connection pool for optimal performance
func SetupEnhancedPool(db *sql.DB, config EnhancedPoolConfig) {
	logger.InfoWithFields(logger.Fields{
		"component":          "database",
		"operation":          "pool_setup",
		"max_open_conns":     config.MaxOpenConns,
		"max_idle_conns":     config.MaxIdleConns,
		"conn_max_lifetime":  config.ConnMaxLifetime.String(),
		"conn_max_idle_time": config.ConnMaxIdleTime.String(),
	}, "Configuring enhanced database connection pool")

	// Set connection pool parameters
	db.SetMaxOpenConns(config.MaxOpenConns)
	db.SetMaxIdleConns(config.MaxIdleConns)
	db.SetConnMaxLifetime(config.ConnMaxLifetime)
	db.SetConnMaxIdleTime(config.ConnMaxIdleTime)

	logger.InfoWithFields(logger.Fields{
		"component": "database",
		"operation": "pool_configured",
		"status":    "success",
	}, "Enhanced database connection pool configured successfully")
}

// GetPoolStats returns current connection pool statistics
func GetPoolStats(db *sql.DB) sql.DBStats {
	return db.Stats()
}

// LogPoolStats logs current connection pool statistics
func LogPoolStats(db *sql.DB) {
	stats := db.Stats()

	logger.InfoWithFields(logger.Fields{
		"component":            "database",
		"operation":            "pool_stats",
		"open_connections":     stats.OpenConnections,
		"in_use":               stats.InUse,
		"idle":                 stats.Idle,
		"wait_count":           stats.WaitCount,
		"wait_duration":        stats.WaitDuration.String(),
		"max_idle_closed":      stats.MaxIdleClosed,
		"max_idle_time_closed": stats.MaxIdleTimeClosed,
		"max_lifetime_closed":  stats.MaxLifetimeClosed,
	}, "Database connection pool statistics")

	// Log warnings for potential issues
	if stats.WaitCount > 0 {
		logger.WarnWithFields(logger.Fields{
			"component":     "database",
			"wait_count":    stats.WaitCount,
			"wait_duration": stats.WaitDuration.String(),
		}, "Database connections are waiting - consider increasing pool size")
	}

	if float64(stats.InUse)/float64(stats.OpenConnections) > 0.8 {
		logger.WarnWithFields(logger.Fields{
			"component":        "database",
			"utilization":      float64(stats.InUse) / float64(stats.OpenConnections),
			"in_use":           stats.InUse,
			"open_connections": stats.OpenConnections,
		}, "High database connection utilization")
	}
}
