package api

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/sqlc-dev/pqtype"
	"github.com/toeic-app/internal/ai"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/token"
)

// WritingPromptResponse defines the structure for writing prompt information returned to clients
type WritingPromptResponse struct {
	ID              int32     `json:"id"`
	UserID          *int32    `json:"user_id,omitempty"`
	PromptText      string    `json:"prompt_text"`
	Topic           *string   `json:"topic,omitempty"`
	DifficultyLevel *string   `json:"difficulty_level,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
}

// NewWritingPromptResponse creates a WritingPromptResponse from a db.WritingPrompt model
func NewWritingPromptResponse(prompt db.WritingPrompt) WritingPromptResponse {
	var userID *int32
	if prompt.UserID.Valid {
		userID = &prompt.UserID.Int32
	}

	var topic *string
	if prompt.Topic.Valid {
		topic = &prompt.Topic.String
	}

	var difficultyLevel *string
	if prompt.DifficultyLevel.Valid {
		difficultyLevel = &prompt.DifficultyLevel.String
	}

	return WritingPromptResponse{
		ID:              prompt.ID,
		UserID:          userID,
		PromptText:      prompt.PromptText,
		Topic:           topic,
		DifficultyLevel: difficultyLevel,
		CreatedAt:       prompt.CreatedAt,
	}
}

// UserWritingResponse defines the structure for user writing information returned to clients
// @Description Response object for user writing submissions
type UserWritingResponse struct {
	ID             int32  `json:"id"`
	UserID         int32  `json:"user_id"`
	PromptID       *int32 `json:"prompt_id,omitempty"`
	SubmissionText string `json:"submission_text"`
	// AIFeedback is a JSON object containing AI-generated feedback
	AIFeedback  json.RawMessage `json:"ai_feedback,omitempty" swaggertype:"object"`
	AIScore     *float64        `json:"ai_score,omitempty"`
	SubmittedAt time.Time       `json:"submitted_at"`
	EvaluatedAt *time.Time      `json:"evaluated_at,omitempty"`
	UpdatedAt   time.Time       `json:"updated_at"`
}

// NewUserWritingResponse creates a UserWritingResponse from a db.UserWriting model
func NewUserWritingResponse(writing db.UserWriting) UserWritingResponse {
	var promptID *int32
	if writing.PromptID.Valid {
		promptID = &writing.PromptID.Int32
	}

	var aiFeedback json.RawMessage
	if writing.AiFeedback.Valid {
		aiFeedback = writing.AiFeedback.RawMessage
	}

	var aiScore *float64
	if writing.AiScore.Valid {
		scoreStr := writing.AiScore.String
		score, err := strconv.ParseFloat(scoreStr, 64)
		if err == nil {
			aiScore = &score
		}
	}

	var evaluatedAt *time.Time
	if writing.EvaluatedAt.Valid {
		evaluatedAt = &writing.EvaluatedAt.Time
	}

	return UserWritingResponse{
		ID:             writing.ID,
		UserID:         writing.UserID,
		PromptID:       promptID,
		SubmissionText: writing.SubmissionText,
		AIFeedback:     aiFeedback,
		AIScore:        aiScore,
		SubmittedAt:    writing.SubmittedAt,
		EvaluatedAt:    evaluatedAt,
		UpdatedAt:      writing.UpdatedAt,
	}
}

// ===== Writing Prompt Handlers =====

// createWritingPromptRequest defines the structure for creating a new writing prompt
type createWritingPromptRequest struct {
	UserID          *int32  `json:"user_id,omitempty"`
	PromptText      string  `json:"prompt_text" binding:"required"`
	Topic           *string `json:"topic,omitempty"`
	DifficultyLevel *string `json:"difficulty_level,omitempty"`
}

// @Summary     Create a new writing prompt
// @Description Add a new writing prompt to the database
// @Tags        writing
// @Accept      json
// @Produce     json
// @Param       prompt body createWritingPromptRequest true "Writing prompt object to create"
// @Success     201 {object} Response{data=WritingPromptResponse} "Writing prompt created successfully"
// @Failure     400 {object} Response "Invalid request body"
// @Failure     500 {object} Response "Failed to create writing prompt"
// @Security    ApiKeyAuth
// @Router      /api/v1/writing/prompts [post]
func (server *Server) createWritingPrompt(ctx *gin.Context) {
	var req createWritingPromptRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	var userID sql.NullInt32
	if req.UserID != nil {
		userID = sql.NullInt32{
			Int32: *req.UserID,
			Valid: true,
		}
	}

	var topic sql.NullString
	if req.Topic != nil {
		topic = sql.NullString{
			String: *req.Topic,
			Valid:  true,
		}
	}

	var difficultyLevel sql.NullString
	if req.DifficultyLevel != nil {
		difficultyLevel = sql.NullString{
			String: *req.DifficultyLevel,
			Valid:  true,
		}
	}

	arg := db.CreateWritingPromptParams{
		UserID:          userID,
		PromptText:      req.PromptText,
		Topic:           topic,
		DifficultyLevel: difficultyLevel,
	}
	prompt, err := server.store.CreateWritingPrompt(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create writing prompt", err)
		return
	}

	logger.Debug("Created new writing prompt with ID: %d", prompt.ID)
	SuccessResponse(ctx, http.StatusCreated, "Writing prompt created successfully", NewWritingPromptResponse(prompt))
}

// getWritingPromptRequest defines the structure for requests to get a writing prompt by ID
type getWritingPromptRequest struct {
	ID int32 `uri:"id" binding:"required,min=1"`
}

// @Summary     Get a writing prompt by ID
// @Description Retrieve a specific writing prompt by its ID
// @Tags        writing
// @Accept      json
// @Produce     json
// @Param       id path int true "Writing Prompt ID"
// @Success     200 {object} Response{data=WritingPromptResponse} "Writing prompt retrieved successfully"
// @Failure     400 {object} Response "Invalid prompt ID"
// @Failure     404 {object} Response "Writing prompt not found"
// @Failure     500 {object} Response "Failed to retrieve writing prompt"
// @Security    ApiKeyAuth
// @Router      /api/v1/writing/prompts/{id} [get]
func (server *Server) getWritingPrompt(ctx *gin.Context) {
	var req getWritingPromptRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid prompt ID", err)
		return
	}
	prompt, err := server.store.GetWritingPrompt(ctx, req.ID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Writing prompt not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve writing prompt", err)
		return
	}

	logger.Debug("Retrieved writing prompt with ID: %d", prompt.ID)
	SuccessResponse(ctx, http.StatusOK, "Writing prompt retrieved successfully", NewWritingPromptResponse(prompt))
}

// @Summary     List all writing prompts
// @Description Get a list of all writing prompts
// @Tags        writing
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=[]WritingPromptResponse} "Writing prompts retrieved successfully"
// @Failure     500 {object} Response "Failed to retrieve writing prompts"
// @Security    ApiKeyAuth
// @Router      /api/v1/writing/prompts [get]
func (server *Server) listWritingPrompts(ctx *gin.Context) {
	prompts, err := server.store.ListWritingPrompts(ctx)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve writing prompts", err)
		return
	}

	var promptResponses []WritingPromptResponse
	for _, prompt := range prompts {
		promptResponses = append(promptResponses, NewWritingPromptResponse(prompt))
	}

	// Ensure we return an empty array instead of null if no results
	if promptResponses == nil {
		promptResponses = []WritingPromptResponse{}
	}

	logger.Debug("Retrieved %d writing prompts", len(promptResponses))
	SuccessResponse(ctx, http.StatusOK, "Writing prompts retrieved successfully", promptResponses)
}

// updateWritingPromptRequest defines the structure for updating an existing writing prompt
type updateWritingPromptRequest struct {
	PromptText      *string `json:"prompt_text,omitempty"`
	Topic           *string `json:"topic,omitempty"`
	DifficultyLevel *string `json:"difficulty_level,omitempty"`
}

// @Summary     Update a writing prompt
// @Description Update an existing writing prompt by ID
// @Tags        writing
// @Accept      json
// @Produce     json
// @Param       id path int true "Writing Prompt ID"
// @Param       prompt body updateWritingPromptRequest true "Writing prompt fields to update"
// @Success     200 {object} Response{data=WritingPromptResponse} "Writing prompt updated successfully"
// @Failure     400 {object} Response "Invalid request body or prompt ID"
// @Failure     404 {object} Response "Writing prompt not found"
// @Failure     500 {object} Response "Failed to update writing prompt"
// @Security    ApiKeyAuth
// @Router      /api/v1/writing/prompts/{id} [put]
func (server *Server) updateWritingPrompt(ctx *gin.Context) {
	promptID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid prompt ID", err)
		return
	}

	var req updateWritingPromptRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Get existing prompt to update only provided fields
	existingPrompt, err := server.store.GetWritingPrompt(ctx, int32(promptID))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Writing prompt not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve writing prompt for update", err)
		return
	}

	// Prepare update parameters
	arg := db.UpdateWritingPromptParams{
		ID:              int32(promptID),
		PromptText:      existingPrompt.PromptText,
		Topic:           existingPrompt.Topic,
		DifficultyLevel: existingPrompt.DifficultyLevel,
	}
	// Update only provided fields
	if req.PromptText != nil {
		arg.PromptText = *req.PromptText
	}
	if req.Topic != nil {
		arg.Topic = sql.NullString{
			String: *req.Topic,
			Valid:  true,
		}
	}
	if req.DifficultyLevel != nil {
		arg.DifficultyLevel = sql.NullString{
			String: *req.DifficultyLevel,
			Valid:  true,
		}
	}
	prompt, err := server.store.UpdateWritingPrompt(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update writing prompt", err)
		return
	}

	logger.Debug("Updated writing prompt with ID: %d", prompt.ID)
	SuccessResponse(ctx, http.StatusOK, "Writing prompt updated successfully", NewWritingPromptResponse(prompt))
}

// @Summary     Delete a writing prompt
// @Description Delete a specific writing prompt by its ID
// @Tags        writing
// @Accept      json
// @Produce     json
// @Param       id path int true "Writing Prompt ID"
// @Success     200 {object} Response "Writing prompt deleted successfully"
// @Failure     400 {object} Response "Invalid prompt ID"
// @Failure     500 {object} Response "Failed to delete writing prompt"
// @Security    ApiKeyAuth
// @Router      /api/v1/writing/prompts/{id} [delete]
func (server *Server) deleteWritingPrompt(ctx *gin.Context) {
	promptID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid prompt ID", err)
		return
	}
	err = server.store.DeleteWritingPrompt(ctx, int32(promptID))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete writing prompt", err)
		return
	}

	logger.Debug("Deleted writing prompt with ID: %d", promptID)
	SuccessResponse(ctx, http.StatusOK, "Writing prompt deleted successfully", nil)
}

// ===== User Writing Handlers =====

// createUserWritingRequest defines the structure for creating a new user writing submission
// @Description Request object for creating user writing submissions
type createUserWritingRequest struct {
	UserID         int32  `json:"user_id" binding:"required,min=1"`
	PromptID       *int32 `json:"prompt_id,omitempty"`
	SubmissionText string `json:"submission_text" binding:"required"`
	// AIFeedback is a JSON object containing AI-generated feedback
	AIFeedback json.RawMessage `json:"ai_feedback,omitempty" swaggertype:"object"`
	AIScore    *float64        `json:"ai_score,omitempty"`
}

// @Summary     Create a new user writing submission
// @Description Add a new user writing submission to the database
// @Tags        writing
// @Accept      json
// @Produce     json
// @Param       writing body createUserWritingRequest true "User writing submission object to create"
// @Success     201 {object} Response{data=UserWritingResponse} "User writing submission created successfully"
// @Failure     400 {object} Response "Invalid request body"
// @Failure     500 {object} Response "Failed to create user writing submission"
// @Security    ApiKeyAuth
// @Router      /api/v1/writing/submissions [post]
func (server *Server) createUserWriting(ctx *gin.Context) {
	var req createUserWritingRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	var promptID sql.NullInt32
	if req.PromptID != nil {
		promptID = sql.NullInt32{
			Int32: *req.PromptID,
			Valid: true,
		}
	}

	var aiFeedback pqtype.NullRawMessage
	if req.AIFeedback != nil {
		aiFeedback = pqtype.NullRawMessage{
			RawMessage: req.AIFeedback,
			Valid:      true,
		}
	}

	var aiScore sql.NullString
	if req.AIScore != nil {
		aiScore = sql.NullString{
			String: strconv.FormatFloat(*req.AIScore, 'f', 2, 64),
			Valid:  true,
		}
	}

	arg := db.CreateUserWritingParams{
		UserID:         req.UserID,
		PromptID:       promptID,
		SubmissionText: req.SubmissionText,
		AiFeedback:     aiFeedback,
		AiScore:        aiScore,
	}
	writing, err := server.store.CreateUserWriting(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create user writing submission", err)
		return
	}

	logger.Debug("Created user writing submission with ID: %d for user ID: %d", writing.ID, writing.UserID)
	SuccessResponse(ctx, http.StatusCreated, "User writing submission created successfully", NewUserWritingResponse(writing))
}

// getUserWritingRequest defines the structure for requests to get a user writing by ID
type getUserWritingRequest struct {
	ID int32 `uri:"id" binding:"required,min=1"`
}

// @Summary     Get a user writing submission by ID
// @Description Retrieve a specific user writing submission by its ID
// @Tags        writing
// @Accept      json
// @Produce     json
// @Param       id path int true "User Writing Submission ID"
// @Success     200 {object} Response{data=UserWritingResponse} "User writing submission retrieved successfully"
// @Failure     400 {object} Response "Invalid submission ID"
// @Failure     404 {object} Response "User writing submission not found"
// @Failure     500 {object} Response "Failed to retrieve user writing submission"
// @Security    ApiKeyAuth
// @Router      /api/v1/writing/submissions/{id} [get]
func (server *Server) getUserWriting(ctx *gin.Context) {
	var req getUserWritingRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid submission ID", err)
		return
	}
	writing, err := server.store.GetUserWriting(ctx, req.ID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "User writing submission not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve user writing submission", err)
		return
	}

	logger.Debug("Retrieved user writing submission with ID: %d", writing.ID)
	SuccessResponse(ctx, http.StatusOK, "User writing submission retrieved successfully", NewUserWritingResponse(writing))
}

// listUserWritingsByUserIDRequest defines the structure for listing user writings by user ID
type listUserWritingsByUserIDRequest struct {
	UserID int32 `uri:"user_id" binding:"required,min=1"`
}

// @Summary     List user writing submissions by user ID
// @Description Get a list of all writing submissions for a specific user
// @Tags        writing
// @Accept      json
// @Produce     json
// @Param       user_id path int true "User ID"
// @Success     200 {object} Response{data=[]UserWritingResponse} "User writing submissions retrieved successfully"
// @Failure     400 {object} Response "Invalid user ID"
// @Failure     500 {object} Response "Failed to retrieve user writing submissions"
// @Security    ApiKeyAuth
// @Router      /api/v1/writing/users/{user_id}/submissions [get]
func (server *Server) listUserWritingsByUserID(ctx *gin.Context) {
	var req listUserWritingsByUserIDRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
		return
	}

	writings, err := server.store.ListUserWritingsByUserID(ctx, req.UserID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve user writing submissions", err)
		return
	}
	var writingResponses []UserWritingResponse
	for _, writing := range writings {
		writingResponses = append(writingResponses, NewUserWritingResponse(writing))
	}

	// Ensure we return an empty array instead of null if no results
	if writingResponses == nil {
		writingResponses = []UserWritingResponse{}
	}

	logger.Debug("Retrieved %d writing submissions for user ID: %d", len(writingResponses), req.UserID)
	SuccessResponse(ctx, http.StatusOK, "User writing submissions retrieved successfully", writingResponses)
}

// listUserWritingsByPromptIDRequest defines the structure for listing user writings by prompt ID
type listUserWritingsByPromptIDRequest struct {
	PromptID int32 `uri:"prompt_id" binding:"required,min=1"`
}

// @Summary     List user writing submissions by prompt ID
// @Description Get a list of all writing submissions for a specific prompt
// @Tags        writing
// @Accept      json
// @Produce     json
// @Param       prompt_id path int true "Prompt ID"
// @Success     200 {object} Response{data=[]UserWritingResponse} "User writing submissions retrieved successfully"
// @Failure     400 {object} Response "Invalid prompt ID"
// @Failure     500 {object} Response "Failed to retrieve user writing submissions"
// @Security    ApiKeyAuth
// @Router      /api/v1/writing/prompt-submissions/{prompt_id} [get]
func (server *Server) listUserWritingsByPromptID(ctx *gin.Context) {
	var req listUserWritingsByPromptIDRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid prompt ID", err)
		return
	}

	// Create NullInt32 for the query
	promptID := sql.NullInt32{
		Int32: req.PromptID,
		Valid: true,
	}

	writings, err := server.store.ListUserWritingsByPromptID(ctx, promptID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve user writing submissions", err)
		return
	}
	var writingResponses []UserWritingResponse
	for _, writing := range writings {
		writingResponses = append(writingResponses, NewUserWritingResponse(writing))
	}

	// Ensure we return an empty array instead of null if no results
	if writingResponses == nil {
		writingResponses = []UserWritingResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "User writing submissions retrieved successfully", writingResponses)
}

// updateUserWritingRequest defines the structure for updating an existing user writing submission
// @Description Request object for updating user writing submissions
type updateUserWritingRequest struct {
	SubmissionText *string `json:"submission_text,omitempty"`
	// AIFeedback is a JSON object containing AI-generated feedback
	AIFeedback  json.RawMessage `json:"ai_feedback,omitempty" swaggertype:"object"`
	AIScore     *float64        `json:"ai_score,omitempty"`
	EvaluatedAt *time.Time      `json:"evaluated_at,omitempty"`
}

// @Summary     Update a user writing submission
// @Description Update an existing user writing submission by ID
// @Tags        writing
// @Accept      json
// @Produce     json
// @Param       id path int true "User Writing Submission ID"
// @Param       writing body updateUserWritingRequest true "User writing submission fields to update"
// @Success     200 {object} Response{data=UserWritingResponse} "User writing submission updated successfully"
// @Failure     400 {object} Response "Invalid request body or submission ID"
// @Failure     404 {object} Response "User writing submission not found"
// @Failure     500 {object} Response "Failed to update user writing submission"
// @Security    ApiKeyAuth
// @Router      /api/v1/writing/submissions/{id} [put]
func (server *Server) updateUserWriting(ctx *gin.Context) {
	writingID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid submission ID", err)
		return
	}

	var req updateUserWritingRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Get existing writing to update only provided fields
	existingWriting, err := server.store.GetUserWriting(ctx, int32(writingID))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "User writing submission not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve user writing submission for update", err)
		return
	}
	// Prepare update parameters
	submissionText := existingWriting.SubmissionText
	if req.SubmissionText != nil {
		submissionText = *req.SubmissionText
	}

	aiFeedback := existingWriting.AiFeedback
	if req.AIFeedback != nil {
		aiFeedback = pqtype.NullRawMessage{
			RawMessage: req.AIFeedback,
			Valid:      true,
		}
	}

	aiScore := existingWriting.AiScore
	if req.AIScore != nil {
		aiScore = sql.NullString{
			String: strconv.FormatFloat(*req.AIScore, 'f', 2, 64),
			Valid:  true,
		}
	}

	evaluatedAt := existingWriting.EvaluatedAt
	if req.EvaluatedAt != nil {
		evaluatedAt = sql.NullTime{
			Time:  *req.EvaluatedAt,
			Valid: true,
		}
	}

	arg := db.UpdateUserWritingParams{
		ID:             int32(writingID),
		SubmissionText: submissionText,
		AiFeedback:     aiFeedback,
		AiScore:        aiScore,
		EvaluatedAt:    evaluatedAt,
	}

	writing, err := server.store.UpdateUserWriting(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update user writing submission", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "User writing submission updated successfully", NewUserWritingResponse(writing))
}

// @Summary     Delete a user writing submission
// @Description Delete a specific user writing submission by its ID
// @Tags        writing
// @Accept      json
// @Produce     json
// @Param       id path int true "User Writing Submission ID"
// @Success     200 {object} Response "User writing submission deleted successfully"
// @Failure     400 {object} Response "Invalid submission ID"
// @Failure     500 {object} Response "Failed to delete user writing submission"
// @Security    ApiKeyAuth
// @Router      /api/v1/writing/submissions/{id} [delete]
func (server *Server) deleteUserWriting(ctx *gin.Context) {
	writingID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid submission ID", err)
		return
	}

	err = server.store.DeleteUserWriting(ctx, int32(writingID))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete user writing submission", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "User writing submission deleted successfully", nil)
}

// scoreWritingRequest defines the structure for AI scoring request
type scoreWritingRequest struct {
	SubmissionID *int32 `json:"submission_id,omitempty"` // If provided, update this submission
	Text         string `json:"text"`                    // Text to score (required if no submission_id)
}

// scoreWritingResponse defines the response structure for AI scoring
type scoreWritingResponse struct {
	UserID      int32                  `json:"user_id"`
	Score       int                    `json:"score"`       // 0-200 TOEIC writing score
	Band        string                 `json:"band"`        // TOEIC band level
	Feedback    map[string]interface{} `json:"feedback"`    // Detailed feedback
	Suggestions []string               `json:"suggestions"` // Improvement suggestions
	Confidence  float64                `json:"confidence"`  // AI confidence score (0-1)
	ProcessedAt string                 `json:"processed_at"`
	Text        string                 `json:"text"`
	PromptID    *int32                 `json:"prompt_id,omitempty"`
}

// @Summary Score writing submission using AI
// @Description Score a writing submission using AI to get TOEIC band assessment and detailed feedback. If submission_id is provided, the submission will be updated with AI scores.
// @Tags writing
// @Accept json
// @Produce json
// @Param request body scoreWritingRequest true "Writing scoring request"
// @Success 200 {object} Response{data=scoreWritingResponse} "Writing scored successfully"
// @Failure 400 {object} Response "Invalid request parameters"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 503 {object} Response "AI scoring service unavailable"
// @Failure 500 {object} Response "Server error"
// @Security ApiKeyAuth
// @Router /api/v1/writing/score [post]
func (server *Server) scoreWriting(ctx *gin.Context) {
	var req scoreWritingRequest
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

	var textToScore string
	var existingSubmission *db.UserWriting
	var promptID *int32

	// If submission_id is provided, get the submission and check if it already has AI scores
	if req.SubmissionID != nil {
		submission, err := server.store.GetUserWriting(ctx, *req.SubmissionID)
		if err != nil {
			if err == sql.ErrNoRows {
				ErrorResponse(ctx, http.StatusNotFound, "Writing submission not found", err)
				return
			}
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve writing submission", err)
			return
		}

		// Check if user owns this submission
		if submission.UserID != authPayload.ID {
			ErrorResponse(ctx, http.StatusForbidden, "You can only score your own submissions", nil)
			return
		}

		existingSubmission = &submission
		textToScore = submission.SubmissionText

		// Get prompt ID if available
		if submission.PromptID.Valid {
			promptID = &submission.PromptID.Int32
		}

		// Check if this submission already has AI scores - if yes, return cached result
		if submission.AiScore.Valid && submission.AiFeedback.Valid {
			logger.Info("Returning cached AI score for submission %d", *req.SubmissionID)

			// Parse existing feedback
			var feedbackMap map[string]interface{}
			if err := json.Unmarshal(submission.AiFeedback.RawMessage, &feedbackMap); err != nil {
				logger.Warn("Failed to parse existing AI feedback, regenerating score: %v", err)
			} else {
				// Return cached result
				aiScore, _ := strconv.ParseFloat(submission.AiScore.String, 64)
				response := scoreWritingResponse{
					UserID:      authPayload.ID,
					Score:       int(aiScore),
					Band:        string(ai.BandLevel1), // You might want to store band separately
					Feedback:    feedbackMap,
					Suggestions: []string{}, // Extract from feedback if needed
					Confidence:  0.9,        // High confidence for cached results
					ProcessedAt: submission.EvaluatedAt.Time.Format(time.RFC3339),
					Text:        textToScore,
				}

				SuccessResponse(ctx, http.StatusOK, "Cached AI score retrieved", response)
				return
			}
		}
	} else {
		// If no submission_id, use the provided text
		if req.Text == "" {
			ErrorResponse(ctx, http.StatusBadRequest, "Either submission_id or text must be provided", nil)
			return
		}
		textToScore = req.Text
	}

	// Check if AI scoring service is available
	if server.aiScoringService == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "AI scoring service not available", nil)
		return
	}

	if !server.aiScoringService.IsHealthy() {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "AI scoring service is not healthy", nil)
		return
	}

	// Create AI scoring request
	aiReq := ai.AIScoreRequest{
		Text:     textToScore,
		PromptID: promptID,
		UserID:   authPayload.ID,
	}

	// Score the writing using AI
	aiResponse, err := server.aiScoringService.ScoreWriting(ctx, aiReq)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to score writing", err)
		return
	}

	// Convert feedback to map for JSON response
	feedbackMap := map[string]interface{}{
		"grammar":       aiResponse.Feedback.Grammar,
		"vocabulary":    aiResponse.Feedback.Vocabulary,
		"organization":  aiResponse.Feedback.Organization,
		"development":   aiResponse.Feedback.Development,
		"task_response": aiResponse.Feedback.TaskResponse,
		"language_use":  aiResponse.Feedback.LanguageUse,
		"overall":       aiResponse.Feedback.Overall,
	}

	response := scoreWritingResponse{
		UserID:      authPayload.ID,
		Score:       aiResponse.Score,
		Band:        string(aiResponse.Band),
		Feedback:    feedbackMap,
		Suggestions: aiResponse.Suggestions,
		Confidence:  aiResponse.Confidence,
		ProcessedAt: aiResponse.ProcessedAt.Format(time.RFC3339),
		Text:        textToScore,
	}

	// If submission ID is provided, update the submission with AI score immediately
	if req.SubmissionID != nil && existingSubmission != nil {
		aiFeedbackJSON, _ := json.Marshal(feedbackMap)
		aiScore := float64(aiResponse.Score)
		evaluatedAt := time.Now()

		updateParams := db.UpdateUserWritingParams{
			ID:             *req.SubmissionID,
			SubmissionText: existingSubmission.SubmissionText, // Keep existing text
			AiFeedback: pqtype.NullRawMessage{
				RawMessage: aiFeedbackJSON,
				Valid:      true,
			},
			AiScore: sql.NullString{
				String: strconv.FormatFloat(aiScore, 'f', 2, 64),
				Valid:  true,
			},
			EvaluatedAt: sql.NullTime{
				Time:  evaluatedAt,
				Valid: true,
			},
		}

		if _, err := server.store.UpdateUserWriting(ctx, updateParams); err != nil {
			logger.Error("Failed to update writing submission %d with AI score: %v", *req.SubmissionID, err)
			// Continue anyway and return the score, but log the error
		} else {
			logger.Info("Updated writing submission %d with AI score %d", *req.SubmissionID, aiResponse.Score)
		}
	}

	logger.Info("Scored writing for user %d: Score=%d, Band=%s", authPayload.ID, aiResponse.Score, aiResponse.Band)
	SuccessResponse(ctx, http.StatusOK, "Writing scored successfully", response)
}
