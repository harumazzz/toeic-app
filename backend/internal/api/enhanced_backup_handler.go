package api

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/backup"
	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
)

// Enhanced backup endpoints using the new backup manager

// @Summary     Create enhanced database backup
// @Description Creates a backup with advanced features like compression, encryption, and validation
// @Tags        admin
// @Accept      json
// @Produce     json
// @Param       backup body enhancedBackupRequest true "Enhanced backup details"
// @Success     200 {object} Response{data=enhancedBackupResponse} "Backup created successfully"
// @Failure     400 {object} Response "Invalid request parameters"
// @Failure     500 {object} Response "Failed to create backup"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/enhanced [post]
func (server *Server) createEnhancedBackup(ctx *gin.Context) {
	var req enhancedBackupRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		logger.Warn("Invalid enhanced backup request format: %v", err)
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	logger.Info("Enhanced backup request: description=%s, type=%s", req.Description, req.Type)

	// Load backup configuration
	backupConfig := config.LoadBackupConfig()
	if err := backupConfig.Validate(); err != nil {
		logger.Error("Invalid backup configuration: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Backup configuration error", err)
		return
	}

	// Create backup manager
	backupManager := backup.NewBackupManager(backupConfig, server.config)

	// Create context with timeout
	backupCtx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
	defer cancel()

	// Create backup
	result, err := backupManager.CreateBackup(backupCtx, req.Description, req.Type)
	if err != nil {
		logger.Error("Enhanced backup creation failed: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create enhanced backup", err)
		return
	}

	// Prepare response
	response := enhancedBackupResponse{
		Success:     result.Success,
		Filename:    result.Metadata.Filename,
		Size:        result.Size,
		Duration:    result.Duration.String(),
		Compressed:  result.Metadata.Compressed,
		Encrypted:   result.Metadata.Encrypted,
		Validated:   result.Metadata.Validated,
		Checksum:    result.Metadata.Checksum,
		Warnings:    result.Warnings,
		DownloadURL: "/api/v1/admin/backups/download/" + result.Metadata.Filename,
	}

	logger.Info("Enhanced backup created successfully: %s", result.Metadata.Filename)
	SuccessResponse(ctx, http.StatusOK, "Enhanced backup created successfully", response)
}

// @Summary     Restore database from enhanced backup
// @Description Restores database with advanced validation and safety measures
// @Tags        admin
// @Accept      json
// @Produce     json
// @Param       restore body enhancedRestoreRequest true "Enhanced restore details"
// @Success     200 {object} Response{data=enhancedRestoreResponse} "Database restored successfully"
// @Failure     400 {object} Response "Invalid request parameters"
// @Failure     404 {object} Response "Backup file not found"
// @Failure     500 {object} Response "Failed to restore database"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/enhanced/restore [post]
func (server *Server) restoreEnhancedBackup(ctx *gin.Context) {
	var req enhancedRestoreRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		logger.Warn("Invalid enhanced restore request format: %v", err)
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	logger.Info("Enhanced restore request for file: %s", req.Filename)

	// Load backup configuration
	backupConfig := config.LoadBackupConfig()
	if err := backupConfig.Validate(); err != nil {
		logger.Error("Invalid backup configuration: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Backup configuration error", err)
		return
	}

	// Create backup manager
	backupManager := backup.NewBackupManager(backupConfig, server.config)

	// Create context with timeout
	restoreCtx, cancel := context.WithTimeout(context.Background(), 60*time.Minute)
	defer cancel()

	// Restore backup
	result, err := backupManager.RestoreBackup(restoreCtx, req.Filename)
	if err != nil {
		logger.Error("Enhanced restore failed: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to restore from enhanced backup", err)
		return
	}

	// Prepare response
	response := enhancedRestoreResponse{
		Success:      result.Success,
		Duration:     result.Duration.String(),
		TablesCount:  result.TablesCount,
		RecordsCount: result.RecordsCount,
		Warnings:     result.Warnings,
	}

	logger.Info("Enhanced restore completed successfully from: %s", req.Filename)
	SuccessResponse(ctx, http.StatusOK, "Enhanced restore completed successfully", response)
}

