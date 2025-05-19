package api

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/util"
)

// backupRequest holds the data needed to perform a backup
type backupRequest struct {
	Filename    string `json:"filename" form:"filename"`
	Description string `json:"description" form:"description"`
}

// backupResponse is the structure returned on successful backup
type backupResponse struct {
	Filename    string    `json:"filename"`
	Description string    `json:"description"`
	Size        int64     `json:"size"`
	CreatedAt   time.Time `json:"created_at"`
	DownloadURL string    `json:"download_url"`
}

// backupListResponse is a single backup file info for listing
type backupListItem struct {
	Filename    string    `json:"filename"`
	Description string    `json:"description"`
	Size        int64     `json:"size"`
	CreatedAt   time.Time `json:"created_at"`
	DownloadURL string    `json:"download_url"`
}

// backupJob represents a database backup or restore job
type backupJob struct {
	ID          string    `json:"id"`
	Type        string    `json:"type"` // "backup" or "restore"
	Status      string    `json:"status"`
	Filename    string    `json:"filename"`
	Description string    `json:"description"`
	StartedAt   time.Time `json:"started_at"`
	FinishedAt  time.Time `json:"finished_at,omitempty"`
	Error       string    `json:"error,omitempty"`
}

// ensureBackupDir creates the backup directory if it doesn't exist
func ensureBackupDir(backupDir string) error {
	if _, err := os.Stat(backupDir); os.IsNotExist(err) {
		return os.MkdirAll(backupDir, 0755)
	}
	return nil
}

// createBackupWithTransaction creates a backup with proper transaction handling
func (server *Server) createBackupWithTransaction(filename, description string) (*backupResponse, error) {
	logger.Info("Starting database backup transaction: filename=%s", filename)

	// Generate a unique backup ID
	backupID := time.Now().Format("20060102_150405")
	if filename == "" {
		filename = fmt.Sprintf("toeic_backup_%s.sql", backupID)
		logger.Debug("Using generated filename: %s", filename)
	} else if filepath.Ext(filename) != ".sql" {
		filename += ".sql"
		logger.Debug("Added .sql extension to filename: %s", filename)
	}
	// Ensure the backup directory exists
	backupDir := filepath.Join(".", "backups")
	logger.Debug("Using backup directory: %s", backupDir)
	if dirErr := ensureBackupDir(backupDir); dirErr != nil {
		logger.Error("Failed to create backup directory: %v", dirErr)
		return nil, fmt.Errorf("failed to create backup directory: %w", dirErr)
	}

	// Full path for the backup file
	backupPath := filepath.Join(backupDir, filename)
	logger.Debug("Full backup path: %s", backupPath)

	// Extract database configuration
	dbUser := server.config.DBUser
	dbPassword := server.config.DBPassword
	dbHost := server.config.DBHost
	dbPort := server.config.DBPort
	dbName := server.config.DBName
	logger.Debug("Using database: host=%s, port=%s, name=%s, user=%s", dbHost, dbPort, dbName, dbUser)
	// Set environment variable for PostgreSQL password
	env := os.Environ()
	env = append(env, fmt.Sprintf("PGPASSWORD=%s", dbPassword))

	// Get pg_dump command with appropriate path
	pgDumpCmd, cmdErr := util.GetPgDumpCommand()
	if cmdErr != nil {
		logger.Error("Failed to find pg_dump command: %v", cmdErr)
		return nil, fmt.Errorf("pg_dump command not found: %w", cmdErr)
	}
	logger.Debug("Using pg_dump command: %s", pgDumpCmd)

	// Create pg_dump command
	cmd := exec.Command(
		pgDumpCmd,
		"--host="+dbHost,
		"--port="+dbPort,
		"--username="+dbUser,
		"--format=plain",
		"--clean",
		"--if-exists",
		"--no-owner",
		"--no-privileges",
		"--file="+backupPath,
		dbName,
	)

	// Set environment variables
	cmd.Env = env
	// Create buffers to capture command output
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	// Execute pg_dump with retry logic
	logger.Info("Creating database backup: %s", backupPath)

	// Retry configuration
	maxRetries := 3
	initialWait := 500 * time.Millisecond
	maxWait := 5 * time.Second
	factor := 2.0

	var err error
	wait := initialWait

	// Try up to maxRetries times
	for attempt := 1; attempt <= maxRetries; attempt++ {
		// Clear the stderr buffer for each attempt
		stderr.Reset()

		if attempt > 1 {
			logger.Info("Backup attempt %d of %d after waiting %v", attempt, maxRetries, wait)
		}

		err = cmd.Run()
		if err == nil {
			// Success!
			if attempt > 1 {
				logger.Info("Backup succeeded on attempt %d", attempt)
			}
			break
		} else {
			errMsg := stderr.String()
			logger.Error("Backup attempt %d failed: %v, stderr: %s", attempt, err, errMsg)

			// If this was the last attempt, return the error
			if attempt == maxRetries {
				return nil, fmt.Errorf("failed to create database backup after %d attempts: %w", maxRetries, err)
			}

			// Wait before the next attempt
			time.Sleep(wait)

			// Increase wait time for next attempt, up to maxWait
			nextWait := time.Duration(float64(wait) * factor)
			if nextWait > maxWait {
				wait = maxWait
			} else {
				wait = nextWait
			}
		}
	}

	// Check for errors again after all retries
	if err != nil {
		return nil, fmt.Errorf("failed to create database backup: %w", err)
	}

	// Get file info
	fileInfo, err := os.Stat(backupPath)
	if err != nil {
		logger.Error("Failed to get backup file info: %v", err)
		return nil, fmt.Errorf("failed to get backup file info: %w", err)
	}

	// Create response
	response := &backupResponse{
		Filename:    filename,
		Description: description,
		Size:        fileInfo.Size(),
		CreatedAt:   time.Now(),
		DownloadURL: fmt.Sprintf("/api/v1/admin/backups/download/%s", filename),
	}

	return response, nil
}

