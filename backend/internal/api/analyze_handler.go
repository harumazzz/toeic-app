package api

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/analyze"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/token"
)

// analyzeTextRequest defines the structure for analyzing text
type analyzeTextRequest struct {
	Text            string `json:"text" binding:"required"`
	MinSynonymLevel string `json:"min_synonym_level,omitempty"`
	Async           bool   `json:"async,omitempty"`
}

// analyzeMultipleTextsRequest defines the structure for analyzing multiple texts
type analyzeMultipleTextsRequest struct {
	Texts           []string `json:"texts" binding:"required"`
	MinSynonymLevel string   `json:"min_synonym_level,omitempty"`
}

// analyzeTextResponse defines the response structure for text analysis
type analyzeTextResponse struct {
	UserID    int32                         `json:"user_id"`
	Text      string                        `json:"text"`
	Result    *analyze.TextAnalysisResponse `json:"result,omitempty"`
	Error     string                        `json:"error,omitempty"`
	Timestamp string                        `json:"timestamp"`
	Cached    bool                          `json:"cached,omitempty"`
}

// @Summary Analyze text
// @Description Analyze English text to get word levels and synonym suggestions
// @Tags text-analysis
// @Accept json
// @Produce json
// @Param request body analyzeTextRequest true "Text analysis request"
// @Success 200 {object} Response{data=analyzeTextResponse} "Text analyzed successfully"
// @Failure 400 {object} Response "Invalid request parameters"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 503 {object} Response "Analyze service unavailable"
// @Failure 500 {object} Response "Server error"
// @Security ApiKeyAuth
// @Router /api/v1/analyze/text [post]
func (server *Server) analyzeText(ctx *gin.Context) {
	var req analyzeTextRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	// Get user ID from authorization payload
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

	// Check if analyze service is available
	if server.analyzeService == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Analyze service not available", nil)
		return
	}

	if !server.analyzeService.IsHealthy() {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Analyze service is not healthy", nil)
		return
	}

	// Set default min synonym level if not provided
	if req.MinSynonymLevel == "" {
		req.MinSynonymLevel = "A2"
	}

	// Handle async request
	if req.Async {
		// Start async analysis
		resultChan := server.analyzeService.AnalyzeTextWithChannel(ctx, authPayload.ID, req.Text, req.MinSynonymLevel)

		// Return immediately with a status
		SuccessResponse(ctx, http.StatusAccepted, "Text analysis started", map[string]interface{}{
			"user_id": authPayload.ID,
			"text":    req.Text,
			"status":  "processing",
			"async":   true,
		})

		// Process result in background
		go func() {
			select {
			case result := <-resultChan:
				if result.Error != nil {
					logger.Error("Async text analysis failed for user %d: %v", authPayload.ID, result.Error)
				} else {
					logger.Info("Async text analysis completed for user %d", authPayload.ID)
					// Here you could store the result in database or send via WebSocket
					// For now, just log it
				}
			case <-time.After(5 * time.Minute): // Timeout
				logger.Warn("Async text analysis timed out for user %d", authPayload.ID)
			}
		}()

		return
	}

	// Perform synchronous analysis
	analysisResult, err := server.analyzeService.AnalyzeTextSync(ctx, authPayload.ID, req.Text, req.MinSynonymLevel)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to analyze text", err)
		return
	}

	response := analyzeTextResponse{
		UserID:    analysisResult.UserID,
		Text:      analysisResult.Text,
		Result:    analysisResult.Result,
		Error:     analysisResult.Error,
		Timestamp: analysisResult.Timestamp.Format(time.RFC3339),
	}

	SuccessResponse(ctx, http.StatusOK, "Text analyzed successfully", response)
}

// @Summary Analyze multiple texts
// @Description Analyze multiple English texts concurrently to get word levels and synonym suggestions
// @Tags text-analysis
// @Accept json
// @Produce json
// @Param request body analyzeMultipleTextsRequest true "Multiple texts analysis request"
// @Success 200 {object} Response{data=[]analyzeTextResponse} "Texts analyzed successfully"
// @Failure 400 {object} Response "Invalid request parameters"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 503 {object} Response "Analyze service unavailable"
// @Failure 500 {object} Response "Server error"
// @Security ApiKeyAuth
// @Router /api/v1/analyze/texts [post]
func (server *Server) analyzeMultipleTexts(ctx *gin.Context) {
	var req analyzeMultipleTextsRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	// Validate request
	if len(req.Texts) == 0 {
		ErrorResponse(ctx, http.StatusBadRequest, "At least one text is required", nil)
		return
	}

	if len(req.Texts) > 10 { // Limit to prevent abuse
		ErrorResponse(ctx, http.StatusBadRequest, "Maximum 10 texts allowed per request", nil)
		return
	}

	// Get user ID from authorization payload
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

	// Check if analyze service is available
	if server.analyzeService == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Analyze service not available", nil)
		return
	}

	if !server.analyzeService.IsHealthy() {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Analyze service is not healthy", nil)
		return
	}

	// Set default min synonym level if not provided
	if req.MinSynonymLevel == "" {
		req.MinSynonymLevel = "A2"
	}

	// Perform concurrent analysis
	resultChan := server.analyzeService.AnalyzeMultipleTexts(ctx, authPayload.ID, req.Texts, req.MinSynonymLevel)

	select {
	case result := <-resultChan:
		if result.Error != nil {
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to analyze texts", result.Error)
			return
		}

		// Convert results to response format
		responses := make([]analyzeTextResponse, len(result.Results))
		for i, analysisResult := range result.Results {
			responses[i] = analyzeTextResponse{
				UserID:    analysisResult.UserID,
				Text:      analysisResult.Text,
				Result:    analysisResult.Result,
				Error:     analysisResult.Error,
				Timestamp: analysisResult.Timestamp.Format(time.RFC3339),
			}
		}

		SuccessResponse(ctx, http.StatusOK, "Texts analyzed successfully", responses)

	case <-ctx.Done():
		ErrorResponse(ctx, http.StatusRequestTimeout, "Request timeout", nil)
		return
	}
}

