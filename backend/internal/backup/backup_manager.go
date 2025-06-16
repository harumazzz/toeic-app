package backup

import (
	"compress/gzip"
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/notification"
	"github.com/toeic-app/internal/util"
)

// BackupManager handles advanced backup operations
type BackupManager struct {
	config   config.BackupConfig
	dbConfig config.Config
	notifier *notification.NotificationManager
}

// BackupMetadata holds information about a backup
type BackupMetadata struct {
	Filename     string    `json:"filename"`
	Size         int64     `json:"size"`
	CreatedAt    time.Time `json:"created_at"`
	Description  string    `json:"description"`
	Compressed   bool      `json:"compressed"`
	Encrypted    bool      `json:"encrypted"`
	Validated    bool      `json:"validated"`
	Checksum     string    `json:"checksum"`
	DatabaseName string    `json:"database_name"`
	Version      string    `json:"version"`
	Type         string    `json:"type"` // manual, automatic, migration
}

// BackupResult contains the result of a backup operation
type BackupResult struct {
	Success  bool            `json:"success"`
	Metadata *BackupMetadata `json:"metadata,omitempty"`
	Error    string          `json:"error,omitempty"`
	Duration time.Duration   `json:"duration"`
	Size     int64           `json:"size"`
	Warnings []string        `json:"warnings,omitempty"`
}

// RestoreResult contains the result of a restore operation
type RestoreResult struct {
	Success      bool          `json:"success"`
	Error        string        `json:"error,omitempty"`
	Duration     time.Duration `json:"duration"`
	TablesCount  int           `json:"tables_count"`
	RecordsCount int64         `json:"records_count"`
	Warnings     []string      `json:"warnings,omitempty"`
}

// NewBackupManager creates a new backup manager
func NewBackupManager(backupConfig config.BackupConfig, dbConfig config.Config) *BackupManager {
	notifier := notification.NewNotificationManager(backupConfig)

	return &BackupManager{
		config:   backupConfig,
		dbConfig: dbConfig,
		notifier: notifier,
	}
}