// @Summary     Create database backup
// @Description Creates a backup of the PostgreSQL database
// @Tags        admin
// @Accept      json
// @Produce     json
// @Param       backup body backupRequest true "Backup details"
// @Success     200 {object} Response{data=backupResponse} "Backup created successfully"
// @Failure     400 {object} Response "Invalid request parameters"
// @Failure     500 {object} Response "Failed to create backup"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups [post]
func (server *Server) createBackup(ctx *gin.Context) {
	// Parse request
	var req backupRequest
	if err := ctx.ShouldBind(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	// Use our transaction-based backup function
	response, err := server.createBackupWithTransaction(req.Filename, req.Description)
	if err != nil {
		logger.Error("Backup creation failed: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create database backup", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Database backup created successfully", response)
}

// @Summary     List database backups
// @Description Lists all available database backups
// @Tags        admin
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=[]backupListItem} "Backups retrieved successfully"
// @Failure     500 {object} Response "Failed to retrieve backups"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups [get]
func (server *Server) listBackups(ctx *gin.Context) {
	// Ensure the backup directory exists
	backupDir := filepath.Join(".", "backups")
	if err := ensureBackupDir(backupDir); err != nil {
		logger.Error("Failed to create backup directory: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to access backup directory", err)
		return
	}

	// Read directory contents
	files, err := os.ReadDir(backupDir)
	if err != nil {
		logger.Error("Failed to read backup directory: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to read backup directory", err)
		return
	}

	// Create response list
	backups := make([]backupListItem, 0)
	for _, file := range files {
		// Skip directories and non-SQL files
		if file.IsDir() || filepath.Ext(file.Name()) != ".sql" {
			continue
		}

		fileInfo, err := file.Info()
		if err != nil {
			logger.Warn("Failed to get info for backup file %s: %v", file.Name(), err)
			continue
		}

		backups = append(backups, backupListItem{
			Filename:    file.Name(),
			Description: "", // We would need to store this separately or in file metadata
			Size:        fileInfo.Size(),
			CreatedAt:   fileInfo.ModTime(),
			DownloadURL: fmt.Sprintf("/api/v1/admin/backups/download/%s", file.Name()),
		})
	}

	SuccessResponse(ctx, http.StatusOK, "Database backups retrieved successfully", backups)
}

// @Summary     Download database backup
// @Description Downloads a specific database backup file
// @Tags        admin
// @Produce     application/octet-stream
// @Param       filename path string true "Backup filename"
// @Success     200 {file} binary "Backup file content"
// @Failure     400 {object} Response "Invalid filename"
// @Failure     404 {object} Response "Backup file not found"
// @Failure     500 {object} Response "Failed to serve backup file"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/download/{filename} [get]
func (server *Server) downloadBackup(ctx *gin.Context) {
	filename := ctx.Param("filename")
	if filename == "" {
		logger.Warn("Download attempt with empty filename")
		ErrorResponse(ctx, http.StatusBadRequest, "Filename is required", nil)
		return
	}

	logger.Info("Download backup request for file: %s", filename)

	// Validate and sanitize the filename
	validFilename, err := util.ValidateBackupFilename(filename)
	if err != nil {
		logger.Warn("Invalid backup filename: %s - %v", filename, err)
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid backup filename", err)
		return
	}
	logger.Debug("Validated filename: %s", validFilename)

	// Path to backup file
	backupPath := filepath.Join(".", "backups", validFilename)
	logger.Debug("Looking for backup at path: %s", backupPath)

	// Check if file exists
	fileInfo, err := os.Stat(backupPath)
	if os.IsNotExist(err) {
		logger.Warn("Backup file not found: %s", backupPath)
		ErrorResponse(ctx, http.StatusNotFound, "Backup file not found", nil)
		return
	} else if err != nil {
		logger.Error("Error checking backup file: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Error accessing backup file", err)
		return
	}

	logger.Info("Serving backup file: %s (size: %d bytes)", validFilename, fileInfo.Size())
	// Serve the file
	ctx.FileAttachment(backupPath, filename)
}

// @Summary     Delete database backup
// @Description Deletes a specific database backup file
// @Tags        admin
// @Accept      json
// @Produce     json
// @Param       filename path string true "Backup filename"
// @Success     200 {object} Response "Backup deleted successfully"
// @Failure     400 {object} Response "Invalid filename"
// @Failure     404 {object} Response "Backup file not found"
// @Failure     500 {object} Response "Failed to delete backup file"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/{filename} [delete]
func (server *Server) deleteBackup(ctx *gin.Context) {
	filename := ctx.Param("filename")
	if filename == "" {
		logger.Warn("Delete attempt with empty filename")
		ErrorResponse(ctx, http.StatusBadRequest, "Filename is required", nil)
		return
	}

	logger.Info("Delete backup request for file: %s", filename)

	// Validate and sanitize the filename
	validFilename, err := util.ValidateBackupFilename(filename)
	if err != nil {
		logger.Warn("Invalid backup filename for deletion: %s - %v", filename, err)
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid backup filename", err)
		return
	}
	logger.Debug("Validated filename for deletion: %s", validFilename)

	// Path to backup file
	backupPath := filepath.Join(".", "backups", validFilename)
	logger.Debug("Backup file to delete: %s", backupPath)

	// Check if file exists
	fileInfo, err := os.Stat(backupPath)
	if os.IsNotExist(err) {
		logger.Warn("Backup file not found for deletion: %s", backupPath)
		ErrorResponse(ctx, http.StatusNotFound, "Backup file not found", nil)
		return
	} else if err != nil {
		logger.Error("Error checking backup file for deletion: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Error accessing backup file", err)
		return
	}

	logger.Info("Deleting backup file: %s (size: %d bytes, modified: %s)",
		validFilename, fileInfo.Size(), fileInfo.ModTime().Format(time.RFC3339))

	// Delete the file
	if err := os.Remove(backupPath); err != nil {
		logger.Error("Failed to delete backup file: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete backup file", err)
		return
	}

	logger.Info("Backup file successfully deleted: %s", validFilename)
	SuccessResponse(ctx, http.StatusOK, "Backup deleted successfully", nil)
}

// restoreRequest holds the data needed to restore a database
type restoreRequest struct {
	Filename string `json:"filename" binding:"required"`
}

// @Summary     Restore database from backup
// @Description Restores the database from a specified backup file
// @Tags        admin
// @Accept      json
// @Produce     json
// @Param       restore body restoreRequest true "Restore details"
// @Success     200 {object} Response "Database restored successfully"
// @Failure     400 {object} Response "Invalid request parameters"
// @Failure     404 {object} Response "Backup file not found"
// @Failure     500 {object} Response "Failed to restore database"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/restore [post]
func (server *Server) restoreBackup(ctx *gin.Context) {
	// Parse request
	var req restoreRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		logger.Warn("Invalid restore request format: %v", err)
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	logger.Info("Database restore request for file: %s", req.Filename)

	// Validate and sanitize the filename
	validFilename, err := util.ValidateBackupFilename(req.Filename)
	if err != nil {
		logger.Warn("Invalid backup filename for restore: %s - %v", req.Filename, err)
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid backup filename", err)
		return
	}
	logger.Debug("Validated filename for restore: %s", validFilename)

	// Path to backup file
	backupPath := filepath.Join(".", "backups", validFilename)
	logger.Debug("Looking for backup at path: %s", backupPath)

	// Check if file exists and get size
	fileInfo, err := os.Stat(backupPath)
	if os.IsNotExist(err) {
		logger.Warn("Backup file not found for restore: %s", backupPath)
		ErrorResponse(ctx, http.StatusNotFound, "Backup file not found", nil)
		return
	} else if err != nil {
		logger.Error("Error checking backup file for restore: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Error accessing backup file", err)
		return
	}

	logger.Info("Preparing to restore database from file: %s (size: %d bytes, modified: %s)",
		validFilename, fileInfo.Size(), fileInfo.ModTime().Format(time.RFC3339))
	// Extract database configuration
	dbUser := server.config.DBUser
	dbPassword := server.config.DBPassword
	dbHost := server.config.DBHost
	dbPort := server.config.DBPort
	dbName := server.config.DBName
	logger.Debug("Database restore target: host=%s, port=%s, name=%s, user=%s",
		dbHost, dbPort, dbName, dbUser)

	// Set environment variable for PostgreSQL password
	env := os.Environ()
	env = append(env, fmt.Sprintf("PGPASSWORD=%s", dbPassword))

	// Get psql command with appropriate path
	psqlCmd, cmdErr := util.GetPsqlCommand()
	if cmdErr != nil {
		logger.Error("Failed to find psql command: %v", cmdErr)
		ErrorResponse(ctx, http.StatusInternalServerError, "psql command not found", cmdErr)
		return
	}
	logger.Debug("Using psql command: %s", psqlCmd)

	// Create psql command to restore from the backup
	cmd := exec.Command(
		psqlCmd,
		"--host="+dbHost,
		"--port="+dbPort,
		"--username="+dbUser,
		"--dbname="+dbName,
		"--file="+backupPath,
	)

	// Set environment variables
	cmd.Env = env
	// Create buffers to capture command output
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr // Execute psql with retry logic
	logger.Info("Restoring database from backup: %s", backupPath)

	// Retry configuration
	maxRetries := 3
	initialWait := 1 * time.Second
	maxWait := 10 * time.Second
	factor := 2.0

	wait := initialWait
	var restoreError error

	// Try up to maxRetries times
	for attempt := 1; attempt <= maxRetries; attempt++ {
		// Clear the buffers for each attempt
		stdout.Reset()
		stderr.Reset()

		if attempt > 1 {
			logger.Info("Database restore attempt %d of %d after waiting %v", attempt, maxRetries, wait)
		}

		restoreError = cmd.Run()
		if restoreError == nil {
			// Success!
			if attempt > 1 {
				logger.Info("Database restore succeeded on attempt %d", attempt)
			}
			break
		} else {
			errMsg := stderr.String()
			logger.Error("Restore attempt %d failed: %v, stderr: %s", attempt, restoreError, errMsg)

			// If this was the last attempt, return the error
			if attempt == maxRetries {
				ErrorResponse(ctx, http.StatusInternalServerError,
					fmt.Sprintf("Failed to restore database after %d attempts", maxRetries), restoreError)
				return
			}

			// Wait before the next attempt
			time.Sleep(wait)

			// Increase wait time for next attempt, up to maxWait
			nextWait := time.Duration(float64(wait) * factor)
			if nextWait > maxWait {
				wait = maxWait
			} else {
				wait = nextWait
			}
		}
	}

	// Check for errors again after all retries
	if restoreError != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to restore database", restoreError)
		return
	}

	logger.Info("Database restored successfully from: %s, output: %s", backupPath, stdout.String())
	SuccessResponse(ctx, http.StatusOK, "Database restored successfully", nil)
}

// @Summary     Upload database backup
// @Description Uploads a backup file to the server
// @Tags        admin
// @Accept      multipart/form-data
// @Produce     json
// @Param       file formData file true "Backup SQL file"
// @Param       description formData string false "Backup description"
// @Success     200 {object} Response{data=backupResponse} "Backup uploaded successfully"
// @Failure     400 {object} Response "Invalid file or description"
// @Failure     500 {object} Response "Failed to save backup file"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/upload [post]
func (server *Server) uploadBackup(ctx *gin.Context) {
	// Get file from form data
	file, header, err := ctx.Request.FormFile("file")
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "No backup file found in request", err)
		return
	}
	defer file.Close()

	// Validate file extension
	if filepath.Ext(header.Filename) != ".sql" {
		ErrorResponse(ctx, http.StatusBadRequest, "Only .sql files are allowed", nil)
		return
	}

	// Get description from form data
	description := ctx.PostForm("description")

	// Ensure the backup directory exists
	backupDir := filepath.Join(".", "backups")
	if err := ensureBackupDir(backupDir); err != nil {
		logger.Error("Failed to create backup directory: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create backup directory", err)
		return
	}

	// Create destination file
	filename := header.Filename
	destPath := filepath.Join(backupDir, filename)

	// Check if file already exists and append timestamp if needed
	if _, err := os.Stat(destPath); err == nil {
		filename = fmt.Sprintf("%s_%s%s",
			strings.TrimSuffix(header.Filename, filepath.Ext(header.Filename)),
			time.Now().Format("20060102_150405"),
			filepath.Ext(header.Filename))
		destPath = filepath.Join(backupDir, filename)
	}

	dest, err := os.Create(destPath)
	if err != nil {
		logger.Error("Failed to create destination file: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to save backup file", err)
		return
	}
	defer dest.Close()

	// Copy file contents
	_, err = io.Copy(dest, file)
	if err != nil {
		logger.Error("Failed to copy file contents: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to save backup file", err)
		return
	}

	// Get file info
	fileInfo, err := os.Stat(destPath)
	if err != nil {
		logger.Error("Failed to get backup file info: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get backup file info", err)
		return
	}

	// Create response
	response := backupResponse{
		Filename:    filename,
		Description: description,
		Size:        fileInfo.Size(),
		CreatedAt:   time.Now(),
		DownloadURL: fmt.Sprintf("/api/v1/admin/backups/download/%s", filename),
	}

	SuccessResponse(ctx, http.StatusOK, "Backup file uploaded successfully", response)
}
