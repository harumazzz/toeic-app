package config

import (
	"crypto/tls"
	"database/sql"
	"fmt"
	"time"

	"github.com/toeic-app/internal/logger"
)

// DatabaseSecurityConfig holds database security settings
type DatabaseSecurityConfig struct {
	SSLMode            string
	SSLCert            string
	SSLKey             string
	SSLRootCert        string
	ConnectionTimeout  time.Duration
	MaxOpenConnections int
	MaxIdleConnections int
	ConnectionLifetime time.Duration
	EnableQueryLogging bool
	AuditLogEnabled    bool
}

// GetSecureDBSource returns a secure database connection string
func GetSecureDBSource(host, port, user, password, dbname string, sslConfig DatabaseSecurityConfig) string {
	// Base connection string
	dsn := fmt.Sprintf("postgresql://%s:%s@%s:%s/%s", user, password, host, port, dbname)

	// Add SSL configuration
	dsn += fmt.Sprintf("?sslmode=%s", sslConfig.SSLMode)

	if sslConfig.SSLCert != "" {
		dsn += fmt.Sprintf("&sslcert=%s", sslConfig.SSLCert)
	}

	if sslConfig.SSLKey != "" {
		dsn += fmt.Sprintf("&sslkey=%s", sslConfig.SSLKey)
	}

	if sslConfig.SSLRootCert != "" {
		dsn += fmt.Sprintf("&sslrootcert=%s", sslConfig.SSLRootCert)
	}

	// Add connection timeout
	dsn += fmt.Sprintf("&connect_timeout=%d", int(sslConfig.ConnectionTimeout.Seconds()))

	return dsn
}

// SetupSecurePool configures database connection pool with security settings
func SetupSecurePool(db *sql.DB, config DatabaseSecurityConfig) {
	// Configure connection pool
	db.SetMaxOpenConns(config.MaxOpenConnections)
	db.SetMaxIdleConns(config.MaxIdleConnections)
	db.SetConnMaxLifetime(config.ConnectionLifetime)

	// Test the connection
	if err := db.Ping(); err != nil {
		logger.Fatal("Database connection failed: %v", err)
	}

	logger.InfoWithFields(logger.Fields{
		"component":           "database",
		"ssl_mode":            config.SSLMode,
		"max_connections":     config.MaxOpenConnections,
		"max_idle":            config.MaxIdleConnections,
		"connection_lifetime": config.ConnectionLifetime,
	}, "Secure database connection pool configured")
}

// DefaultDatabaseSecurityConfig returns default secure database configuration
func DefaultDatabaseSecurityConfig() DatabaseSecurityConfig {
	return DatabaseSecurityConfig{
		SSLMode:            GetEnv("DB_SSL_MODE", "require"),
		SSLCert:            GetEnv("DB_SSL_CERT", ""),
		SSLKey:             GetEnv("DB_SSL_KEY", ""),
		SSLRootCert:        GetEnv("DB_SSL_ROOT_CERT", ""),
		ConnectionTimeout:  time.Duration(GetEnvAsInt("DB_CONNECTION_TIMEOUT", 30)) * time.Second,
		MaxOpenConnections: int(GetEnvAsInt("DB_MAX_OPEN_CONNECTIONS", 25)),
		MaxIdleConnections: int(GetEnvAsInt("DB_MAX_IDLE_CONNECTIONS", 5)),
		ConnectionLifetime: time.Duration(GetEnvAsInt("DB_CONNECTION_LIFETIME", 300)) * time.Second,
		EnableQueryLogging: GetEnv("DB_QUERY_LOGGING", "false") == "true",
		AuditLogEnabled:    GetEnv("DB_AUDIT_LOG_ENABLED", "true") == "true",
	}
}

// AuditEvent represents a database audit event
type AuditEvent struct {
	UserID    int64     `json:"user_id"`
	Action    string    `json:"action"`
	Table     string    `json:"table"`
	RecordID  string    `json:"record_id,omitempty"`
	OldValues string    `json:"old_values,omitempty"`
	NewValues string    `json:"new_values,omitempty"`
	Timestamp time.Time `json:"timestamp"`
	IPAddress string    `json:"ip_address"`
	UserAgent string    `json:"user_agent"`
	Success   bool      `json:"success"`
	ErrorMsg  string    `json:"error_msg,omitempty"`
}

// LogAuditEvent logs database operations for security auditing
func LogAuditEvent(event AuditEvent) {
	logger.InfoWithFields(logger.Fields{
		"component":  "audit",
		"user_id":    event.UserID,
		"action":     event.Action,
		"table":      event.Table,
		"record_id":  event.RecordID,
		"timestamp":  event.Timestamp,
		"ip_address": event.IPAddress,
		"success":    event.Success,
		"error":      event.ErrorMsg,
	}, "Database audit event")
}

// GetTLSConfigFromFiles creates TLS config from certificate files
func GetTLSConfigFromFiles(certFile, keyFile, caFile string) (*tls.Config, error) {
	cert, err := tls.LoadX509KeyPair(certFile, keyFile)
	if err != nil {
		return nil, fmt.Errorf("failed to load key pair: %w", err)
	}

	config := &tls.Config{
		Certificates: []tls.Certificate{cert},
		MinVersion:   tls.VersionTLS12,
	}

	if caFile != "" {
		// Add CA certificate for verification if provided
		// Implementation would go here for custom CA
	}

	return config, nil
}