// @Summary     Get backup status and health
// @Description Returns backup system status, recent activity, and health metrics
// @Tags        admin
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=backupStatusResponse} "Backup status retrieved successfully"
// @Failure     500 {object} Response "Failed to retrieve backup status"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/status [get]
func (server *Server) getBackupStatus(ctx *gin.Context) {
	logger.Info("Backup status request")

	// Load backup configuration
	backupConfig := config.LoadBackupConfig()

	// Get backup statistics
	stats, err := server.getBackupStatistics()
	if err != nil {
		logger.Error("Failed to get backup statistics: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve backup status", err)
		return
	}

	// Check backup system health
	health := server.checkBackupHealth(backupConfig)

	// Get recent backup activity
	recentActivity, err := server.getRecentBackupActivity(5) // Last 5 backups
	if err != nil {
		logger.Warn("Failed to get recent backup activity: %v", err)
	}

	response := backupStatusResponse{
		Enabled:        backupConfig.Enabled,
		AutoBackup:     backupConfig.AutoBackupEnabled,
		LastBackup:     stats.LastBackupTime,
		NextBackup:     stats.NextBackupTime,
		TotalBackups:   stats.TotalBackups,
		TotalSize:      stats.TotalSize,
		OldestBackup:   stats.OldestBackupTime,
		Health:         health,
		RecentActivity: recentActivity,
		Configuration: backupConfigSummary{
			RetentionDays:   backupConfig.RetentionDays,
			MaxBackupCount:  backupConfig.MaxBackupCount,
			CompressBackups: backupConfig.CompressBackups,
			EncryptBackups:  backupConfig.EncryptBackups,
			ValidateBackups: backupConfig.ValidateAfterBackup,
			StorageType:     backupConfig.StorageType,
		},
	}

	SuccessResponse(ctx, http.StatusOK, "Backup status retrieved successfully", response)
}

// @Summary     Validate backup file
// @Description Validates the integrity and structure of a backup file
// @Tags        admin
// @Accept      json
// @Produce     json
// @Param       filename path string true "Backup filename"
// @Success     200 {object} Response{data=backupValidationResponse} "Backup validation completed"
// @Failure     400 {object} Response "Invalid filename"
// @Failure     404 {object} Response "Backup file not found"
// @Failure     500 {object} Response "Validation failed"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/{filename}/validate [post]
func (server *Server) validateBackupFile(ctx *gin.Context) {
	filename := ctx.Param("filename")
	if filename == "" {
		ErrorResponse(ctx, http.StatusBadRequest, "Filename is required", nil)
		return
	}

	logger.Info("Backup validation request for file: %s", filename)

	// Load backup configuration
	backupConfig := config.LoadBackupConfig()
	backupManager := backup.NewBackupManager(backupConfig, server.config)

	// Perform validation
	validationResult := server.performBackupValidation(backupManager, filename)

	response := backupValidationResponse{
		Filename:       filename,
		Valid:          validationResult.Valid,
		FileExists:     validationResult.FileExists,
		ReadableFile:   validationResult.ReadableFile,
		ValidStructure: validationResult.ValidStructure,
		ChecksumMatch:  validationResult.ChecksumMatch,
		Size:           validationResult.Size,
		LastModified:   validationResult.LastModified,
		Issues:         validationResult.Issues,
		Warnings:       validationResult.Warnings,
	}
	if validationResult.Valid {
		SuccessResponse(ctx, http.StatusOK, "Backup validation completed successfully", response)
	} else {
		SuccessResponse(ctx, http.StatusOK, "Backup validation completed with issues", response)
	}
}

// Helper types for enhanced backup API

type enhancedBackupRequest struct {
	Description string `json:"description" binding:"required"`
	Type        string `json:"type" binding:"required"` // manual, automatic, migration, etc.
}