// @Summary Get analyze service health
// @Description Check the health status of the analyze service
// @Tags text-analysis
// @Accept json
// @Produce json
// @Success 200 {object} Response "Service health status"
// @Failure 500 {object} Response "Server error"
// @Security ApiKeyAuth
// @Router /api/v1/analyze/health [get]
func (server *Server) getAnalyzeServiceHealth(ctx *gin.Context) {
	if server.analyzeService == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Analyze service not available", nil)
		return
	}

	healthy, lastCheck := server.analyzeService.GetHealthStatus()

	status := map[string]interface{}{
		"healthy":           healthy,
		"last_health_check": lastCheck.Format(time.RFC3339),
		"service_available": true,
	}

	if healthy {
		SuccessResponse(ctx, http.StatusOK, "Analyze service is healthy", status)
	} else {
		SuccessResponse(ctx, http.StatusOK, "Analyze service is unhealthy", status)
	}
}

// @Summary Get analyze service statistics
// @Description Get detailed statistics about the analyze service
// @Tags text-analysis
// @Accept json
// @Produce json
// @Success 200 {object} Response "Service statistics"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Server error"
// @Security ApiKeyAuth
// @Router /api/v1/analyze/stats [get]
func (server *Server) getAnalyzeServiceStats(ctx *gin.Context) {
	// This endpoint might be restricted to admin users
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

	// Check if user is admin (optional - you might want to restrict this)
	isAdmin, err := server.IsUserAdmin(ctx, authPayload.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to check admin status", err)
		return
	}

	if !isAdmin {
		ErrorResponse(ctx, http.StatusForbidden, "Admin access required", nil)
		return
	}

	if server.analyzeService == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Analyze service not available", nil)
		return
	}

	stats := server.analyzeService.GetStats()
	SuccessResponse(ctx, http.StatusOK, "Analyze service statistics retrieved", stats)
}

// @Summary Clear analyze service cache
// @Description Clear the analyze service cache (admin only)
// @Tags text-analysis
// @Accept json
// @Produce json
// @Success 200 {object} Response "Cache cleared successfully"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 403 {object} Response "Admin access required"
// @Failure 500 {object} Response "Server error"
// @Security ApiKeyAuth
// @Router /api/v1/analyze/cache/clear [post]
func (server *Server) clearAnalyzeServiceCache(ctx *gin.Context) {
	// Get user ID from authorization payload
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

	// Check if user is admin
	isAdmin, err := server.IsUserAdmin(ctx, authPayload.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to check admin status", err)
		return
	}

	if !isAdmin {
		ErrorResponse(ctx, http.StatusForbidden, "Admin access required", nil)
		return
	}

	if server.analyzeService == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Analyze service not available", nil)
		return
	}

	server.analyzeService.ClearCache()
	SuccessResponse(ctx, http.StatusOK, "Analyze service cache cleared successfully", nil)
}

// @Summary Get word analysis by ID
// @Description Get cached word analysis result by user and text
// @Tags text-analysis
// @Accept json
// @Produce json
// @Param text query string true "Text to search for"
// @Success 200 {object} Response{data=analyzeTextResponse} "Cached analysis found"
// @Failure 400 {object} Response "Invalid request parameters"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 404 {object} Response "Analysis not found in cache"
// @Failure 500 {object} Response "Server error"
// @Security ApiKeyAuth
// @Router /api/v1/analyze/cache [get]
func (server *Server) getCachedAnalysis(ctx *gin.Context) {
	text := ctx.Query("text")
	if text == "" {
		ErrorResponse(ctx, http.StatusBadRequest, "Text parameter is required", nil)
		return
	}

	minLevel := ctx.Query("min_synonym_level")
	if minLevel == "" {
		minLevel = "A2"
	}

	// Get user ID from authorization payload
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
	if server.analyzeService == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Analyze service not available", nil)
		return
	}

	// Try to get from cache using the analyze service method
	cachedResult, err := server.analyzeService.AnalyzeTextSync(ctx, authPayload.ID, text, minLevel)
	if err != nil {
		ErrorResponse(ctx, http.StatusNotFound, "Analysis not found in cache", err)
		return
	}

	response := analyzeTextResponse{
		UserID:    cachedResult.UserID,
		Text:      cachedResult.Text,
		Result:    cachedResult.Result,
		Error:     cachedResult.Error,
		Timestamp: cachedResult.Timestamp.Format(time.RFC3339),
		Cached:    true,
	}

	SuccessResponse(ctx, http.StatusOK, "Cached analysis retrieved", response)
}