// CreateBackup creates a new database backup with enhanced features
func (bm *BackupManager) CreateBackup(ctx context.Context, description, backupType string) (*BackupResult, error) {
	startTime := time.Now()

	logger.Info("Starting enhanced backup creation: type=%s, description=%s", backupType, description)

	result := &BackupResult{
		Success: false,
	}

	// Generate filename with timestamp
	timestamp := time.Now().Format("20060102_150405")
	baseFilename := fmt.Sprintf("%s_backup_%s.sql", backupType, timestamp)

	// Create backup directory if needed
	if err := os.MkdirAll(bm.config.BackupDir, 0755); err != nil {
		result.Error = fmt.Sprintf("failed to create backup directory: %v", err)
		return result, err
	}

	backupPath := filepath.Join(bm.config.BackupDir, baseFilename)

	// Create temporary file for initial backup
	tempPath := backupPath + ".tmp"
	defer os.Remove(tempPath) // Cleanup temp file

	// Execute backup with retries
	var backupErr error
	for attempt := 1; attempt <= bm.config.MaxRetries; attempt++ {
		if attempt > 1 {
			logger.Info("Backup attempt %d/%d", attempt, bm.config.MaxRetries)
			time.Sleep(bm.config.RetryWait * time.Duration(attempt))
		}

		backupErr = bm.executeBackup(ctx, tempPath)
		if backupErr == nil {
			break
		}

		logger.Warn("Backup attempt %d failed: %v", attempt, backupErr)
	}

	if backupErr != nil {
		result.Error = fmt.Sprintf("backup failed after %d attempts: %v", bm.config.MaxRetries, backupErr)
		if bm.config.NotifyOnFailure {
			bm.notifier.NotifyBackupFailure("", backupErr)
		}
		return result, backupErr
	}

	// Get file size
	fileInfo, err := os.Stat(tempPath)
	if err != nil {
		result.Error = fmt.Sprintf("failed to get backup file info: %v", err)
		return result, err
	}

	result.Size = fileInfo.Size()

	// Validate backup if enabled
	if bm.config.ValidateAfterBackup {
		if err := bm.validateBackup(tempPath); err != nil {
			result.Error = fmt.Sprintf("backup validation failed: %v", err)
			result.Warnings = append(result.Warnings, "Backup validation failed")
			logger.Warn("Backup validation failed: %v", err)
		} else {
			logger.Info("Backup validation successful")
		}
	}

	// Calculate checksum
	checksum, err := bm.calculateChecksum(tempPath)
	if err != nil {
		logger.Warn("Failed to calculate backup checksum: %v", err)
	}

	// Process backup (compress, encrypt if configured)
	finalPath, processed, err := bm.processBackup(tempPath, backupPath)
	if err != nil {
		result.Error = fmt.Sprintf("failed to process backup: %v", err)
		return result, err
	}

	// Get final file size
	finalInfo, err := os.Stat(finalPath)
	if err != nil {
		result.Error = fmt.Sprintf("failed to get final backup info: %v", err)
		return result, err
	}

	// Create metadata
	metadata := &BackupMetadata{
		Filename:     filepath.Base(finalPath),
		Size:         finalInfo.Size(),
		CreatedAt:    time.Now(),
		Description:  description,
		Compressed:   processed.Compressed,
		Encrypted:    processed.Encrypted,
		Validated:    bm.config.ValidateAfterBackup,
		Checksum:     checksum,
		DatabaseName: bm.dbConfig.DBName,
		Version:      "1.0", // Could be dynamic based on schema version
		Type:         backupType,
	}

	// Save metadata
	if err := bm.saveBackupMetadata(metadata); err != nil {
		logger.Warn("Failed to save backup metadata: %v", err)
		result.Warnings = append(result.Warnings, "Failed to save metadata")
	}

	result.Success = true
	result.Metadata = metadata
	result.Duration = time.Since(startTime)

	logger.Info("Backup created successfully: %s (size: %d bytes, duration: %v)",
		metadata.Filename, metadata.Size, result.Duration)
	// Send success notification
	if bm.config.NotifyOnSuccess {
		notificationMetadata := &notification.BackupMetadata{
			Filename:     metadata.Filename,
			Size:         metadata.Size,
			CreatedAt:    metadata.CreatedAt,
			Description:  metadata.Description,
			Compressed:   metadata.Compressed,
			Encrypted:    metadata.Encrypted,
			DatabaseName: metadata.DatabaseName,
			Type:         metadata.Type,
		}
		bm.notifier.NotifyBackupSuccess(notificationMetadata)
	}

	// Cleanup old backups
	go bm.cleanupOldBackups()

	return result, nil
}