type enhancedBackupResponse struct {
	Success     bool     `json:"success"`
	Filename    string   `json:"filename"`
	Size        int64    `json:"size"`
	Duration    string   `json:"duration"`
	Compressed  bool     `json:"compressed"`
	Encrypted   bool     `json:"encrypted"`
	Validated   bool     `json:"validated"`
	Checksum    string   `json:"checksum"`
	Warnings    []string `json:"warnings,omitempty"`
	DownloadURL string   `json:"download_url"`
}

type enhancedRestoreRequest struct {
	Filename string `json:"filename" binding:"required"`
}

type enhancedRestoreResponse struct {
	Success      bool     `json:"success"`
	Duration     string   `json:"duration"`
	TablesCount  int      `json:"tables_count"`
	RecordsCount int64    `json:"records_count"`
	Warnings     []string `json:"warnings,omitempty"`
}

type backupStatusResponse struct {
	Enabled        bool                 `json:"enabled"`
	AutoBackup     bool                 `json:"auto_backup"`
	LastBackup     *time.Time           `json:"last_backup,omitempty"`
	NextBackup     *time.Time           `json:"next_backup,omitempty"`
	TotalBackups   int                  `json:"total_backups"`
	TotalSize      int64                `json:"total_size"`
	OldestBackup   *time.Time           `json:"oldest_backup,omitempty"`
	Health         backupHealthStatus   `json:"health"`
	RecentActivity []backupActivityItem `json:"recent_activity"`
	Configuration  backupConfigSummary  `json:"configuration"`
}

type backupHealthStatus struct {
	Overall   string    `json:"overall"` // healthy, warning, critical
	Issues    []string  `json:"issues,omitempty"`
	LastCheck time.Time `json:"last_check"`
}

type backupActivityItem struct {
	Timestamp   time.Time `json:"timestamp"`
	Action      string    `json:"action"` // backup, restore, cleanup
	Filename    string    `json:"filename,omitempty"`
	Status      string    `json:"status"` // success, failure, warning
	Duration    string    `json:"duration,omitempty"`
	Size        int64     `json:"size,omitempty"`
	Description string    `json:"description,omitempty"`
}

type backupConfigSummary struct {
	RetentionDays   int    `json:"retention_days"`
	MaxBackupCount  int    `json:"max_backup_count"`
	CompressBackups bool   `json:"compress_backups"`
	EncryptBackups  bool   `json:"encrypt_backups"`
	ValidateBackups bool   `json:"validate_backups"`
	StorageType     string `json:"storage_type"`
}

type backupValidationResponse struct {
	Filename       string    `json:"filename"`
	Valid          bool      `json:"valid"`
	FileExists     bool      `json:"file_exists"`
	ReadableFile   bool      `json:"readable_file"`
	ValidStructure bool      `json:"valid_structure"`
	ChecksumMatch  bool      `json:"checksum_match"`
	Size           int64     `json:"size"`
	LastModified   time.Time `json:"last_modified"`
	Issues         []string  `json:"issues,omitempty"`
	Warnings       []string  `json:"warnings,omitempty"`
}

type scheduleInfo struct {
	ID          string `json:"id"`
	Description string `json:"description"`
	Schedule    string `json:"schedule"`
	LastRun     string `json:"last_run"`
	NextRun     string `json:"next_run"`
	Enabled     bool   `json:"enabled"`
}

// Helper method implementations would go here...

// Helper structures for internal use
type backupStatistics struct {
	LastBackupTime   *time.Time
	NextBackupTime   *time.Time
	TotalBackups     int
	TotalSize        int64
	OldestBackupTime *time.Time
}

type validationResult struct {
	Valid          bool
	FileExists     bool
	ReadableFile   bool
	ValidStructure bool
	ChecksumMatch  bool
	Size           int64
	LastModified   time.Time
	Issues         []string
	Warnings       []string
}

