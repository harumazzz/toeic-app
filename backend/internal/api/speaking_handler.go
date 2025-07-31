package api

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/sqlc-dev/pqtype"
	"github.com/toeic-app/internal/ai"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/logger"
)

// CustomTime wraps time.Time to handle flexible datetime parsing
type CustomTime struct {
	time.Time
}

// UnmarshalJSON implements json.Unmarshaler interface for flexible datetime parsing
func (ct *CustomTime) UnmarshalJSON(data []byte) error {
	// Remove quotes from JSON string
	s := strings.Trim(string(data), "\"")
	
	// List of time formats to try
	formats := []string{
		time.RFC3339,           // "2006-01-02T15:04:05Z07:00"
		time.RFC3339Nano,       // "2006-01-02T15:04:05.999999999Z07:00"
		"2006-01-02T15:04:05",  // Without timezone
		"2006-01-02T15:04:05.999999", // With microseconds, without timezone
		"2006-01-02T15:04:05.999999999", // With nanoseconds, without timezone
	}
	
	var err error
	for _, format := range formats {
		ct.Time, err = time.Parse(format, s)
		if err == nil {
			// If parsed successfully but no timezone info, assume UTC
			if ct.Time.Location() == time.UTC && !strings.Contains(s, "Z") && !strings.Contains(s, "+") && !strings.Contains(s, "-") {
				// Only for formats without timezone info
				if !strings.Contains(format, "Z") && !strings.Contains(format, "07:00") {
					ct.Time = ct.Time.UTC()
				}
			}
			return nil
		}
	}
	
	return fmt.Errorf("unable to parse time %q", s)
}

// SpeakingSessionResponse defines the structure for speaking session information returned to clients
type SpeakingSessionResponse struct {
	ID           int32      `json:"id"`
	UserID       int32      `json:"user_id"`
	SessionTopic *string    `json:"session_topic,omitempty"`
	StartTime    time.Time  `json:"start_time"`
	EndTime      *time.Time `json:"end_time,omitempty"`
	UpdatedAt    time.Time  `json:"updated_at"`
}

// NewSpeakingSessionResponse creates a SpeakingSessionResponse from a db.SpeakingSession model
func NewSpeakingSessionResponse(session db.SpeakingSession) SpeakingSessionResponse {
	var sessionTopic *string
	if session.SessionTopic.Valid {
		sessionTopic = &session.SessionTopic.String
	}

	var endTime *time.Time
	if session.EndTime.Valid {
		endTime = &session.EndTime.Time
	}

	return SpeakingSessionResponse{
		ID:           session.ID,
		UserID:       session.UserID,
		SessionTopic: sessionTopic,
		StartTime:    session.StartTime,
		EndTime:      endTime,
		UpdatedAt:    session.UpdatedAt,
	}
}

// SpeakingTurnResponse defines the structure for speaking turn information returned to clients
type SpeakingTurnResponse struct {
	ID                 int32           `json:"id"`
	SessionID          int32           `json:"session_id"`
	SpeakerType        string          `json:"speaker_type"`
	TextSpoken         *string         `json:"text_spoken,omitempty"`
	AudioRecordingPath *string         `json:"audio_recording_path,omitempty"`
	Timestamp          time.Time       `json:"timestamp"`
	AIEvaluation       json.RawMessage `json:"ai_evaluation,omitempty" swaggertype:"object"`
	AIScore            *float64        `json:"ai_score,omitempty"`
}

