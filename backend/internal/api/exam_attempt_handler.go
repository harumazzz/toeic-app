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

// ExamAttemptResponse defines the structure for exam attempt information returned to clients
type ExamAttemptResponse struct {
	AttemptID int32             `json:"attempt_id"`
	UserID    int32             `json:"user_id"`
	ExamID    int32             `json:"exam_id"`
	StartTime time.Time         `json:"start_time"`
	EndTime   *time.Time        `json:"end_time,omitempty"`
	Score     *string           `json:"score,omitempty"` // Using string for NUMERIC precision
	Status    db.ExamStatusEnum `json:"status"`
	CreatedAt time.Time         `json:"created_at"`
	UpdatedAt time.Time         `json:"updated_at"`
}

// ExamAttemptStatsResponse provides statistics about user's exam attempts
type ExamAttemptStatsResponse struct {
	TotalAttempts      int64   `json:"total_attempts"`
	CompletedAttempts  int64   `json:"completed_attempts"`
	InProgressAttempts int64   `json:"in_progress_attempts"`
	AbandonedAttempts  int64   `json:"abandoned_attempts"`
	AverageScore       *string `json:"average_score,omitempty"`
	HighestScore       *string `json:"highest_score,omitempty"`
	LowestScore        *string `json:"lowest_score,omitempty"`
}

// LeaderboardEntry represents a leaderboard entry
type LeaderboardEntry struct {
	UserID   int32     `json:"user_id"`
	Username string    `json:"username"`
	Score    string    `json:"score"`
	EndTime  time.Time `json:"end_time"`
	Rank     int64     `json:"rank"`
}

// NewExamAttemptResponse creates an ExamAttemptResponse from a db.ExamAttempt model
func NewExamAttemptResponse(attempt db.ExamAttempt) ExamAttemptResponse {
	response := ExamAttemptResponse{
		AttemptID: attempt.AttemptID,
		UserID:    attempt.UserID,
		ExamID:    attempt.ExamID,
		StartTime: attempt.StartTime,
		Status:    attempt.Status,
		CreatedAt: attempt.CreatedAt,
		UpdatedAt: attempt.UpdatedAt,
	}

	if attempt.EndTime.Valid {
		response.EndTime = &attempt.EndTime.Time
	}

	if attempt.Score.Valid {
		scoreStr := attempt.Score.String
		response.Score = &scoreStr
	}

	return response
}

// createExamAttemptRequest defines the structure for creating a new exam attempt
type createExamAttemptRequest struct {
	ExamID int32 `json:"exam_id" binding:"required,min=1"`
}

// updateExamAttemptRequest defines the structure for updating an exam attempt
type updateExamAttemptRequest struct {
	Status *string `json:"status,omitempty"`
	Score  *string `json:"score,omitempty"`
}

// getExamAttemptRequest defines the structure for getting an exam attempt by ID
type getExamAttemptRequest struct {
	AttemptID int32 `uri:"id" binding:"required,min=1"`
}

// listExamAttemptsRequest defines the structure for listing exam attempts with pagination
type listExamAttemptsRequest struct {
	Limit  int32 `form:"limit" binding:"min=1,max=100"`
	Offset int32 `form:"offset" binding:"min=0"`
}

// listLeaderboardRequest defines the structure for leaderboard pagination
type listLeaderboardRequest struct {
	Limit  int32 `form:"limit" binding:"min=1,max=100"`
	Offset int32 `form:"offset" binding:"min=0"`
}

// completeExamAttemptRequest defines the structure for completing an exam attempt
type completeExamAttemptRequest struct {
	Score string `json:"score" binding:"required"`
}

