package util

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"time"

	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
)

// CheckDatabaseConnection tests if the database is accessible
func CheckDatabaseConnection(cfg config.Config) error {
	// Create connection string
	dbSource := config.GetDBSource(cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName)

	// Open connection to database
	db, err := sql.Open(cfg.DBDriver, dbSource)
	if err != nil {
		return fmt.Errorf("failed to open database connection: %w", err)
	}
	defer db.Close()

	// Set connection pool parameters
	config.SetupPool(db)

	// Test connection with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Ping database
	err = db.PingContext(ctx)
	if err != nil {
		return fmt.Errorf("failed to ping database: %w", err)
	}

	return nil
}

// FindPostgreSQLBinPath attempts to locate the PostgreSQL bin directory
func FindPostgreSQLBinPath() (string, error) {
	logger.Info("Looking for PostgreSQL bin directory")

	// First try to find pg_dump in PATH
	path, err := exec.LookPath("pg_dump")
	if err == nil {
		binDir := filepath.Dir(path)
		logger.Info("Found PostgreSQL bin directory in PATH: %s", binDir)
		return binDir, nil
	}

	// On Windows, check common installation locations
	if runtime.GOOS == "windows" {
		// Check Program Files
		pgDirs := []string{
			"C:\\Program Files\\PostgreSQL",
			"C:\\Program Files (x86)\\PostgreSQL",
		}

		for _, pgDir := range pgDirs {
			exists, err := os.Stat(pgDir)
			if err == nil && exists.IsDir() {
				// Look for version subdirectories
				items, err := os.ReadDir(pgDir)
				if err != nil {
					continue
				}

				// Check each version directory
				for _, item := range items {
					if item.IsDir() {
						binPath := filepath.Join(pgDir, item.Name(), "bin")
						pgDumpPath := filepath.Join(binPath, "pg_dump.exe")

						if _, err := os.Stat(pgDumpPath); err == nil {
							logger.Info("Found PostgreSQL bin directory at: %s", binPath)
							return binPath, nil
						}
					}
				}
			}
		}
	}

	return "", fmt.Errorf("PostgreSQL bin directory not found")
}

// GetPgDumpCommand returns the command to run pg_dump with the appropriate path
func GetPgDumpCommand() (string, error) {
	// First check if pg_dump is directly in PATH
	_, err := exec.LookPath("pg_dump")
	if err == nil {
		return "pg_dump", nil
	}

	// If not in PATH, try to find the bin directory
	binDir, err := FindPostgreSQLBinPath()
	if err != nil {
		return "", err
	}

	return filepath.Join(binDir, "pg_dump"), nil
}

// GetPsqlCommand returns the command to run psql with the appropriate path
func GetPsqlCommand() (string, error) {
	// First check if psql is directly in PATH
	_, err := exec.LookPath("psql")
	if err == nil {
		return "psql", nil
	}

	// If not in PATH, try to find the bin directory
	binDir, err := FindPostgreSQLBinPath()
	if err != nil {
		return "", err
	}

	return filepath.Join(binDir, "psql"), nil
}

// CheckPgDumpAvailable checks if pg_dump command is available
func CheckPgDumpAvailable() error {
	pgDumpCmd, err := GetPgDumpCommand()
	if err != nil {
		return fmt.Errorf("pg_dump command not found: %w", err)
	}

	cmd := exec.Command(pgDumpCmd, "--version")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("pg_dump command not working: %w", err)
	}

	logger.Info("pg_dump command available: %s", pgDumpCmd)
	return nil
}

// CheckPsqlAvailable checks if psql command is available
func CheckPsqlAvailable() error {
	psqlCmd, err := GetPsqlCommand()
	if err != nil {
		return fmt.Errorf("psql command not found: %w", err)
	}

	cmd := exec.Command(psqlCmd, "--version")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("psql command not working: %w", err)
	}

	logger.Info("psql command available: %s", psqlCmd)
	return nil
}

// CheckDatabaseTools checks if both pg_dump and psql are available
func CheckDatabaseTools() error {
	// Check if pg_dump is available
	if err := CheckPgDumpAvailable(); err != nil {
		logger.Error("pg_dump not available: %v", err)
		return err
	}

	// Check if psql is available
	if err := CheckPsqlAvailable(); err != nil {
		logger.Error("psql not available: %v", err)
		return err
	}

	logger.Info("Database tools (pg_dump, psql) are available")
	return nil
}

// ValidateBackupFilename checks if a filename is valid for backup files
// This helps prevent path traversal attacks and ensures consistent naming
func ValidateBackupFilename(filename string) (string, error) {
	// Clean the filename to prevent path traversal
	clean := filepath.Base(filename)

	// Validate extension
	if filepath.Ext(clean) != ".sql" {
		return "", fmt.Errorf("invalid backup file extension, only .sql is allowed")
	}

	// Additional validations (optional)
	// For example, enforcing certain naming patterns

	return clean, nil
}