// NewSpeakingTurnResponse creates a SpeakingTurnResponse from a db.SpeakingTurn model
func NewSpeakingTurnResponse(turn db.SpeakingTurn) SpeakingTurnResponse {
	var textSpoken *string
	if turn.TextSpoken.Valid {
		textSpoken = &turn.TextSpoken.String
	}

	var audioRecordingPath *string
	if turn.AudioRecordingPath.Valid {
		audioRecordingPath = &turn.AudioRecordingPath.String
	}

	var aiEvaluation json.RawMessage
	if turn.AiEvaluation.Valid {
		aiEvaluation = turn.AiEvaluation.RawMessage
	}

	var aiScore *float64
	if turn.AiScore.Valid {
		scoreStr := turn.AiScore.String
		score, err := strconv.ParseFloat(scoreStr, 64)
		if err == nil {
			aiScore = &score
		}
	}

	return SpeakingTurnResponse{
		ID:                 turn.ID,
		SessionID:          turn.SessionID,
		SpeakerType:        turn.SpeakerType,
		TextSpoken:         textSpoken,
		AudioRecordingPath: audioRecordingPath,
		Timestamp:          turn.Timestamp,
		AIEvaluation:       aiEvaluation,
		AIScore:            aiScore,
	}
}

// ===== Speaking Session Handlers =====

// createSpeakingSessionRequest defines the structure for creating a new speaking session
type createSpeakingSessionRequest struct {
	UserID       int32        `json:"user_id" binding:"required,min=1"`
	SessionTopic *string      `json:"session_topic,omitempty"`
	StartTime    *CustomTime  `json:"start_time,omitempty"`
	EndTime      *CustomTime  `json:"end_time,omitempty"`
}

// @Summary     Create a new speaking session
// @Description Add a new speaking session to the database
// @Tags        speaking
// @Accept      json
// @Produce     json
// @Param       session body createSpeakingSessionRequest true "Speaking session object to create"
// @Success     201 {object} Response{data=SpeakingSessionResponse} "Speaking session created successfully"
// @Failure     400 {object} Response "Invalid request body"
// @Failure     500 {object} Response "Failed to create speaking session"
// @Security    ApiKeyAuth
// @Router      /api/v1/speaking/sessions [post]
func (server *Server) createSpeakingSession(ctx *gin.Context) {
	var req createSpeakingSessionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	var sessionTopic sql.NullString
	if req.SessionTopic != nil {
		sessionTopic = sql.NullString{
			String: *req.SessionTopic,
			Valid:  true,
		}
	}

	startTime := time.Now()
	if req.StartTime != nil {
		startTime = req.StartTime.Time
	}

	var endTime sql.NullTime
	if req.EndTime != nil {
		endTime = sql.NullTime{
			Time:  req.EndTime.Time,
			Valid: true,
		}
	}

	arg := db.CreateSpeakingSessionParams{
		UserID:       req.UserID,
		SessionTopic: sessionTopic,
		StartTime:    startTime,
		EndTime:      endTime,
	}
	session, err := server.store.CreateSpeakingSession(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create speaking session", err)
		return
	}

	logger.Debug("Created new speaking session with ID: %d", session.ID)
	SuccessResponse(ctx, http.StatusCreated, "Speaking session created successfully", NewSpeakingSessionResponse(session))
}

// getSpeakingSessionRequest defines the structure for requests to get a speaking session by ID
type getSpeakingSessionRequest struct {
	ID int32 `uri:"id" binding:"required,min=1"`
}

// @Summary     Get a speaking session by ID
// @Description Retrieve a specific speaking session by its ID
// @Tags        speaking
// @Accept      json
// @Produce     json
// @Param       id path int true "Speaking Session ID"
// @Success     200 {object} Response{data=SpeakingSessionResponse} "Speaking session retrieved successfully"
// @Failure     400 {object} Response "Invalid session ID"
// @Failure     404 {object} Response "Speaking session not found"
// @Failure     500 {object} Response "Failed to retrieve speaking session"
// @Security    ApiKeyAuth
// @Router      /api/v1/speaking/sessions/{id} [get]
func (server *Server) getSpeakingSession(ctx *gin.Context) {
	var req getSpeakingSessionRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid session ID", err)
		return
	}
	session, err := server.store.GetSpeakingSession(ctx, req.ID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Speaking session not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve speaking session", err)
		return
	}

	logger.Debug("Retrieved speaking session with ID: %d", session.ID)
	SuccessResponse(ctx, http.StatusOK, "Speaking session retrieved successfully", NewSpeakingSessionResponse(session))
}