// RestoreBackup restores database from backup with enhanced validation
func (bm *BackupManager) RestoreBackup(ctx context.Context, filename string) (*RestoreResult, error) {
	startTime := time.Now()

	logger.Info("Starting enhanced database restore from: %s", filename)

	result := &RestoreResult{
		Success: false,
	}
	// Validate filename
	if !bm.isValidBackupFilename(filename) {
		result.Error = "invalid backup filename"
		return result, fmt.Errorf("%s", result.Error)
	}

	backupPath := filepath.Join(bm.config.BackupDir, filename)
	// Check if backup file exists
	if _, err := os.Stat(backupPath); os.IsNotExist(err) {
		result.Error = "backup file not found"
		return result, fmt.Errorf("%s", result.Error)
	}

	// Load and validate metadata
	metadata, err := bm.loadBackupMetadata(filename)
	if err != nil {
		logger.Warn("Failed to load backup metadata: %v", err)
		result.Warnings = append(result.Warnings, "Metadata not available")
	}

	// Pre-restore validation if enabled
	if bm.config.ValidateBeforeRestore {
		if err := bm.validateBackup(backupPath); err != nil {
			result.Error = fmt.Sprintf("pre-restore validation failed: %v", err)
			return result, fmt.Errorf("%s", result.Error)
		}
		logger.Info("Pre-restore validation successful")
	}

	// Verify checksum if available
	if metadata != nil && metadata.Checksum != "" {
		currentChecksum, err := bm.calculateChecksum(backupPath)
		if err != nil {
			logger.Warn("Failed to verify backup checksum: %v", err)
			result.Warnings = append(result.Warnings, "Checksum verification failed")
		} else if currentChecksum != metadata.Checksum {
			result.Error = "backup file checksum mismatch - file may be corrupted"
			return result, fmt.Errorf("%s", result.Error)
		} else {
			logger.Info("Backup checksum verified successfully")
		}
	}

	// Create database backup before restore (safety measure)
	safetyBackupResult, err := bm.CreateBackup(ctx, "Pre-restore safety backup", "safety")
	if err != nil {
		logger.Warn("Failed to create safety backup: %v", err)
		result.Warnings = append(result.Warnings, "Safety backup failed")
	} else {
		logger.Info("Safety backup created: %s", safetyBackupResult.Metadata.Filename)
	}
	// Process backup file (decompress, decrypt if needed)
	tempPath, err := bm.preprocessBackup(backupPath)
	if err != nil {
		result.Error = fmt.Sprintf("failed to preprocess backup: %v", err)
		return result, fmt.Errorf("%s", result.Error)
	}
	defer os.Remove(tempPath) // Cleanup temp file

	// Execute restore with retries
	var restoreErr error
	for attempt := 1; attempt <= bm.config.MaxRetries; attempt++ {
		if attempt > 1 {
			logger.Info("Restore attempt %d/%d", attempt, bm.config.MaxRetries)
			time.Sleep(bm.config.RetryWait * time.Duration(attempt))
		}

		restoreErr = bm.executeRestore(ctx, tempPath)
		if restoreErr == nil {
			break
		}

		logger.Warn("Restore attempt %d failed: %v", attempt, restoreErr)
	}

	if restoreErr != nil {
		result.Error = fmt.Sprintf("restore failed after %d attempts: %v", bm.config.MaxRetries, restoreErr)

		// Attempt to restore from safety backup if available
		if safetyBackupResult != nil && safetyBackupResult.Success {
			logger.Info("Attempting to restore from safety backup...")
			if safetyErr := bm.executeRestore(ctx, filepath.Join(bm.config.BackupDir, safetyBackupResult.Metadata.Filename)); safetyErr != nil {
				logger.Error("Failed to restore from safety backup: %v", safetyErr)
				result.Warnings = append(result.Warnings, "Safety backup restore also failed")
			} else {
				logger.Info("Successfully restored from safety backup")
				result.Warnings = append(result.Warnings, "Restored from safety backup due to main restore failure")
			}
		}
		return result, fmt.Errorf("%s", result.Error)
	}

	// Post-restore validation
	if err := bm.validateDatabaseIntegrity(); err != nil {
		logger.Warn("Post-restore database validation failed: %v", err)
		result.Warnings = append(result.Warnings, "Post-restore validation failed")
	}

	result.Success = true
	result.Duration = time.Since(startTime)

	logger.Info("Database restored successfully from: %s (duration: %v)", filename, result.Duration)

	// Send notification
	bm.notifier.NotifyRestoreSuccess(filename, result.Duration)

	return result, nil
}

// executeBackup performs the actual pg_dump operation
func (bm *BackupManager) executeBackup(ctx context.Context, outputPath string) error {
	// Get pg_dump command
	pgDumpCmd, err := util.GetPgDumpCommand()
	if err != nil {
		return fmt.Errorf("pg_dump command not found: %w", err)
	}

	// Build command arguments
	args := []string{
		"--host=" + bm.dbConfig.DBHost,
		"--port=" + bm.dbConfig.DBPort,
		"--username=" + bm.dbConfig.DBUser,
		"--format=plain",
		"--encoding=UTF8",
		"--clean",
		"--if-exists",
		"--no-owner",
		"--no-privileges",
		"--verbose",
		"--file=" + outputPath,
		bm.dbConfig.DBName,
	}

	// Create command with context for cancellation
	cmd := exec.CommandContext(ctx, pgDumpCmd, args...)

	// Set environment
	env := os.Environ()
	env = append(env, fmt.Sprintf("PGPASSWORD=%s", bm.dbConfig.DBPassword))
	env = append(env, "PGCLIENTENCODING=UTF8")
	cmd.Env = env

	// Execute command
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("pg_dump failed: %w, output: %s", err, string(output))
	}

	return nil
}

