package api

import (
	"database/sql"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/token"
)

// WordProgressJSONField is a placeholder for JSON fields in Swagger docs
// swagger:model
// example: {"en": "example"}
type WordProgressJSONField struct {
	Raw interface{} `json:"raw"`
}

// WordProgressResponse is used for Swagger documentation only
// swagger:model
// example: {"id":1,"word":"example","pronounce":"ex-am-ple","level":1,"descript_level":"A1","short_mean":"short meaning","means":{"raw":{"en":"meaning"}},"snym":{"raw":null},"freq":1.0,"conjugation":{"raw":null}}
type WordProgressResponse struct {
	ID            int32                 `json:"id"`
	Word          string                `json:"word"`
	Pronounce     string                `json:"pronounce"`
	Level         int32                 `json:"level"`
	DescriptLevel string                `json:"descript_level"`
	ShortMean     string                `json:"short_mean"`
	Means         WordProgressJSONField `json:"means"`
	Snym          WordProgressJSONField `json:"snym"`
	Freq          float32               `json:"freq"`
	Conjugation   WordProgressJSONField `json:"conjugation"`
}

// NewWordProgressResponse creates a WordProgressResponse from a db.Word
func NewWordProgressResponse(word db.Word) WordProgressResponse {
	return WordProgressResponse{
		ID:            word.ID,
		Word:          word.Word,
		Pronounce:     word.Pronounce,
		Level:         word.Level,
		DescriptLevel: word.DescriptLevel,
		ShortMean:     word.ShortMean,
		Means:         WordProgressJSONField{Raw: word.Means.RawMessage},
		Snym:          WordProgressJSONField{Raw: word.Snym.RawMessage},
		Freq:          word.Freq,
		Conjugation:   WordProgressJSONField{Raw: word.Conjugation.RawMessage},
	}
}

// UserWordProgressResponse defines the structure for user word progress information returned to clients
type UserWordProgressResponse struct {
	UserID         int32      `json:"user_id"`
	WordID         int32      `json:"word_id"`
	LastReviewedAt *time.Time `json:"last_reviewed_at,omitempty"`
	NextReviewAt   *time.Time `json:"next_review_at,omitempty"`
	IntervalDays   int32      `json:"interval_days"`
	EaseFactor     float32    `json:"ease_factor"`
	Repetitions    int32      `json:"repetitions"`
	CreatedAt      string     `json:"created_at" example:"2025-05-01T13:45:00Z" format:"date-time"`
	UpdatedAt      string     `json:"updated_at" example:"2025-05-01T13:45:00Z" format:"date-time"`
}

// createUserWordProgressRequest defines the structure for creating a user word progress record
type createUserWordProgressRequest struct {
	WordID         int32   `json:"word_id" binding:"required"`
	LastReviewedAt *string `json:"last_reviewed_at"`
	NextReviewAt   *string `json:"next_review_at"`
	IntervalDays   int32   `json:"interval_days" binding:"min=0"`
	EaseFactor     float32 `json:"ease_factor" binding:"min=0"`
	Repetitions    int32   `json:"repetitions" binding:"min=0"`
}

// parseTimeString parses a time string in various formats and returns a time.Time and error
func parseTimeString(timeStr string) (time.Time, error) {
	// List of time formats to try, in order of preference
	formats := []string{
		time.RFC3339,                 // "2006-01-02T15:04:05Z07:00"
		time.RFC3339Nano,             // "2006-01-02T15:04:05.999999999Z07:00"
		"2006-01-02T15:04:05.999999", // "2025-06-11T06:12:03.388916"
		"2006-01-02T15:04:05",        // "2006-01-02T15:04:05"
		"2006-01-02 15:04:05.999999", // "2006-01-02 15:04:05.999999"
		"2006-01-02 15:04:05",        // "2006-01-02 15:04:05"
	}

	for _, format := range formats {
		if t, err := time.Parse(format, timeStr); err == nil {
			return t, nil
		}
	}

	return time.Time{}, fmt.Errorf("unable to parse time string: %s", timeStr)
}