// @Summary     List speaking sessions by user ID
// @Description Get a list of all speaking sessions for a specific user
// @Tags        speaking
// @Accept      json
// @Produce     json
// @Param       user_id path int true "User ID"
// @Success     200 {object} Response{data=[]SpeakingSessionResponse} "Speaking sessions retrieved successfully"
// @Failure     400 {object} Response "Invalid user ID"
// @Failure     500 {object} Response "Failed to retrieve speaking sessions"
// @Security    ApiKeyAuth
// @Router      /api/v1/speaking/users/{user_id}/sessions [get]
func (server *Server) listSpeakingSessionsByUserID(ctx *gin.Context) {
	userID, err := strconv.ParseInt(ctx.Param("user_id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
		return
	}

	sessions, err := server.store.ListSpeakingSessionsByUserID(ctx, int32(userID))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve speaking sessions", err)
		return
	}

	var sessionResponses []SpeakingSessionResponse
	for _, session := range sessions {
		sessionResponses = append(sessionResponses, NewSpeakingSessionResponse(session))
	}

	// Ensure we return an empty array instead of null if no results
	if sessionResponses == nil {
		sessionResponses = []SpeakingSessionResponse{}
	}

	logger.Debug("Retrieved %d speaking sessions for user ID: %d", len(sessionResponses), userID)
	SuccessResponse(ctx, http.StatusOK, "Speaking sessions retrieved successfully", sessionResponses)
}

// updateSpeakingSessionRequest defines the structure for updating an existing speaking session
type updateSpeakingSessionRequest struct {
	SessionTopic *string      `json:"session_topic,omitempty"`
	StartTime    *CustomTime  `json:"start_time,omitempty"`
	EndTime      *CustomTime  `json:"end_time,omitempty"`
}

// @Summary     Update a speaking session
// @Description Update an existing speaking session by ID
// @Tags        speaking
// @Accept      json
// @Produce     json
// @Param       id path int true "Speaking Session ID"
// @Param       session body updateSpeakingSessionRequest true "Speaking session fields to update"
// @Success     200 {object} Response{data=SpeakingSessionResponse} "Speaking session updated successfully"
// @Failure     400 {object} Response "Invalid request body or session ID"
// @Failure     404 {object} Response "Speaking session not found"
// @Failure     500 {object} Response "Failed to update speaking session"
// @Security    ApiKeyAuth
// @Router      /api/v1/speaking/sessions/{id} [put]
func (server *Server) updateSpeakingSession(ctx *gin.Context) {
	sessionID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid session ID", err)
		return
	}

	var req updateSpeakingSessionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Get existing session to update only provided fields
	existingSession, err := server.store.GetSpeakingSession(ctx, int32(sessionID))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Speaking session not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve speaking session for update", err)
		return
	}

	// Prepare update parameters
	arg := db.UpdateSpeakingSessionParams{
		ID:           int32(sessionID),
		SessionTopic: existingSession.SessionTopic,
		StartTime:    existingSession.StartTime,
		EndTime:      existingSession.EndTime,
	}

	// Update only provided fields
	if req.SessionTopic != nil {
		arg.SessionTopic = sql.NullString{
			String: *req.SessionTopic,
			Valid:  true,
		}
	}
	if req.StartTime != nil {
		arg.StartTime = req.StartTime.Time
	}
	if req.EndTime != nil {
		arg.EndTime = sql.NullTime{
			Time:  req.EndTime.Time,
			Valid: true,
		}
	}

	session, err := server.store.UpdateSpeakingSession(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update speaking session", err)
		return
	}

	logger.Debug("Updated speaking session with ID: %d", session.ID)
	SuccessResponse(ctx, http.StatusOK, "Speaking session updated successfully", NewSpeakingSessionResponse(session))
}