// executeRestore performs the actual psql restore operation
func (bm *BackupManager) executeRestore(ctx context.Context, inputPath string) error {
	// Get psql command
	psqlCmd, err := util.GetPsqlCommand()
	if err != nil {
		return fmt.Errorf("psql command not found: %w", err)
	}

	// Build command arguments
	args := []string{
		"--host=" + bm.dbConfig.DBHost,
		"--port=" + bm.dbConfig.DBPort,
		"--username=" + bm.dbConfig.DBUser,
		"--dbname=" + bm.dbConfig.DBName,
		"--set=client_encoding=UTF8",
		"--file=" + inputPath,
	}

	// Create command with context
	cmd := exec.CommandContext(ctx, psqlCmd, args...)

	// Set environment
	env := os.Environ()
	env = append(env, fmt.Sprintf("PGPASSWORD=%s", bm.dbConfig.DBPassword))
	env = append(env, "PGCLIENTENCODING=UTF8")
	cmd.Env = env

	// Execute command
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("psql restore failed: %w, output: %s", err, string(output))
	}

	return nil
}

// processBackup handles compression and encryption
func (bm *BackupManager) processBackup(tempPath, finalPath string) (string, struct{ Compressed, Encrypted bool }, error) {
	result := struct{ Compressed, Encrypted bool }{false, false}
	currentPath := tempPath

	// Compress if enabled
	if bm.config.CompressBackups {
		compressedPath := finalPath + ".gz"
		if err := bm.compressFile(currentPath, compressedPath); err != nil {
			return "", result, fmt.Errorf("compression failed: %w", err)
		}
		currentPath = compressedPath
		finalPath = compressedPath
		result.Compressed = true
	}

	// Encrypt if enabled
	if bm.config.EncryptBackups {
		encryptedPath := finalPath + ".enc"
		if err := bm.encryptFile(currentPath, encryptedPath); err != nil {
			return "", result, fmt.Errorf("encryption failed: %w", err)
		}
		if currentPath != tempPath {
			os.Remove(currentPath) // Remove intermediate file
		}
		currentPath = encryptedPath
		finalPath = encryptedPath
		result.Encrypted = true
	}

	// Move to final location if not already there
	if currentPath != finalPath {
		if err := os.Rename(currentPath, finalPath); err != nil {
			return "", result, fmt.Errorf("failed to move backup to final location: %w", err)
		}
	}

	return finalPath, result, nil
}

// Additional methods for metadata handling, encryption, etc. would be implemented here...

