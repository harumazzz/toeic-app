package config

import (
	"database/sql"
	"time"
)

func SetupPool(db *sql.DB) {
	// Set the maximum number of open connections to the database
	db.SetMaxOpenConns(25)
	// Set the maximum number of idle connections in the pool
	db.SetMaxIdleConns(25)
	// Set the maximum lifetime of a connection in the pool
	db.SetConnMaxLifetime(5 * time.Minute)
}