// @Summary     Delete a speaking session
// @Description Delete a specific speaking session by its ID
// @Tags        speaking
// @Accept      json
// @Produce     json
// @Param       id path int true "Speaking Session ID"
// @Success     200 {object} Response "Speaking session deleted successfully"
// @Failure     400 {object} Response "Invalid session ID"
// @Failure     500 {object} Response "Failed to delete speaking session"
// @Security    ApiKeyAuth
// @Router      /api/v1/speaking/sessions/{id} [delete]
func (server *Server) deleteSpeakingSession(ctx *gin.Context) {
	sessionID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid session ID", err)
		return
	}
	err = server.store.DeleteSpeakingSession(ctx, int32(sessionID))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete speaking session", err)
		return
	}

	logger.Debug("Deleted speaking session with ID: %d", sessionID)
	SuccessResponse(ctx, http.StatusOK, "Speaking session deleted successfully", nil)
}

// ===== Speaking Turn Handlers =====

// createSpeakingTurnRequest defines the structure for creating a new speaking turn
type createSpeakingTurnRequest struct {
	SessionID          int32           `json:"session_id" binding:"required,min=1"`
	SpeakerType        string          `json:"speaker_type" binding:"required"`
	TextSpoken         *string         `json:"text_spoken,omitempty"`
	AudioRecordingPath *string         `json:"audio_recording_path,omitempty"`
	Timestamp          *CustomTime     `json:"timestamp,omitempty"`
	AIEvaluation       json.RawMessage `json:"ai_evaluation,omitempty" swaggertype:"object"`
	AIScore            *float64        `json:"ai_score,omitempty"`
}

// @Summary     Create a new speaking turn
// @Description Add a new speaking turn to a session
// @Tags        speaking
// @Accept      json
// @Produce     json
// @Param       turn body createSpeakingTurnRequest true "Speaking turn object to create"
// @Success     201 {object} Response{data=SpeakingTurnResponse} "Speaking turn created successfully"
// @Failure     400 {object} Response "Invalid request body"
// @Failure     500 {object} Response "Failed to create speaking turn"
// @Security    ApiKeyAuth
// @Router      /api/v1/speaking/turns [post]
func (server *Server) createSpeakingTurn(ctx *gin.Context) {
	var req createSpeakingTurnRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	var textSpoken sql.NullString
	if req.TextSpoken != nil {
		textSpoken = sql.NullString{
			String: *req.TextSpoken,
			Valid:  true,
		}
	}

	var audioRecordingPath sql.NullString
	if req.AudioRecordingPath != nil {
		audioRecordingPath = sql.NullString{
			String: *req.AudioRecordingPath,
			Valid:  true,
		}
	}

	timestamp := time.Now()
	if req.Timestamp != nil {
		timestamp = req.Timestamp.Time
	}

	var aiEvaluation pqtype.NullRawMessage
	if req.AIEvaluation != nil {
		aiEvaluation = pqtype.NullRawMessage{
			RawMessage: req.AIEvaluation,
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

	arg := db.CreateSpeakingTurnParams{
		SessionID:          req.SessionID,
		SpeakerType:        req.SpeakerType,
		TextSpoken:         textSpoken,
		AudioRecordingPath: audioRecordingPath,
		Timestamp:          timestamp,
		AiEvaluation:       aiEvaluation,
		AiScore:            aiScore,
	}

	turn, err := server.store.CreateSpeakingTurn(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create speaking turn", err)
		return
	}

	logger.Debug("Created new speaking turn with ID: %d for session ID: %d", turn.ID, turn.SessionID)
	SuccessResponse(ctx, http.StatusCreated, "Speaking turn created successfully", NewSpeakingTurnResponse(turn))
}

// getSpeakingTurnRequest defines the structure for requests to get a speaking turn by ID
type getSpeakingTurnRequest struct {
	ID int32 `uri:"id" binding:"required,min=1"`
}

// @Summary     Get a speaking turn by ID
// @Description Retrieve a specific speaking turn by its ID
// @Tags        speaking
// @Accept      json
// @Produce     json
// @Param       id path int true "Speaking Turn ID"
// @Success     200 {object} Response{data=SpeakingTurnResponse} "Speaking turn retrieved successfully"
// @Failure     400 {object} Response "Invalid turn ID"
// @Failure     404 {object} Response "Speaking turn not found"
// @Failure     500 {object} Response "Failed to retrieve speaking turn"
// @Security    ApiKeyAuth
// @Router      /api/v1/speaking/turns/{id} [get]
func (server *Server) getSpeakingTurn(ctx *gin.Context) {
	var req getSpeakingTurnRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid turn ID", err)
		return
	}
	turn, err := server.store.GetSpeakingTurn(ctx, req.ID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Speaking turn not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve speaking turn", err)
		return
	}

	logger.Debug("Retrieved speaking turn with ID: %d", turn.ID)
	SuccessResponse(ctx, http.StatusOK, "Speaking turn retrieved successfully", NewSpeakingTurnResponse(turn))
}

// @Summary     List speaking turns by session ID
// @Description Get a list of all speaking turns for a specific session
// @Tags        speaking
// @Accept      json
// @Produce     json
// @Param       id path int true "Session ID"
// @Success     200 {object} Response{data=[]SpeakingTurnResponse} "Speaking turns retrieved successfully"
// @Failure     400 {object} Response "Invalid session ID"
// @Failure     500 {object} Response "Failed to retrieve speaking turns"
// @Security    ApiKeyAuth
// @Router      /api/v1/speaking/sessions/{id}/turns [get]
func (server *Server) listSpeakingTurnsBySessionID(ctx *gin.Context) {
	sessionID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid session ID", err)
		return
	}

	turns, err := server.store.ListSpeakingTurnsBySessionID(ctx, int32(sessionID))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve speaking turns", err)
		return
	}

	var turnResponses []SpeakingTurnResponse
	for _, turn := range turns {
		turnResponses = append(turnResponses, NewSpeakingTurnResponse(turn))
	}

	// Ensure we return an empty array instead of null if no results
	if turnResponses == nil {
		turnResponses = []SpeakingTurnResponse{}
	}

	logger.Debug("Retrieved %d speaking turns for session ID: %d", len(turnResponses), sessionID)
	SuccessResponse(ctx, http.StatusOK, "Speaking turns retrieved successfully", turnResponses)
}