// @Summary     Start a new exam attempt
// @Description Create a new exam attempt for the authenticated user
// @Tags        exam-attempts
// @Accept      json
// @Produce     json
// @Param       attempt body createExamAttemptRequest true "Exam attempt to create"
// @Success     201 {object} Response{data=ExamAttemptResponse} "Exam attempt started successfully"
// @Failure     400 {object} Response "Invalid request body"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     404 {object} Response "Exam not found"
// @Failure     409 {object} Response "User already has an active attempt for this exam"
// @Failure     500 {object} Response "Failed to create exam attempt"
// @Security    ApiKeyAuth
// @Router      /api/v1/exam-attempts [post]
func (server *Server) createExamAttempt(ctx *gin.Context) {
	var req createExamAttemptRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_request_body", err)
		return
	}

	// Get user from authorization
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ErrorResponse(ctx, http.StatusUnauthorized, "authorization_payload_not_found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusUnauthorized, "invalid_authorization_payload", nil)
		return
	}

	// Check if exam exists
	_, err := server.store.GetExam(ctx, req.ExamID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "exam_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_exam", err)
		return
	}

	// Check if user already has an active attempt for this exam
	activeAttempt, err := server.store.GetActiveExamAttempt(ctx, db.GetActiveExamAttemptParams{
		UserID: authPayload.ID,
		ExamID: req.ExamID,
	})
	if err == nil {
		// User already has an active attempt - return conflict with attempt ID in message
		message := fmt.Sprintf("User already has active attempt with ID: %d", activeAttempt.AttemptID)
		ErrorResponseWithMessage(ctx, http.StatusConflict, message, nil)
		return
	} else if err != sql.ErrNoRows {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_check_active_attempt", err)
		return
	}

	// Create the exam attempt
	arg := db.CreateExamAttemptParams{
		UserID:    authPayload.ID,
		ExamID:    req.ExamID,
		StartTime: time.Now(),
		Status:    db.ExamStatusEnumInProgress,
	}

	attempt, err := server.store.CreateExamAttempt(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_create_exam_attempt", err)
		return
	}

	// Clear user cache for exam attempts
	if server.serviceCache != nil {
		go func() {
			server.ClearUserCache(int64(authPayload.ID))
		}()
	}

	response := NewExamAttemptResponse(attempt)
	SuccessResponse(ctx, http.StatusCreated, "exam_attempt_created_successfully", response)
}

// @Summary     Get an exam attempt by ID
// @Description Retrieve a specific exam attempt by its ID (user can only access their own attempts)
// @Tags        exam-attempts
// @Accept      json
// @Produce     json
// @Param       id path int true "Exam Attempt ID"
// @Success     200 {object} Response{data=ExamAttemptResponse} "Exam attempt retrieved successfully"
// @Failure     400 {object} Response "Invalid attempt ID"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     403 {object} Response "Access denied - not your exam attempt"
// @Failure     404 {object} Response "Exam attempt not found"
// @Failure     500 {object} Response "Failed to retrieve exam attempt"
// @Security    ApiKeyAuth
// @Router      /api/v1/exam-attempts/{id} [get]
func (server *Server) getExamAttempt(ctx *gin.Context) {
	var req getExamAttemptRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_attempt_id", err)
		return
	}

	// Get user from authorization
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ErrorResponse(ctx, http.StatusUnauthorized, "authorization_payload_not_found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusUnauthorized, "invalid_authorization_payload", nil)
		return
	}

	// Get exam attempt and verify ownership
	attempt, err := server.store.GetExamAttemptByUser(ctx, db.GetExamAttemptByUserParams{
		AttemptID: req.AttemptID,
		UserID:    authPayload.ID,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "exam_attempt_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_exam_attempt", err)
		return
	}

	response := NewExamAttemptResponse(attempt)
	SuccessResponse(ctx, http.StatusOK, "exam_attempt_retrieved_successfully", response)
}

