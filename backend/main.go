package main

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	_ "github.com/lib/pq"
	_ "github.com/toeic-app/docs"
	"github.com/toeic-app/internal/api"
	"github.com/toeic-app/internal/config"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/middleware"
	"github.com/toeic-app/internal/util"
)

func main() {
	// Initialize logger
	logDir := filepath.Join(".", "logs")
	err := logger.InitFileLogger(logDir, logger.LevelDebug)
	if err != nil {
		fmt.Printf("Failed to initialize logger: %v\n", err)
		os.Exit(1)
	}

	logger.Info("Starting TOEIC application...")

	// Load configuration
	cfg := config.DefaultConfig()
	logger.Info("Configuration loaded successfully")

	// Register custom validators
	middleware.RegisterValidators()
	logger.Debug("Custom validators registered")

	// Check if database tools (pg_dump, psql) are available
	// This is optional - if tools are not available, the backup/restore features won't work
	if err := util.CheckDatabaseTools(); err != nil {
		logger.Warn("Database backup/restore tools not available: %v", err)
		logger.Warn("Backup/restore functionality will be limited")
	}

	// Open a connection to the database
	logger.Info("Connecting to database: %s", cfg.DBDriver)
	conn, err := sql.Open(cfg.DBDriver, cfg.DBSource)
	if err != nil {
		logger.Fatal("Could not connect to database: %v", err)
	}

	// Test the connection
	err = conn.Ping()
	if err != nil {
		logger.Fatal("Could not ping database: %v", err)
	}
	config.SetupPool(conn)

	logger.Info("Successfully connected to database!")

	// Initialize queries with connection
	queries := db.New(conn)
	if err != nil {
		logger.Warn("Note: Could not create test user: %v. This may be okay if user already exists.", err)
	} // Initialize and start the API server
	logger.Info("Initializing API server...")
	server, err := api.NewServer(cfg, queries)
	if err != nil {
		logger.Fatal("Cannot create server: %v", err)
	}

	// Create a background context for automatic backups
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Setup automatic database backups
	if err := server.StartAutomaticBackups(ctx); err != nil {
		logger.Warn("Failed to setup automatic backups: %v", err)
		logger.Warn("Will continue without automatic backups")
	} else {
		logger.Info("Automatic database backups configured successfully")

		// Setup cleanup of old backups (keep backups for 30 days)
		go func() {
			// Initial cleanup
			if err := server.CleanupOldBackups(30 * 24 * time.Hour); err != nil {
				logger.Warn("Failed to clean up old backups: %v", err)
			}

			// Periodic cleanup (once a day)
			ticker := time.NewTicker(24 * time.Hour)
			defer ticker.Stop()

			for {
				select {
				case <-ticker.C:
					if err := server.CleanupOldBackups(30 * 24 * time.Hour); err != nil {
						logger.Warn("Failed to clean up old backups: %v", err)
					}
				case <-ctx.Done():
					return
				}
			}
		}()
	}

	logger.Info("Starting API server on %s", cfg.ServerAddress)

	// Set up graceful shutdown
	go func() {
		if err := server.Start(cfg.ServerAddress); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Could not start server: %v", err)
		}
	}()
	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	// Listen for interrupt and SIGTERM signals
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit

	logger.Info("Shutdown signal received...")

	// Create a deadline to wait for current operations to complete
	ctx, cancel = context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// First shut down the server
	if err := server.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown: %v", err)
	}

	// Set release mode
	server.SetReleaseMode()

	// Then close the database connection
	if conn != nil {
		logger.Info("Closing database connection...")
		if err := conn.Close(); err != nil {
			logger.Error("Error closing database connection: %v", err)
		} else {
			logger.Info("Database connection closed successfully")
		}
	}

	logger.Info("Server exited gracefully")
}