// updateSpeakingTurnRequest defines the structure for updating an existing speaking turn
type updateSpeakingTurnRequest struct {
	TextSpoken         *string         `json:"text_spoken,omitempty"`
	AudioRecordingPath *string         `json:"audio_recording_path,omitempty"`
	AIEvaluation       json.RawMessage `json:"ai_evaluation,omitempty" swaggertype:"object"`
	AIScore            *float64        `json:"ai_score,omitempty"`
	Timestamp          *CustomTime     `json:"timestamp,omitempty"`
}

// @Summary     Update a speaking turn
// @Description Update an existing speaking turn by ID
// @Tags        speaking
// @Accept      json
// @Produce     json
// @Param       id path int true "Speaking Turn ID"
// @Param       turn body updateSpeakingTurnRequest true "Speaking turn fields to update"
// @Success     200 {object} Response{data=SpeakingTurnResponse} "Speaking turn updated successfully"
// @Failure     400 {object} Response "Invalid request body or turn ID"
// @Failure     404 {object} Response "Speaking turn not found"
// @Failure     500 {object} Response "Failed to update speaking turn"
// @Security    ApiKeyAuth
// @Router      /api/v1/speaking/turns/{id} [put]
func (server *Server) updateSpeakingTurn(ctx *gin.Context) {
	turnID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid turn ID", err)
		return
	}

	var req updateSpeakingTurnRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Get existing turn to update only provided fields
	existingTurn, err := server.store.GetSpeakingTurn(ctx, int32(turnID))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Speaking turn not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve speaking turn for update", err)
		return
	}

	// Prepare update parameters
	arg := db.UpdateSpeakingTurnParams{
		ID:                 int32(turnID),
		TextSpoken:         existingTurn.TextSpoken,
		AudioRecordingPath: existingTurn.AudioRecordingPath,
		AiEvaluation:       existingTurn.AiEvaluation,
		AiScore:            existingTurn.AiScore,
		Timestamp:          existingTurn.Timestamp,
	}

	// Update only provided fields
	if req.TextSpoken != nil {
		arg.TextSpoken = sql.NullString{
			String: *req.TextSpoken,
			Valid:  true,
		}
	}
	if req.AudioRecordingPath != nil {
		arg.AudioRecordingPath = sql.NullString{
			String: *req.AudioRecordingPath,
			Valid:  true,
		}
	}
	if req.AIEvaluation != nil {
		arg.AiEvaluation = pqtype.NullRawMessage{
			RawMessage: req.AIEvaluation,
			Valid:      true,
		}
	}
	if req.AIScore != nil {
		arg.AiScore = sql.NullString{
			String: strconv.FormatFloat(*req.AIScore, 'f', 2, 64),
			Valid:  true,
		}
	}
	if req.Timestamp != nil {
		arg.Timestamp = req.Timestamp.Time
	}

	turn, err := server.store.UpdateSpeakingTurn(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update speaking turn", err)
		return
	}

	logger.Debug("Updated speaking turn with ID: %d", turn.ID)
	SuccessResponse(ctx, http.StatusOK, "Speaking turn updated successfully", NewSpeakingTurnResponse(turn))
}

