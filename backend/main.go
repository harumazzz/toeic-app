package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
	_ "github.com/toeic-app/docs"
	"github.com/toeic-app/internal/api"
	"github.com/toeic-app/internal/config"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/middleware"
)

func main() {
	// Load configuration
	cfg := config.DefaultConfig()

	// Register custom validators
	middleware.RegisterValidators()

	// Open a connection to the database
	conn, err := sql.Open(cfg.DBDriver, cfg.DBSource)
	if err != nil {
		log.Fatalf("Could not connect to database: %v", err)
	}

	// Test the connection
	err = conn.Ping()
	if err != nil {
		log.Fatalf("Could not ping database: %v", err)
	}

	fmt.Println("Successfully connected to database!")

	// Initialize queries with connection
	queries := db.New(conn)
	if err != nil {
		log.Printf("Note: Could not create test user: %v. This may be okay if user already exists.", err)
	} // Initialize and start the API server
	server, err := api.NewServer(cfg, queries)
	if err != nil {
		log.Fatalf("Cannot create server: %v", err)
	}

	log.Printf("Starting API server on %s", cfg.ServerAddress)
	err = server.Start(cfg.ServerAddress)
	if err != nil {
		log.Fatalf("Could not start server: %v", err)
	}
}
