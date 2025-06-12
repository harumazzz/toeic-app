package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/token"
	"github.com/toeic-app/internal/upgrade"
)

// upgradeCheckRequest represents the request body for checking updates
type upgradeCheckRequest struct {
	CurrentVersion string `json:"current_version" binding:"required"`
	Platform       string `json:"platform"`
	UserAgent      string `json:"user_agent"`
}

// subscriptionRequest represents the request body for subscription preferences
type subscriptionRequest struct {
	NotifyMajor    bool   `json:"notify_major"`
	NotifyMinor    bool   `json:"notify_minor"`
	NotifyPatches  bool   `json:"notify_patches"`
	NotifyRequired bool   `json:"notify_required"`
	ClientVersion  string `json:"client_version"`
	Platform       string `json:"platform"`
}

// addVersionRequest represents the request body for adding a new version (admin only)
type addVersionRequest struct {
	Version     string            `json:"version" binding:"required"`
	Title       string            `json:"title" binding:"required"`
	Description string            `json:"description" binding:"required"`
	Required    bool              `json:"required"`
	Changes     []string          `json:"changes"`
	Downloads   map[string]string `json:"downloads"`
	MinVersion  string            `json:"min_version"`
	Deprecated  []string          `json:"deprecated"`
	Metadata    map[string]string `json:"metadata"`
}

// notifyUpgradeRequest represents the request body for sending upgrade notifications
type notifyUpgradeRequest struct {
	Version     string   `json:"version" binding:"required"`
	TargetUsers []string `json:"target_users"` // If empty, broadcasts to all
}

// @Summary WebSocket upgrade for real-time notifications
// @Description Upgrade HTTP connection to WebSocket for real-time upgrade notifications
// @Tags upgrade
// @Accept json
// @Produce json
// @Param Authorization header string true "Bearer JWT token"
// @Success 101 {string} string "Switching Protocols"
// @Failure 400 {object} Response "Bad Request"
// @Failure 401 {object} Response "Unauthorized"
// @Security ApiKeyAuth
// @Router /api/v1/upgrade/ws [get]
func (server *Server) upgradeWebSocket(ctx *gin.Context) {
	server.wsManager.HandleWebSocket(ctx, server.tokenMaker)
}

// @Summary Check for app updates
// @Description Check if there are any updates available for the current app version
// @Tags upgrade
// @Accept json
// @Produce json
// @Param request body upgradeCheckRequest true "Current version information"
// @Success 200 {object} Response{data=upgrade.UpdateCheckResponse} "Update check completed"
// @Failure 400 {object} Response "Invalid request"
// @Failure 500 {object} Response "Internal server error"
// @Router /api/v1/upgrade/check [post]
func (server *Server) checkForUpdates(ctx *gin.Context) {
	var req upgradeCheckRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	response, err := server.upgradeService.CheckForUpdates(req.CurrentVersion, req.Platform)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to check for updates", err)
		return
	}

	logger.Debug("Update check for version %s: has_update=%v, required=%v",
		req.CurrentVersion, response.HasUpdate, response.UpdateRequired)

	SuccessResponse(ctx, http.StatusOK, "Update check completed", response)
}

// @Summary Get current app version
// @Description Get the current latest version of the application
// @Tags upgrade
// @Produce json
// @Success 200 {object} Response{data=upgrade.AppVersion} "Current version retrieved"
// @Router /api/v1/upgrade/current [get]
func (server *Server) getCurrentVersion(ctx *gin.Context) {
	currentVersion := server.upgradeService.GetCurrentVersion()
	SuccessResponse(ctx, http.StatusOK, "Current version retrieved", currentVersion)
}

// @Summary Get all app versions
// @Description Get all available versions of the application
// @Tags upgrade
// @Produce json
// @Success 200 {object} Response{data=map[string]upgrade.AppVersion} "All versions retrieved"
// @Router /api/v1/upgrade/versions [get]
func (server *Server) getAllVersions(ctx *gin.Context) {
	versions := server.upgradeService.GetVersions()
	SuccessResponse(ctx, http.StatusOK, "All versions retrieved", versions)
}

// @Summary Get specific app version
// @Description Get details of a specific version
// @Tags upgrade
// @Produce json
// @Param version path string true "Version number (e.g., 1.0.0)"
// @Success 200 {object} Response{data=upgrade.AppVersion} "Version details retrieved"
// @Failure 404 {object} Response "Version not found"
// @Router /api/v1/upgrade/versions/{version} [get]
func (server *Server) getVersion(ctx *gin.Context) {
	version := ctx.Param("version")
	if version == "" {
		ErrorResponse(ctx, http.StatusBadRequest, "Version parameter is required", nil)
		return
	}

	versionInfo, exists := server.upgradeService.GetVersion(version)
	if !exists {
		ErrorResponse(ctx, http.StatusNotFound, "Version not found", nil)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Version details retrieved", versionInfo)
}

// @Summary Subscribe to upgrade notifications
// @Description Subscribe to real-time upgrade notifications with preferences
// @Tags upgrade
// @Accept json
// @Produce json
// @Param request body subscriptionRequest true "Subscription preferences"
// @Success 200 {object} Response "Subscribed to upgrade notifications"
// @Failure 400 {object} Response "Invalid request"
// @Failure 401 {object} Response "Unauthorized"
// @Security ApiKeyAuth
// @Router /api/v1/upgrade/subscribe [post]
func (server *Server) subscribeToUpgrades(ctx *gin.Context) {
	// Get user from auth payload
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ErrorResponse(ctx, http.StatusUnauthorized, "Authorization payload not found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusUnauthorized, "Invalid authorization payload", nil)
		return
	}

	var req subscriptionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	subscriber := &upgrade.Subscriber{
		NotifyMajor:    req.NotifyMajor,
		NotifyMinor:    req.NotifyMinor,
		NotifyPatches:  req.NotifyPatches,
		NotifyRequired: req.NotifyRequired,
		ClientVersion:  req.ClientVersion,
		Platform:       req.Platform,
	}

	if err := server.upgradeService.Subscribe(authPayload.Username, subscriber); err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to subscribe to upgrades", err)
		return
	}

	logger.Info("User %s subscribed to upgrade notifications", authPayload.Username)
	SuccessResponse(ctx, http.StatusOK, "Successfully subscribed to upgrade notifications", gin.H{
		"user_id":     authPayload.Username,
		"preferences": subscriber,
	})
}