// @Summary     List user's exam attempts
// @Description Get a list of exam attempts for the authenticated user
// @Tags        exam-attempts
// @Accept      json
// @Produce     json
// @Param       limit query int false "Limit" default(10)
// @Param       offset query int false "Offset" default(0)
// @Success     200 {object} Response{data=[]ExamAttemptResponse} "Exam attempts retrieved successfully"
// @Failure     400 {object} Response "Invalid query parameters"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     500 {object} Response "Failed to retrieve exam attempts"
// @Security    ApiKeyAuth
// @Router      /api/v1/exam-attempts [get]
func (server *Server) listUserExamAttempts(ctx *gin.Context) {
	// Parse pagination parameters from query
	var req listExamAttemptsRequest
	req.Limit = 10 // Default limit
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_query_parameters", err)
		return
	}

	// Get user from authorization
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ErrorResponse(ctx, http.StatusUnauthorized, "authorization_payload_not_found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusUnauthorized, "invalid_authorization_payload", nil)
		return
	}

	// Check cache first
	cacheKey := fmt.Sprintf("user:exam_attempts:%d:%d:%d", authPayload.ID, req.Limit, req.Offset)
	if server.serviceCache != nil {
		var cachedAttempts []ExamAttemptResponse
		if err := server.serviceCache.Get(ctx, cacheKey, &cachedAttempts); err == nil {
			SuccessResponse(ctx, http.StatusOK, "exam_attempts_retrieved_successfully", cachedAttempts)
			return
		}
	}

	attempts, err := server.store.ListExamAttemptsByUser(ctx, db.ListExamAttemptsByUserParams{
		UserID: authPayload.ID,
		Limit:  req.Limit,
		Offset: req.Offset,
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_exam_attempts", err)
		return
	}

	response := make([]ExamAttemptResponse, len(attempts))
	for i, attempt := range attempts {
		response[i] = NewExamAttemptResponse(attempt)
	}

	// Cache the results
	if server.serviceCache != nil {
		go func() {
			server.serviceCache.Set(ctx, cacheKey, response, 5*time.Minute)
		}()
	}

	SuccessResponse(ctx, http.StatusOK, "exam_attempts_retrieved_successfully", response)
}

// @Summary     Update exam attempt status
// @Description Update the status or score of an exam attempt
// @Tags        exam-attempts
// @Accept      json
// @Produce     json
// @Param       id path int true "Exam Attempt ID"
// @Param       update body updateExamAttemptRequest true "Update data"
// @Success     200 {object} Response{data=ExamAttemptResponse} "Exam attempt updated successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     403 {object} Response "Access denied - not your exam attempt"
// @Failure     404 {object} Response "Exam attempt not found"
// @Failure     500 {object} Response "Failed to update exam attempt"
// @Security    ApiKeyAuth
// @Router      /api/v1/exam-attempts/{id} [put]
func (server *Server) updateExamAttempt(ctx *gin.Context) {
	var req getExamAttemptRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_attempt_id", err)
		return
	}

	var updateReq updateExamAttemptRequest
	if err := ctx.ShouldBindJSON(&updateReq); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_request_body", err)
		return
	}

	// Get user from authorization
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ErrorResponse(ctx, http.StatusUnauthorized, "authorization_payload_not_found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusUnauthorized, "invalid_authorization_payload", nil)
		return
	}

	// Verify ownership first
	_, err := server.store.GetExamAttemptByUser(ctx, db.GetExamAttemptByUserParams{
		AttemptID: req.AttemptID,
		UserID:    authPayload.ID,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "exam_attempt_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_exam_attempt", err)
		return
	}

	var updatedAttempt db.ExamAttempt

	// Handle different update operations
	if updateReq.Score != nil {
		// Update score (this will also complete the attempt)
		scoreValue := sql.NullString{String: *updateReq.Score, Valid: true}
		updatedAttempt, err = server.store.UpdateExamAttemptScore(ctx, db.UpdateExamAttemptScoreParams{
			AttemptID: req.AttemptID,
			Score:     scoreValue,
		})
	} else if updateReq.Status != nil {
		// Update status only
		var statusEnum db.ExamStatusEnum
		switch *updateReq.Status {
		case "in_progress":
			statusEnum = db.ExamStatusEnumInProgress
		case "completed":
			statusEnum = db.ExamStatusEnumCompleted
		case "abandoned":
			statusEnum = db.ExamStatusEnumAbandoned
		default:
			ErrorResponse(ctx, http.StatusBadRequest, "invalid_status_value", nil)
			return
		}

		updatedAttempt, err = server.store.UpdateExamAttemptStatus(ctx, db.UpdateExamAttemptStatusParams{
			AttemptID: req.AttemptID,
			Status:    statusEnum,
		})
	} else {
		ErrorResponse(ctx, http.StatusBadRequest, "no_update_fields_provided", nil)
		return
	}

	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_update_exam_attempt", err)
		return
	}

	// Clear user cache
	if server.serviceCache != nil {
		go func() {
			server.ClearUserCache(int64(authPayload.ID))
		}()
	}

	response := NewExamAttemptResponse(updatedAttempt)
	SuccessResponse(ctx, http.StatusOK, "exam_attempt_updated_successfully", response)
}