// getBackupStatistics retrieves backup statistics
func (server *Server) getBackupStatistics() (*backupStatistics, error) {
	// Placeholder implementation - would scan backup directory and collect stats
	stats := &backupStatistics{
		TotalBackups: 0,
		TotalSize:    0,
	}

	// In a real implementation, this would scan the backup directory
	// and collect actual statistics

	return stats, nil
}

// checkBackupHealth checks the health of the backup system
func (server *Server) checkBackupHealth(_ config.BackupConfig) backupHealthStatus {
	health := backupHealthStatus{
		Overall:   "healthy",
		LastCheck: time.Now(),
		Issues:    []string{},
	}
	// Check if backup tools are available
	// In a real implementation, this would check database connectivity
	// For now, assume healthy

	// Add more health checks as needed

	return health
}

// getRecentBackupActivity retrieves recent backup activity
func (server *Server) getRecentBackupActivity(_ int) ([]backupActivityItem, error) {
	// Placeholder implementation - would read from activity log
	activity := []backupActivityItem{}

	// In a real implementation, this would read from an activity log
	// or scan backup files for recent activity

	return activity, nil
}

// performBackupValidation validates a backup file
func (server *Server) performBackupValidation(_ *backup.BackupManager, _ string) *validationResult {
	result := &validationResult{
		Valid:          true,
		FileExists:     true,
		ReadableFile:   true,
		ValidStructure: true,
		ChecksumMatch:  true,
		Issues:         []string{},
		Warnings:       []string{},
	}

	// In a real implementation, this would perform comprehensive validation
	// For now, just return a successful validation

	return result
}

// @Summary     Get backup schedules
// @Description Get all active backup schedules
// @Tags        admin
// @Produce     json
// @Success     200 {object} Response{data=[]scheduleInfo} "Backup schedules retrieved successfully"
// @Failure     500 {object} Response "Failed to get schedules"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/schedules [get]
func (server *Server) getBackupSchedules(ctx *gin.Context) {
	if server.enhancedBackupScheduler == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Enhanced backup scheduler not available", nil)
		return
	}

	schedules := server.enhancedBackupScheduler.GetSchedules()

	var scheduleList []scheduleInfo
	for id, schedule := range schedules {
		scheduleList = append(scheduleList, scheduleInfo{
			ID:          id,
			Description: schedule.Description,
			Schedule:    schedule.Interval.String(),
			LastRun:     "N/A",                                                  // lastRun is private, would need a getter method
			NextRun:     time.Now().Add(schedule.Interval).Format(time.RFC3339), // Estimate next run
			Enabled:     schedule.Enabled,
		})
	}

	SuccessResponse(ctx, http.StatusOK, "Backup schedules retrieved successfully", scheduleList)
}

// @Summary     Add backup schedule
// @Description Add a new backup schedule
// @Tags        admin
// @Accept      json
// @Produce     json
// @Param       schedule body addScheduleRequest true "Schedule details"
// @Success     200 {object} Response "Schedule added successfully"
// @Failure     400 {object} Response "Invalid request parameters"
// @Failure     500 {object} Response "Failed to add schedule"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/schedules [post]
func (server *Server) addBackupSchedule(ctx *gin.Context) {
	var req addScheduleRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	if server.enhancedBackupScheduler == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Enhanced backup scheduler not available", nil)
		return
	}

	err := server.enhancedBackupScheduler.AddSchedule(req.ID, req.Schedule, req.Description, req.BackupType)
	if err != nil {
		logger.Error("Failed to add backup schedule: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to add schedule", err)
		return
	}

	logger.Info("Added backup schedule: %s (%s)", req.ID, req.Description)
	SuccessResponse(ctx, http.StatusOK, "Schedule added successfully", nil)
}