// @Summary     Delete a speaking turn
// @Description Delete a specific speaking turn by its ID
// @Tags        speaking
// @Accept      json
// @Produce     json
// @Param       id path int true "Speaking Turn ID"
// @Success     200 {object} Response "Speaking turn deleted successfully"
// @Failure     400 {object} Response "Invalid turn ID"
// @Failure     500 {object} Response "Failed to delete speaking turn"
// @Security    ApiKeyAuth
// @Router      /api/v1/speaking/turns/{id} [delete]
func (server *Server) deleteSpeakingTurn(ctx *gin.Context) {
	turnID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid turn ID", err)
		return
	}
	err = server.store.DeleteSpeakingTurn(ctx, int32(turnID))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete speaking turn", err)
		return
	}

	logger.Debug("Deleted speaking turn with ID: %d", turnID)
	SuccessResponse(ctx, http.StatusOK, "Speaking turn deleted successfully", nil)
}

// GenerateSpeakingResponse request structure
type GenerateSpeakingRequest struct {
	UserMessage         string `json:"user_message" binding:"required"`
	ConversationContext string `json:"conversation_context"`
	Difficulty          string `json:"difficulty"`
}

// GenerateSpeakingResponse response structure
type GenerateSpeakingResponseData struct {
	Response    string `json:"response"`
	ProcessedAt string `json:"processed_at"`
}

// @Summary     Generate AI speaking response
// @Description Generate an AI response for speaking practice based on user input and conversation context
// @Tags        ai
// @Accept      json
// @Produce     json
// @Param       request body GenerateSpeakingRequest true "Speaking response generation request"
// @Success     200 {object} Response{data=GenerateSpeakingResponseData} "Speaking response generated successfully"
// @Failure     400 {object} Response "Invalid request parameters"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     503 {object} Response "AI service unavailable"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/ai/generate-speaking-response [post]
func (server *Server) generateSpeakingResponse(ctx *gin.Context) {
	var req GenerateSpeakingRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	// Check if AI scoring service is available
	if server.aiScoringService == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "AI service is not configured", nil)
		return
	}

	// Create AI request
	aiReq := ai.AISpeakingRequest{
		UserMessage:         req.UserMessage,
		ConversationContext: req.ConversationContext,
		Difficulty:          req.Difficulty,
	}

	// Generate AI response
	aiResponse, err := server.aiScoringService.GenerateSpeakingResponse(ctx, aiReq)
	if err != nil {
		logger.Error("Failed to generate AI speaking response: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to generate AI response", err)
		return
	}

	response := GenerateSpeakingResponseData{
		Response:    aiResponse.Response,
		ProcessedAt: aiResponse.ProcessedAt.Format(time.RFC3339),
	}

	logger.Debug("Generated AI speaking response successfully")
	SuccessResponse(ctx, http.StatusOK, "Speaking response generated successfully", response)
}