// NewUserWordProgressResponse creates a UserWordProgressResponse from a UserWordProgress model
func NewUserWordProgressResponse(progress db.UserWordProgress) UserWordProgressResponse {
	var lastReviewed *time.Time
	var nextReview *time.Time

	if progress.LastReviewedAt.Valid {
		t := progress.LastReviewedAt.Time
		lastReviewed = &t
	}

	if progress.NextReviewAt.Valid {
		t := progress.NextReviewAt.Time
		nextReview = &t
	}

	return UserWordProgressResponse{
		UserID:         progress.UserID,
		WordID:         progress.WordID,
		LastReviewedAt: lastReviewed,
		NextReviewAt:   nextReview,
		IntervalDays:   progress.IntervalDays,
		EaseFactor:     progress.EaseFactor,
		Repetitions:    progress.Repetitions,
		CreatedAt:      progress.CreatedAt.Format(time.RFC3339),
		UpdatedAt:      progress.UpdatedAt.Format(time.RFC3339),
	}
}

// @Summary Create user word progress
// @Description Create a new user word progress record
// @Tags user-word-progress
// @Accept json
// @Produce json
// @Param request body createUserWordProgressRequest true "User word progress data"
// @Success 201 {object} Response{data=UserWordProgressResponse} "User word progress created successfully"
// @Failure 400 {object} Response "Invalid request parameters"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Failed to create user word progress"
// @Security ApiKeyAuth
// @Router /api/v1/user-word-progress [post]
func (server *Server) createUserWordProgress(ctx *gin.Context) {
	var req createUserWordProgressRequest
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
	// Create LastReviewedAt and NextReviewAt as sql.NullTime
	var lastReviewedAt sql.NullTime
	var nextReviewAt sql.NullTime

	if req.LastReviewedAt != nil {
		if parsedTime, err := parseTimeString(*req.LastReviewedAt); err != nil {
			ErrorResponse(ctx, http.StatusBadRequest, "Invalid last_reviewed_at format", err)
			return
		} else {
			lastReviewedAt = sql.NullTime{
				Time:  parsedTime,
				Valid: true,
			}
		}
	}

	if req.NextReviewAt != nil {
		if parsedTime, err := parseTimeString(*req.NextReviewAt); err != nil {
			ErrorResponse(ctx, http.StatusBadRequest, "Invalid next_review_at format", err)
			return
		} else {
			nextReviewAt = sql.NullTime{
				Time:  parsedTime,
				Valid: true,
			}
		}
	}

	arg := db.CreateUserWordProgressParams{
		UserID:         authPayload.ID,
		WordID:         req.WordID,
		LastReviewedAt: lastReviewedAt,
		NextReviewAt:   nextReviewAt,
		IntervalDays:   req.IntervalDays,
		EaseFactor:     req.EaseFactor,
		Repetitions:    req.Repetitions,
	}

	progress, err := server.store.CreateUserWordProgress(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create user word progress", err)
		return
	}

	progressResp := NewUserWordProgressResponse(progress)
	SuccessResponse(ctx, http.StatusCreated, "User word progress created successfully", progressResp)
}