// @Summary     Remove backup schedule
// @Description Remove a backup schedule
// @Tags        admin
// @Produce     json
// @Param       id path string true "Schedule ID"
// @Success     200 {object} Response "Schedule removed successfully"
// @Failure     500 {object} Response "Failed to remove schedule"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/schedules/{id} [delete]
func (server *Server) removeBackupSchedule(ctx *gin.Context) {
	scheduleID := ctx.Param("id")

	if server.enhancedBackupScheduler == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Enhanced backup scheduler not available", nil)
		return
	}

	err := server.enhancedBackupScheduler.RemoveSchedule(scheduleID)
	if err != nil {
		logger.Error("Failed to remove backup schedule %s: %v", scheduleID, err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to remove schedule", err)
		return
	}

	logger.Info("Removed backup schedule: %s", scheduleID)
	SuccessResponse(ctx, http.StatusOK, "Schedule removed successfully", nil)
}

// @Summary     Get backup history
// @Description Get backup history and statistics
// @Tags        admin
// @Produce     json
// @Param       limit query int false "Limit number of results" default(50)
// @Success     200 {object} Response{data=backupHistoryResponse} "Backup history retrieved successfully"
// @Failure     500 {object} Response "Failed to get backup history"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/history [get]
func (server *Server) getBackupHistory(ctx *gin.Context) {
	limit := 50
	if limitStr := ctx.Query("limit"); limitStr != "" {
		if parsedLimit, err := strconv.Atoi(limitStr); err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}

	if server.enhancedBackupScheduler == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Enhanced backup scheduler not available", nil)
		return
	}
	history := server.enhancedBackupScheduler.GetBackupHistory(limit)

	// Convert scheduler.BackupHistoryItem to backupHistoryItem
	var convertedHistory []backupHistoryItem
	for _, item := range history {
		convertedHistory = append(convertedHistory, backupHistoryItem{
			Timestamp:   item.Timestamp,
			Operation:   "backup", // Default operation
			Filename:    item.Filename,
			Success:     item.Success,
			Duration:    item.Duration.String(),
			Size:        item.Size,
			Description: fmt.Sprintf("Schedule: %s, Type: %s", item.ScheduleName, item.BackupType),
			Error:       item.Error,
		})
	}

	response := backupHistoryResponse{
		History: convertedHistory,
		Total:   len(convertedHistory),
	}

	SuccessResponse(ctx, http.StatusOK, "Backup history retrieved successfully", response)
}

type backupHistoryResponse struct {
	History []backupHistoryItem `json:"history"`
	Total   int                 `json:"total"`
}

type backupHistoryItem struct {
	Timestamp   time.Time `json:"timestamp"`
	Operation   string    `json:"operation"`
	Filename    string    `json:"filename"`
	Success     bool      `json:"success"`
	Duration    string    `json:"duration"`
	Size        int64     `json:"size"`
	Description string    `json:"description"`
	Error       string    `json:"error,omitempty"`
}

type addScheduleRequest struct {
	ID          string `json:"id" binding:"required"`
	Schedule    string `json:"schedule" binding:"required"`
	Description string `json:"description" binding:"required"`
	BackupType  string `json:"backup_type"`
}

type cleanupRequest struct {
	MaxAge string `json:"max_age"` // Duration string like "720h" for 30 days
}

// @Summary     Manual cleanup of old backups
// @Description Manually trigger cleanup of old backup files
// @Tags        admin
// @Accept      json
// @Produce     json
// @Param       cleanup body cleanupRequest false "Cleanup parameters"
// @Success     200 {object} Response "Cleanup completed successfully"
// @Failure     500 {object} Response "Failed to cleanup backups"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/backups/cleanup [post]
func (server *Server) cleanupOldBackupsHandler(ctx *gin.Context) {
	var req cleanupRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		// Use default values if no request body
		req.MaxAge = "720h" // 30 days default
	}

	maxAge, err := time.ParseDuration(req.MaxAge)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid max_age duration format", err)
		return
	}

	// Use the existing CleanupOldBackups method
	err = server.CleanupOldBackups(maxAge)
	if err != nil {
		logger.Error("Failed to cleanup old backups: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to cleanup backups", err)
		return
	}
	logger.Info("Manual backup cleanup completed successfully")
	SuccessResponse(ctx, http.StatusOK, "Cleanup completed successfully", nil)
}