// @Summary     Complete exam attempt
// @Description Complete an exam attempt with final score
// @Tags        exam-attempts
// @Accept      json
// @Produce     json
// @Param       id path int true "Exam Attempt ID"
// @Param       request body completeExamAttemptRequest true "Complete exam attempt request"
// @Success     200 {object} Response{data=ExamAttemptResponse} "Exam attempt completed successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     404 {object} Response "Exam attempt not found"
// @Failure     500 {object} Response "Failed to complete exam attempt"
// @Security    ApiKeyAuth
// @Router      /api/v1/exam-attempts/{id}/complete [post]
func (server *Server) completeExamAttempt(ctx *gin.Context) {
	var req getExamAttemptRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_attempt_id", err)
		return
	}

	var scoreReq completeExamAttemptRequest
	if err := ctx.ShouldBindJSON(&scoreReq); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_request_body", err)
		return
	}

	// Get user from authorization
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ErrorResponse(ctx, http.StatusUnauthorized, "authorization_payload_not_found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusUnauthorized, "invalid_authorization_payload", nil)
		return
	}

	// Verify ownership
	_, err := server.store.GetExamAttemptByUser(ctx, db.GetExamAttemptByUserParams{
		AttemptID: req.AttemptID,
		UserID:    authPayload.ID,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "exam_attempt_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_exam_attempt", err)
		return
	}

	// Complete the attempt
	scoreValue := sql.NullString{String: scoreReq.Score, Valid: true}
	updatedAttempt, err := server.store.CompleteExamAttempt(ctx, db.CompleteExamAttemptParams{
		AttemptID: req.AttemptID,
		Score:     scoreValue,
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_complete_exam_attempt", err)
		return
	}

	// Clear user cache
	if server.serviceCache != nil {
		go func() {
			server.ClearUserCache(int64(authPayload.ID))
		}()
	}

	response := NewExamAttemptResponse(updatedAttempt)
	SuccessResponse(ctx, http.StatusOK, "exam_attempt_completed_successfully", response)
}

// @Summary     Abandon exam attempt
// @Description Abandon an active exam attempt
// @Tags        exam-attempts
// @Accept      json
// @Produce     json
// @Param       id path int true "Exam Attempt ID"
// @Success     200 {object} Response{data=ExamAttemptResponse} "Exam attempt abandoned successfully"
// @Failure     400 {object} Response "Invalid attempt ID"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     404 {object} Response "Exam attempt not found"
// @Failure     500 {object} Response "Failed to abandon exam attempt"
// @Security    ApiKeyAuth
// @Router      /api/v1/exam-attempts/{id}/abandon [post]
func (server *Server) abandonExamAttempt(ctx *gin.Context) {
	var req getExamAttemptRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_attempt_id", err)
		return
	}

	// Get user from authorization
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ErrorResponse(ctx, http.StatusUnauthorized, "authorization_payload_not_found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusUnauthorized, "invalid_authorization_payload", nil)
		return
	}

	// Verify ownership
	_, err := server.store.GetExamAttemptByUser(ctx, db.GetExamAttemptByUserParams{
		AttemptID: req.AttemptID,
		UserID:    authPayload.ID,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "exam_attempt_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_exam_attempt", err)
		return
	}

	// Abandon the attempt
	updatedAttempt, err := server.store.AbandonExamAttempt(ctx, req.AttemptID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_abandon_exam_attempt", err)
		return
	}

	// Clear user cache
	if server.serviceCache != nil {
		go func() {
			server.ClearUserCache(int64(authPayload.ID))
		}()
	}

	response := NewExamAttemptResponse(updatedAttempt)
	SuccessResponse(ctx, http.StatusOK, "exam_attempt_abandoned_successfully", response)
}