// @Summary Get user word progress
// @Description Get a specific word progress record for the current user. Returns null if no progress record exists.
// @Tags user-word-progress
// @Accept json
// @Produce json
// @Param word_id path int true "Word ID"
// @Success 200 {object} Response{data=UserWordProgressResponse} "User word progress retrieved successfully (may be null if not found)"
// @Failure 400 {object} Response "Invalid word ID format"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Server error"
// @Security ApiKeyAuth
// @Router /api/v1/user-word-progress/{word_id} [get]
func (server *Server) getUserWordProgress(ctx *gin.Context) {
	wordID, err := strconv.ParseInt(ctx.Param("word_id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid word ID format", err)
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

	arg := db.GetUserWordProgressParams{
		UserID: authPayload.ID,
		WordID: int32(wordID),
	}
	progress, err := server.store.GetUserWordProgress(ctx, arg)
	if err != nil {
		if err == sql.ErrNoRows {
			// Return null when no user word progress is found instead of an error
			SuccessResponse(ctx, http.StatusOK, "User word progress retrieved successfully", nil)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve user word progress", err)
		return
	}

	progressResp := NewUserWordProgressResponse(progress)
	SuccessResponse(ctx, http.StatusOK, "User word progress retrieved successfully", progressResp)
}

// updateUserWordProgressRequest defines the structure for updating a user word progress record
type updateUserWordProgressRequest struct {
	LastReviewedAt *string `json:"last_reviewed_at"`
	NextReviewAt   *string `json:"next_review_at"`
	IntervalDays   int32   `json:"interval_days" binding:"min=0"`
	EaseFactor     float32 `json:"ease_factor" binding:"min=0"`
	Repetitions    int32   `json:"repetitions" binding:"min=0"`
}

// @Summary Update user word progress
// @Description Update a word progress record for the current user
// @Tags user-word-progress
// @Accept json
// @Produce json
// @Param word_id path int true "Word ID"
// @Param request body updateUserWordProgressRequest true "User word progress data to update"
// @Success 200 {object} Response{data=UserWordProgressResponse} "User word progress updated successfully"
// @Failure 400 {object} Response "Invalid request parameters or word ID format"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 404 {object} Response "User word progress not found"
// @Failure 500 {object} Response "Server error"
// @Security ApiKeyAuth
// @Router /api/v1/user-word-progress/{word_id} [put]
func (server *Server) updateUserWordProgress(ctx *gin.Context) {
	wordIDParam := ctx.Param("word_id")
	logger.Debug("Updating user word progress for word ID: %s", wordIDParam)

	wordID, err := strconv.ParseInt(wordIDParam, 10, 32)
	if err != nil {
		logger.Error("Failed to parse word ID: %v", err)
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid word ID format", err)
		return
	}

	var req updateUserWordProgressRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		logger.Error("Failed to bind request JSON: %v", err)
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	logger.Debug("Request data: interval=%d, ease=%f, repetitions=%d",
		req.IntervalDays, req.EaseFactor, req.Repetitions)

	// Get user ID from authorization payload
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		logger.Error("Authorization payload not found")
		ErrorResponse(ctx, http.StatusUnauthorized, "Authorization payload not found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		logger.Error("Invalid authorization payload type")
		ErrorResponse(ctx, http.StatusUnauthorized, "Invalid authorization payload", nil)
		return
	}

	logger.Debug("User ID from token: %d", authPayload.ID)
	// Create LastReviewedAt and NextReviewAt as sql.NullTime
	var lastReviewedAt sql.NullTime
	var nextReviewAt sql.NullTime

	if req.LastReviewedAt != nil {
		if parsedTime, err := parseTimeString(*req.LastReviewedAt); err != nil {
			logger.Error("Failed to parse last_reviewed_at: %v", err)
			ErrorResponse(ctx, http.StatusBadRequest, "Invalid last_reviewed_at format", err)
			return
		} else {
			lastReviewedAt = sql.NullTime{
				Time:  parsedTime,
				Valid: true,
			}
			logger.Debug("Last reviewed at: %v", parsedTime)
		}
	}

	if req.NextReviewAt != nil {
		if parsedTime, err := parseTimeString(*req.NextReviewAt); err != nil {
			logger.Error("Failed to parse next_review_at: %v", err)
			ErrorResponse(ctx, http.StatusBadRequest, "Invalid next_review_at format", err)
			return
		} else {
			nextReviewAt = sql.NullTime{
				Time:  parsedTime,
				Valid: true,
			}
			logger.Debug("Next review at: %v", parsedTime)
		}
	}

	arg := db.UpdateUserWordProgressParams{
		UserID:         authPayload.ID,
		WordID:         int32(wordID),
		LastReviewedAt: lastReviewedAt,
		NextReviewAt:   nextReviewAt,
		IntervalDays:   req.IntervalDays,
		EaseFactor:     req.EaseFactor,
		Repetitions:    req.Repetitions,
	}

	logger.Debug("Calling store.UpdateUserWordProgress for user %d and word %d",
		authPayload.ID, wordID)

	progress, err := server.store.UpdateUserWordProgress(ctx, arg)
	if err != nil {
		if err == sql.ErrNoRows {
			logger.Warn("User word progress not found for user %d and word %d",
				authPayload.ID, wordID)
			ErrorResponse(ctx, http.StatusNotFound, "User word progress not found", err)
			return
		}
		logger.Error("Failed to update user word progress: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update user word progress", err)
		return
	}

	logger.Info("Successfully updated word progress for user %d and word %d",
		authPayload.ID, wordID)

	progressResp := NewUserWordProgressResponse(progress)
	SuccessResponse(ctx, http.StatusOK, "User word progress updated successfully", progressResp)
}

// @Summary Delete user word progress
// @Description Delete a word progress record for the current user
// @Tags user-word-progress
// @Accept json
// @Produce json
// @Param word_id path int true "Word ID"
// @Success 200 {object} Response "User word progress deleted successfully"
// @Failure 400 {object} Response "Invalid word ID format"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Server error"
// @Security ApiKeyAuth
// @Router /api/v1/user-word-progress/{word_id} [delete]
func (server *Server) deleteUserWordProgress(ctx *gin.Context) {
	wordID, err := strconv.ParseInt(ctx.Param("word_id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid word ID format", err)
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

	arg := db.DeleteUserWordProgressParams{
		UserID: authPayload.ID,
		WordID: int32(wordID),
	}

	err = server.store.DeleteUserWordProgress(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete user word progress", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "User word progress deleted successfully", nil)
}

// listUserWordsForReviewRequest defines the query parameters for listing words due for review
type listWordsForReviewRequest struct {
	Limit int32 `form:"limit" binding:"omitempty,min=1"`
}

// WordWithProgressResponse defines the structure for a word with its progress information
// swagger:model
type WordWithProgressResponse struct {
	Word     WordProgressResponse      `json:"word"`
	Progress *UserWordProgressResponse `json:"progress,omitempty"`
}

// @Summary Get words for review
// @Description Get a list of words that are due for review for the current user
// @Tags user-word-progress
// @Accept json
// @Produce json
// @Param limit query int false "Maximum number of words to return (optional)"
// @Success 200 {object} Response{data=[]WordWithProgressResponse} "Words for review retrieved successfully"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Server error"
// @Security ApiKeyAuth
// @Router /api/v1/user-word-progress/reviews [get]
func (server *Server) getWordsForReview(ctx *gin.Context) {
	var req listWordsForReviewRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
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

	words, err := server.store.GetWordsForReview(ctx, authPayload.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve words for review", err)
		return
	}

	// Apply limit if specified
	if req.Limit > 0 && int(req.Limit) < len(words) {
		words = words[:req.Limit]
	}
	// Convert to response format
	wordsResp := make([]WordWithProgressResponse, len(words))
	for i, word := range words {
		progress := NewUserWordProgressResponse(word.UserWordProgress)
		wordsResp[i] = WordWithProgressResponse{
			Word:     NewWordProgressResponse(word.Word),
			Progress: &progress,
		}
	}

	SuccessResponse(ctx, http.StatusOK, "Words for review retrieved successfully", wordsResp)
}

// @Summary Get word with progress
// @Description Get a specific word with its progress information for the current user
// @Tags user-word-progress
// @Accept json
// @Produce json
// @Param word_id path int true "Word ID"
// @Success 200 {object} Response{data=WordWithProgressResponse} "Word with progress retrieved successfully"
// @Failure 400 {object} Response "Invalid word ID format"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 404 {object} Response "Word not found"
// @Failure 500 {object} Response "Server error"
// @Security ApiKeyAuth
// @Router /api/v1/user-word-progress/word/{word_id} [get]
func (server *Server) getWordWithProgress(ctx *gin.Context) {
	wordID, err := strconv.ParseInt(ctx.Param("word_id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid word ID format", err)
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

	arg := db.GetWordWithProgressParams{
		ID:     int32(wordID),
		UserID: authPayload.ID,
	}

	result, err := server.store.GetWordWithProgress(ctx, arg)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Word not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve word with progress", err)
		return
	}

	var progressResp *UserWordProgressResponse
	if result.UserWordProgress.UserID > 0 { // Check if progress exists
		progress := NewUserWordProgressResponse(result.UserWordProgress)
		progressResp = &progress
	}
	wordResp := WordWithProgressResponse{
		Word:     NewWordProgressResponse(result.Word),
		Progress: progressResp,
	}

	SuccessResponse(ctx, http.StatusOK, "Word with progress retrieved successfully", wordResp)
}