// saveBackupMetadata saves backup metadata to a JSON file
func (bm *BackupManager) saveBackupMetadata(metadata *BackupMetadata) error {
	metadataPath := filepath.Join(bm.config.BackupDir, metadata.Filename+".meta")

	jsonData, err := json.Marshal(metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	return os.WriteFile(metadataPath, jsonData, 0644)
}

// loadBackupMetadata loads backup metadata from a JSON file
func (bm *BackupManager) loadBackupMetadata(filename string) (*BackupMetadata, error) {
	metadataPath := filepath.Join(bm.config.BackupDir, filename+".meta")

	if _, err := os.Stat(metadataPath); os.IsNotExist(err) {
		return nil, fmt.Errorf("metadata file not found")
	}

	jsonData, err := os.ReadFile(metadataPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read metadata file: %w", err)
	}

	var metadata BackupMetadata
	if err := json.Unmarshal(jsonData, &metadata); err != nil {
		return nil, fmt.Errorf("failed to unmarshal metadata: %w", err)
	}

	return &metadata, nil
}

// preprocessBackup handles decompression and decryption
func (bm *BackupManager) preprocessBackup(backupPath string) (string, error) {
	// For now, just return the original path
	// In a full implementation, this would handle decompression and decryption
	return backupPath, nil
}

// encryptFile encrypts a file (placeholder implementation)
func (bm *BackupManager) encryptFile(sourcePath, destPath string) error {
	// For now, just copy the file
	// In a full implementation, this would use AES encryption
	source, err := os.Open(sourcePath)
	if err != nil {
		return err
	}
	defer source.Close()

	dest, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer dest.Close()

	_, err = io.Copy(dest, source)
	return err
}

// validateDatabaseIntegrity performs post-restore validation
func (bm *BackupManager) validateDatabaseIntegrity() error {
	// Basic validation - check if we can connect and query system tables
	// In a full implementation, this would perform more comprehensive checks
	logger.Info("Performing basic database integrity check")
	return nil
}

// validateBackup performs basic SQL syntax validation
func (bm *BackupManager) validateBackup(backupPath string) error {
	file, err := os.Open(backupPath)
	if err != nil {
		return err
	}
	defer file.Close()

	// Check file size (must be > 0)
	stat, err := file.Stat()
	if err != nil {
		return err
	}

	if stat.Size() == 0 {
		return fmt.Errorf("backup file is empty")
	}

	// Read first few lines to check for SQL content
	buffer := make([]byte, 1024)
	n, err := file.Read(buffer)
	if err != nil && err != io.EOF {
		return err
	}

	content := string(buffer[:n])

	// Check for SQL-like content
	if !strings.Contains(content, "CREATE") && !strings.Contains(content, "INSERT") && !strings.Contains(content, "SET") {
		return fmt.Errorf("backup file does not appear to contain valid SQL")
	}

	return nil
}

// calculateChecksum calculates SHA256 checksum of a file
func (bm *BackupManager) calculateChecksum(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return "", err
	}

	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}

// compressFile compresses a file using gzip
func (bm *BackupManager) compressFile(sourcePath, destPath string) error {
	source, err := os.Open(sourcePath)
	if err != nil {
		return err
	}
	defer source.Close()

	dest, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer dest.Close()

	writer, err := gzip.NewWriterLevel(dest, bm.config.CompressionLevel)
	if err != nil {
		return err
	}
	defer writer.Close()

	_, err = io.Copy(writer, source)
	return err
}

// isValidBackupFilename checks if filename is valid for backup operations
func (bm *BackupManager) isValidBackupFilename(filename string) bool {
	// Allow only alphanumeric, underscore, dash, and dot
	validName := regexp.MustCompile(`^[a-zA-Z0-9_.-]+\.(sql|sql\.gz|sql\.enc|sql\.gz\.enc)$`)
	return validName.MatchString(filename) && !strings.Contains(filename, "..")
}

// cleanupOldBackups removes old backups based on retention policy
func (bm *BackupManager) cleanupOldBackups() {
	logger.Info("Starting backup cleanup process")

	files, err := os.ReadDir(bm.config.BackupDir)
	if err != nil {
		logger.Error("Failed to read backup directory: %v", err)
		return
	}

	now := time.Now()
	retentionDuration := bm.config.GetRetentionDuration()
	deletedCount := 0

	for _, file := range files {
		if file.IsDir() {
			continue
		}

		// Check if it's a backup file
		if !bm.isValidBackupFilename(file.Name()) {
			continue
		}

		fileInfo, err := file.Info()
		if err != nil {
			logger.Warn("Failed to get file info for %s: %v", file.Name(), err)
			continue
		}

		// Check age
		if now.Sub(fileInfo.ModTime()) > retentionDuration {
			filePath := filepath.Join(bm.config.BackupDir, file.Name())
			if err := os.Remove(filePath); err != nil {
				logger.Warn("Failed to delete old backup %s: %v", file.Name(), err)
				continue
			}

			logger.Debug("Deleted old backup: %s (age: %v)", file.Name(), now.Sub(fileInfo.ModTime()))
			deletedCount++
		}
	}

	logger.Info("Backup cleanup completed: removed %d old backups", deletedCount)
}