// @Summary     Get exam attempt statistics
// @Description Get statistics about user's exam attempts
// @Tags        exam-attempts
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=ExamAttemptStatsResponse} "Statistics retrieved successfully"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     500 {object} Response "Failed to retrieve statistics"
// @Security    ApiKeyAuth
// @Router      /api/v1/exam-attempts/stats [get]
func (server *Server) getExamAttemptStats(ctx *gin.Context) {
	// Get user from authorization
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ErrorResponse(ctx, http.StatusUnauthorized, "authorization_payload_not_found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusUnauthorized, "invalid_authorization_payload", nil)
		return
	}

	// Check cache first
	cacheKey := fmt.Sprintf("user:exam_attempt_stats:%d", authPayload.ID)
	if server.serviceCache != nil {
		var cachedStats ExamAttemptStatsResponse
		if err := server.serviceCache.Get(ctx, cacheKey, &cachedStats); err == nil {
			SuccessResponse(ctx, http.StatusOK, "exam_attempt_stats_retrieved_successfully", cachedStats)
			return
		}
	}

	stats, err := server.store.GetExamAttemptStats(ctx, authPayload.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_exam_attempt_stats", err)
		return
	}

	response := ExamAttemptStatsResponse{
		TotalAttempts:      stats.TotalAttempts,
		CompletedAttempts:  stats.CompletedAttempts,
		InProgressAttempts: stats.InProgressAttempts,
		AbandonedAttempts:  stats.AbandonedAttempts,
	}

	// Handle nullable scores by checking for a sentinel value (e.g., -1 means no score)
	if stats.AverageScore != -1 {
		avgScore := fmt.Sprintf("%.2f", stats.AverageScore)
		response.AverageScore = &avgScore
	}

	if stats.HighestScore != -1 {
		highScore := fmt.Sprintf("%.2f", stats.HighestScore)
		response.HighestScore = &highScore
	}

	if stats.LowestScore != -1 {
		lowScore := fmt.Sprintf("%.2f", stats.LowestScore)
		response.LowestScore = &lowScore
	}

	// Cache the results
	if server.serviceCache != nil {
		go func() {
			server.serviceCache.Set(ctx, cacheKey, response, 10*time.Minute)
		}()
	}

	SuccessResponse(ctx, http.StatusOK, "exam_attempt_stats_retrieved_successfully", response)
}

