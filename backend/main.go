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
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
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