// @Summary Unsubscribe from upgrade notifications
// @Description Unsubscribe from real-time upgrade notifications
// @Tags upgrade
// @Produce json
// @Success 200 {object} Response "Unsubscribed from upgrade notifications"
// @Failure 401 {object} Response "Unauthorized"
// @Security ApiKeyAuth
// @Router /api/v1/upgrade/unsubscribe [post]
func (server *Server) unsubscribeFromUpgrades(ctx *gin.Context) {
	// Get user from auth payload
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ErrorResponse(ctx, http.StatusUnauthorized, "Authorization payload not found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusUnauthorized, "Invalid authorization payload", nil)
		return
	}

	if err := server.upgradeService.Unsubscribe(authPayload.Username); err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to unsubscribe from upgrades", err)
		return
	}

	logger.Info("User %s unsubscribed from upgrade notifications", authPayload.Username)
	SuccessResponse(ctx, http.StatusOK, "Successfully unsubscribed from upgrade notifications", gin.H{
		"user_id": authPayload.Username,
	})
}

// @Summary Get upgrade service statistics
// @Description Get statistics about the upgrade service (admin only)
// @Tags upgrade
// @Produce json
// @Success 200 {object} Response{data=map[string]interface{}} "Upgrade statistics retrieved"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 403 {object} Response "Forbidden - Admin access required"
// @Security ApiKeyAuth
// @Router /api/v1/upgrade/stats [get]
func (server *Server) getUpgradeStats(ctx *gin.Context) {
	stats := server.upgradeService.GetStats()
	SuccessResponse(ctx, http.StatusOK, "Upgrade statistics retrieved", stats)
}

// @Summary Add new app version (Admin only)
// @Description Add a new version to the system and optionally notify users
// @Tags upgrade
// @Accept json
// @Produce json
// @Param request body addVersionRequest true "Version information"
// @Success 201 {object} Response{data=upgrade.AppVersion} "Version added successfully"
// @Failure 400 {object} Response "Invalid request"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 403 {object} Response "Forbidden - Admin access required"
// @Security ApiKeyAuth
// @Router /api/v1/upgrade/versions [post]
func (server *Server) addVersion(ctx *gin.Context) {
	var req addVersionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	version := &upgrade.AppVersion{
		Version:     req.Version,
		Title:       req.Title,
		Description: req.Description,
		Required:    req.Required,
		Changes:     req.Changes,
		Downloads:   req.Downloads,
		MinVersion:  req.MinVersion,
		Deprecated:  req.Deprecated,
		Metadata:    req.Metadata,
	}

	if err := server.upgradeService.AddVersion(version); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Failed to add version", err)
		return
	}

	logger.Info("Admin added new version: %s", req.Version)
	SuccessResponse(ctx, http.StatusCreated, "Version added successfully", version)
}

// @Summary Send upgrade notification (Admin only)
// @Description Send upgrade notification to users
// @Tags upgrade
// @Accept json
// @Produce json
// @Param request body notifyUpgradeRequest true "Notification information"
// @Success 200 {object} Response "Notification sent successfully"
// @Failure 400 {object} Response "Invalid request"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 403 {object} Response "Forbidden - Admin access required"
// @Failure 404 {object} Response "Version not found"
// @Security ApiKeyAuth
// @Router /api/v1/upgrade/notify [post]
func (server *Server) notifyUpgrade(ctx *gin.Context) {
	var req notifyUpgradeRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	version, exists := server.upgradeService.GetVersion(req.Version)
	if !exists {
		ErrorResponse(ctx, http.StatusNotFound, "Version not found", nil)
		return
	}

	if err := server.upgradeService.NotifyUpgrade(version, req.TargetUsers); err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to send upgrade notification", err)
		return
	}

	targetCount := len(req.TargetUsers)
	if targetCount == 0 {
		targetCount = server.wsManager.GetConnectedUsers()
	}

	logger.Info("Admin sent upgrade notification for version %s to %d users", req.Version, targetCount)
	SuccessResponse(ctx, http.StatusOK, "Upgrade notification sent successfully", gin.H{
		"version":      req.Version,
		"target_count": targetCount,
		"broadcast":    len(req.TargetUsers) == 0,
	})
}

// @Summary Get WebSocket connection status
// @Description Get the current WebSocket connection statistics
// @Tags upgrade
// @Produce json
// @Success 200 {object} Response{data=map[string]interface{}} "WebSocket status retrieved"
// @Router /api/v1/upgrade/ws/status [get]
func (server *Server) getWebSocketStatus(ctx *gin.Context) {
	connectedUsers := server.wsManager.GetConnectedUsers()
	connectedUserIDs := server.wsManager.GetConnectedUserIDs()

	status := gin.H{
		"connected_users":    connectedUsers,
		"connected_user_ids": connectedUserIDs,
		"status":             "active",
	}

	SuccessResponse(ctx, http.StatusOK, "WebSocket status retrieved", status)
}