// @Summary     Get exam leaderboard
// @Description Get the leaderboard for a specific exam
// @Tags        exam-attempts
// @Accept      json
// @Produce     json
// @Param       id path int true "Exam ID"
// @Param       limit query int false "Limit" default(10)
// @Param       offset query int false "Offset" default(0)
// @Success     200 {object} Response{data=[]LeaderboardEntry} "Leaderboard retrieved successfully"
// @Failure     400 {object} Response "Invalid parameters"
// @Failure     404 {object} Response "Exam not found"
// @Failure     500 {object} Response "Failed to retrieve leaderboard"
// @Security    ApiKeyAuth
// @Router      /api/v1/exams/{id}/leaderboard [get]
func (server *Server) getExamLeaderboard(ctx *gin.Context) {
	examID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_exam_id", err)
		return
	}

	// Parse pagination parameters
	var req listLeaderboardRequest
	req.Limit = 10 // Default limit
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_query_parameters", err)
		return
	}

	// Check if exam exists
	_, err = server.store.GetExam(ctx, int32(examID))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "exam_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_exam", err)
		return
	}

	// Check cache first
	cacheKey := fmt.Sprintf("exam:leaderboard:%d:%d:%d", examID, req.Limit, req.Offset)
	if server.serviceCache != nil {
		var cachedLeaderboard []LeaderboardEntry
		if err := server.serviceCache.Get(ctx, cacheKey, &cachedLeaderboard); err == nil {
			SuccessResponse(ctx, http.StatusOK, "exam_leaderboard_retrieved_successfully", cachedLeaderboard)
			return
		}
	}

	leaderboard, err := server.store.GetExamLeaderboard(ctx, db.GetExamLeaderboardParams{
		ExamID: int32(examID),
		Limit:  req.Limit,
		Offset: req.Offset,
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_exam_leaderboard", err)
		return
	}

	response := make([]LeaderboardEntry, len(leaderboard))
	for i, entry := range leaderboard {
		var endTime time.Time
		if entry.EndTime.Valid {
			endTime = entry.EndTime.Time
		}

		var score string
		if entry.Score.Valid {
			score = entry.Score.String
		}

		response[i] = LeaderboardEntry{
			UserID:   entry.UserID,
			Username: entry.Username,
			Score:    score,
			EndTime:  endTime,
			Rank:     entry.Rank,
		}
	}

	// Cache the results
	if server.serviceCache != nil {
		go func() {
			server.serviceCache.Set(ctx, cacheKey, response, 30*time.Minute)
		}()
	}

	SuccessResponse(ctx, http.StatusOK, "exam_leaderboard_retrieved_successfully", response)
}

// @Summary     Delete an exam attempt
// @Description Delete an exam attempt (admin only or own incomplete attempts)
// @Tags        exam-attempts
// @Accept      json
// @Produce     json
// @Param       id path int true "Exam Attempt ID"
// @Success     200 {object} Response "Exam attempt deleted successfully"
// @Failure     400 {object} Response "Invalid attempt ID"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     403 {object} Response "Access denied"
// @Failure     404 {object} Response "Exam attempt not found"
// @Failure     500 {object} Response "Failed to delete exam attempt"
// @Security    ApiKeyAuth
// @Router      /api/v1/exam-attempts/{id} [delete]
func (server *Server) deleteExamAttempt(ctx *gin.Context) {
	var req getExamAttemptRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_attempt_id", err)
		return
	}

	// Get user from authorization
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ErrorResponse(ctx, http.StatusUnauthorized, "authorization_payload_not_found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusUnauthorized, "invalid_authorization_payload", nil)
		return
	}

	// Check if user is admin or if it's their own attempt
	isAdmin, err := server.IsUserAdmin(ctx, authPayload.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_check_admin_status", err)
		return
	}

	if !isAdmin {
		// Non-admin users can only delete their own incomplete attempts
		attempt, err := server.store.GetExamAttemptByUser(ctx, db.GetExamAttemptByUserParams{
			AttemptID: req.AttemptID,
			UserID:    authPayload.ID,
		})
		if err != nil {
			if err == sql.ErrNoRows {
				ErrorResponse(ctx, http.StatusNotFound, "exam_attempt_not_found", err)
				return
			}
			ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_exam_attempt", err)
			return
		}

		// Only allow deletion of in-progress attempts
		if attempt.Status != db.ExamStatusEnumInProgress {
			ErrorResponse(ctx, http.StatusForbidden, "cannot_delete_completed_attempt", nil)
			return
		}
	}

	// Delete the exam attempt (this will cascade to user_answers)
	err = server.store.DeleteExamAttempt(ctx, req.AttemptID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_delete_exam_attempt", err)
		return
	}

	// Clear user cache
	if server.serviceCache != nil {
		go func() {
			server.ClearUserCache(int64(authPayload.ID))
		}()
	}

	logger.Info("Exam attempt %d deleted by user %d", req.AttemptID, authPayload.ID)
	SuccessResponse(ctx, http.StatusOK, "exam_attempt_deleted_successfully", nil)
}
