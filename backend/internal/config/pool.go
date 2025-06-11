package config

import (
	"database/sql"
	"runtime"
	"time"

	"github.com/toeic-app/internal/logger"
)

// DatabasePoolConfig holds database connection pool configuration
type DatabasePoolConfig struct {
	MaxOpenConns    int           `mapstructure:"DB_MAX_OPEN_CONNS"`
	MaxIdleConns    int           `mapstructure:"DB_MAX_IDLE_CONNS"`
	ConnMaxLifetime time.Duration `mapstructure:"DB_CONN_MAX_LIFETIME"`
	ConnMaxIdleTime time.Duration `mapstructure:"DB_CONN_MAX_IDLE_TIME"`
}

// GetOptimalPoolConfig returns optimized database pool configuration based on system resources
func GetOptimalPoolConfig() DatabasePoolConfig {
	numCPU := runtime.NumCPU()

	// Scale connection pool based on CPU cores and expected concurrency
	// For high-concurrency applications, aim for 2-4 connections per CPU core
	maxOpenConns := numCPU * 4
	if maxOpenConns < 20 {
		maxOpenConns = 20 // Minimum for decent concurrency
	}
	if maxOpenConns > 100 {
		maxOpenConns = 100 // Cap to prevent resource exhaustion
	}

	// Keep a good balance of idle connections (about 25-50% of max)
	maxIdleConns := maxOpenConns / 3
	if maxIdleConns < 5 {
		maxIdleConns = 5
	}

	return DatabasePoolConfig{
		MaxOpenConns:    maxOpenConns,
		MaxIdleConns:    maxIdleConns,
		ConnMaxLifetime: 10 * time.Minute, // Longer lifetime for stability
		ConnMaxIdleTime: 2 * time.Minute,  // Reasonable idle timeout
	}
}

func SetupPool(db *sql.DB) {
	config := GetOptimalPoolConfig()
	SetupPoolWithConfig(db, config)
}

func SetupPoolWithConfig(db *sql.DB, config DatabasePoolConfig) {
	// Set the maximum number of open connections to the database
	db.SetMaxOpenConns(config.MaxOpenConns)
	// Set the maximum number of idle connections in the pool
	db.SetMaxIdleConns(config.MaxIdleConns)
	// Set the maximum lifetime of a connection in the pool
	db.SetConnMaxLifetime(config.ConnMaxLifetime)
	// Set the maximum idle time for connections
	db.SetConnMaxIdleTime(config.ConnMaxIdleTime)

	logger.Info("Database connection pool configured: MaxOpen=%d, MaxIdle=%d, Lifetime=%v, IdleTime=%v",
		config.MaxOpenConns, config.MaxIdleConns, config.ConnMaxLifetime, config.ConnMaxIdleTime)
}
