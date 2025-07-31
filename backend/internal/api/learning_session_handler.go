package api

import (
	"database/sql"
	"encoding/json"
	"math/rand"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/sqlc-dev/pqtype"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/token"
)

// LearningSessionResponse represents a learning session response
type LearningSessionResponse struct {
	ID             int32   `json:"id"`
	UserID         int32   `json:"user_id"`
	StudySetID     *int32  `json:"study_set_id,omitempty"`
	SessionType    string  `json:"session_type"`
	StartedAt      string  `json:"started_at"`
	CompletedAt    *string `json:"completed_at,omitempty"`
	TotalQuestions int32   `json:"total_questions"`
	CorrectAnswers int32   `json:"correct_answers"`
	SessionData    *SessionData `json:"session_data,omitempty"`
}

// SessionData represents the union of all possible session data types
type SessionData struct {
	Flashcard *FlashcardSessionData `json:"flashcard,omitempty"`
	Quiz      *QuizSessionData      `json:"quiz,omitempty"`
	Match     *MatchSessionData     `json:"match,omitempty"`
	Type      *TypeSessionData      `json:"type,omitempty"`
	FinalStats *SessionStats        `json:"final_stats,omitempty"`
}

// LearningAttemptResponse represents a learning attempt response
type LearningAttemptResponse struct {
	ID               int32  `json:"id"`
	SessionID        int32  `json:"session_id"`
	WordID           int32  `json:"word_id"`
	Word             string `json:"word,omitempty"`
	AttemptType      string `json:"attempt_type"`
	UserAnswer       string `json:"user_answer,omitempty"`
	CorrectAnswer    string `json:"correct_answer"`
	IsCorrect        bool   `json:"is_correct"`
	ResponseTimeMs   *int32 `json:"response_time_ms,omitempty"`
	DifficultyRating *int32 `json:"difficulty_rating,omitempty"`
	CreatedAt        string `json:"created_at"`
}

// FlashcardQuestion represents a flashcard learning question
type FlashcardQuestion struct {
	WordID        int32  `json:"word_id"`
	Word          string `json:"word"`
	Meaning       string `json:"meaning"`
	Pronunciation string `json:"pronunciation,omitempty"`
	Level         int32  `json:"level"`
}

// MultipleChoiceQuestion represents a multiple choice question
type MultipleChoiceQuestion struct {
	WordID        int32    `json:"word_id"`
	Word          string   `json:"word"`
	Pronunciation string   `json:"pronunciation,omitempty"`
	Options       []string `json:"options"`
	CorrectAnswer string   `json:"correct_answer"`
}

// MatchPair represents a match game pair
type MatchPair struct {
	WordID   int32  `json:"word_id"`
	Word     string `json:"word"`
	Meaning  string `json:"meaning"`
	Position int    `json:"position"`
}

// FlashcardSessionData represents session data for flashcard mode
type FlashcardSessionData struct {
	Questions []FlashcardQuestion `json:"questions"`
}

// QuizSessionData represents session data for quiz/multiple choice mode
type QuizSessionData struct {
	Questions []MultipleChoiceQuestion `json:"questions"`
}

// MatchSessionData represents session data for match game mode
type MatchSessionData struct {
	Pairs []MatchPair `json:"pairs"`
}

// TypeSessionData represents session data for typing mode
type TypeSessionData struct {
	Questions []FlashcardQuestion `json:"questions"`
}

// SessionStats represents final session statistics
type SessionStats struct {
	TotalAttempts     int32   `json:"total_attempts"`
	CorrectAttempts   int32   `json:"correct_attempts"`
	AvgResponseTime   float64 `json:"avg_response_time"`
	AvgDifficulty     float64 `json:"avg_difficulty"`
	AccuracyPercentage float64 `json:"accuracy_percentage"`
}

// createLearningSessionRequest defines the structure for creating a learning session
type createLearningSessionRequest struct {
	StudySetID    *int32        `json:"study_set_id,omitempty"`
	SessionType   string        `json:"session_type" binding:"required,oneof=flashcard match quiz type"`
	WordLimit     int32         `json:"word_limit,default=10" binding:"min=1,max=50"`
	SessionConfig *SessionConfig `json:"session_config,omitempty"`
}

// SessionConfig represents optional configuration for a learning session
type SessionConfig struct {
	TimeLimit       *int32 `json:"time_limit,omitempty"`        // Time limit in seconds
	ShowHints       *bool  `json:"show_hints,omitempty"`        // Whether to show hints
	ShuffleAnswers  *bool  `json:"shuffle_answers,omitempty"`   // Whether to shuffle multiple choice answers
	CaseSensitive   *bool  `json:"case_sensitive,omitempty"`    // Whether typing answers are case sensitive
	AllowPartial    *bool  `json:"allow_partial,omitempty"`     // Whether to allow partial credit for typing
}

// submitLearningAttemptRequest defines the structure for submitting a learning attempt
type submitLearningAttemptRequest struct {
	WordID           int32  `json:"word_id" binding:"required,min=1"`
	AttemptType      string `json:"attempt_type" binding:"required"`
	UserAnswer       string `json:"user_answer"`
	ResponseTimeMs   *int32 `json:"response_time_ms,omitempty"`
	DifficultyRating *int32 `json:"difficulty_rating,omitempty" binding:"omitempty,min=1,max=5"`
}

// completeSessionRequest defines the structure for completing a session
type completeSessionRequest struct {
	FinalStats *SessionStats `json:"final_stats,omitempty"`
}

// getLearningSessionRequest defines the URI parameter for session ID
type getLearningSessionRequest struct {
	ID int32 `uri:"id" binding:"required,min=1"`
}

// NewLearningSessionResponse creates a LearningSessionResponse from database model
func NewLearningSessionResponse(session db.LearningSession) LearningSessionResponse {
	response := LearningSessionResponse{
		ID:          session.ID,
		UserID:      session.UserID,
		SessionType: session.SessionType,
		StartedAt:   session.StartedAt.Format("2006-01-02T15:04:05Z"),
	}

	if session.TotalQuestions.Valid {
		response.TotalQuestions = session.TotalQuestions.Int32
	}

	if session.CorrectAnswers.Valid {
		response.CorrectAnswers = session.CorrectAnswers.Int32
	}

	if session.StudySetID.Valid {
		response.StudySetID = &session.StudySetID.Int32
	}

	if session.CompletedAt.Valid {
		completedAt := session.CompletedAt.Time.Format("2006-01-02T15:04:05Z")
		response.CompletedAt = &completedAt
	}

	if session.SessionData.Valid {
		var rawData map[string]interface{}
		if err := json.Unmarshal(session.SessionData.RawMessage, &rawData); err == nil {
			sessionData := &SessionData{}
			
			// Parse different session data types based on session type
			switch session.SessionType {
			case "flashcard":
				if questions, ok := rawData["questions"]; ok {
					if questionsBytes, err := json.Marshal(questions); err == nil {
						var flashcardQuestions []FlashcardQuestion
						if err := json.Unmarshal(questionsBytes, &flashcardQuestions); err == nil {
							sessionData.Flashcard = &FlashcardSessionData{Questions: flashcardQuestions}
						}
					}
				}
			case "quiz":
				if questions, ok := rawData["questions"]; ok {
					if questionsBytes, err := json.Marshal(questions); err == nil {
						var quizQuestions []MultipleChoiceQuestion
						if err := json.Unmarshal(questionsBytes, &quizQuestions); err == nil {
							sessionData.Quiz = &QuizSessionData{Questions: quizQuestions}
						}
					}
				}
			case "match":
				if pairs, ok := rawData["pairs"]; ok {
					if pairsBytes, err := json.Marshal(pairs); err == nil {
						var matchPairs []MatchPair
						if err := json.Unmarshal(pairsBytes, &matchPairs); err == nil {
							sessionData.Match = &MatchSessionData{Pairs: matchPairs}
						}
					}
				}
			case "type":
				if questions, ok := rawData["questions"]; ok {
					if questionsBytes, err := json.Marshal(questions); err == nil {
						var typeQuestions []FlashcardQuestion
						if err := json.Unmarshal(questionsBytes, &typeQuestions); err == nil {
							sessionData.Type = &TypeSessionData{Questions: typeQuestions}
						}
					}
				}
			}
			
			// Parse final stats if available
			if finalStats, ok := rawData["final_stats"]; ok {
				if statsBytes, err := json.Marshal(finalStats); err == nil {
					var stats SessionStats
					if err := json.Unmarshal(statsBytes, &stats); err == nil {
						sessionData.FinalStats = &stats
					}
				}
			}
			
			response.SessionData = sessionData
		}
	}

	return response
}

// @Summary Start a new learning session
// @Description Start a new vocabulary learning session
// @Tags learning
// @Accept json
// @Produce json
// @Param request body createLearningSessionRequest true "Session configuration"
// @Success 201 {object} Response{data=LearningSessionResponse} "Learning session started successfully"
// @Failure 400 {object} Response "Invalid request body"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Failed to start learning session"
// @Security ApiKeyAuth
// @Router /api/v1/learning/sessions [post]
func (server *Server) startLearningSession(ctx *gin.Context) {
	var req createLearningSessionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	// Get words for the session
	var words []db.Word
	var err error

	if req.StudySetID != nil {
		// Get words from study set
		studySetWords, err := server.store.GetStudySetWords(ctx, *req.StudySetID)
		if err != nil {
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get study set words", err)
			return
		}

		// Convert to []db.Word
		for _, studySetWord := range studySetWords {
			words = append(words, studySetWord.Word)
		}

		// Check if user has access to the study set
		studySet, err := server.store.GetStudySet(ctx, *req.StudySetID)
		if err != nil {
			ErrorResponse(ctx, http.StatusNotFound, "Study set not found", err)
			return
		}
		if studySet.UserID != authPayload.ID && (!studySet.IsPublic.Valid || !studySet.IsPublic.Bool) {
			ErrorResponse(ctx, http.StatusForbidden, "Access denied to study set", nil)
			return
		}
	} else {
		// Get words that need review
		reviewWords, err := server.store.GetWordsNeedingReview(ctx, db.GetWordsNeedingReviewParams{
			UserID:       authPayload.ID,
			MasteryLevel: sql.NullInt32{Int32: 8, Valid: true}, // Words with mastery level < 8
			Limit:        req.WordLimit,
		})
		if err != nil {
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get words for review", err)
			return
		}

		// Extract words from the result
		for _, review := range reviewWords {
			words = append(words, review.Word)
		}
	}

	if len(words) == 0 {
		ErrorResponse(ctx, http.StatusBadRequest, "No words available for learning session", nil)
		return
	}

	// Limit the number of words
	if len(words) > int(req.WordLimit) {
		words = words[:req.WordLimit]
	}

	// Generate session questions based on session type
	sessionData := make(map[string]interface{})
	switch req.SessionType {
	case "flashcard":
		sessionData["questions"] = generateFlashcardQuestions(words)
	case "quiz":
		sessionData["questions"] = generateMultipleChoiceQuestions(words)
	case "match":
		sessionData["pairs"] = generateMatchPairs(words)
	case "type":
		sessionData["questions"] = generateTypeQuestions(words)
	}

	// Add session config if provided
	if req.SessionConfig != nil {
		if req.SessionConfig.TimeLimit != nil {
			sessionData["time_limit"] = *req.SessionConfig.TimeLimit
		}
		if req.SessionConfig.ShowHints != nil {
			sessionData["show_hints"] = *req.SessionConfig.ShowHints
		}
		if req.SessionConfig.ShuffleAnswers != nil {
			sessionData["shuffle_answers"] = *req.SessionConfig.ShuffleAnswers
		}
		if req.SessionConfig.CaseSensitive != nil {
			sessionData["case_sensitive"] = *req.SessionConfig.CaseSensitive
		}
		if req.SessionConfig.AllowPartial != nil {
			sessionData["allow_partial"] = *req.SessionConfig.AllowPartial
		}
	}

	sessionDataJSON, _ := json.Marshal(sessionData)

	var studySetID sql.NullInt32
	if req.StudySetID != nil {
		studySetID = sql.NullInt32{Int32: *req.StudySetID, Valid: true}
	}

	// Create the learning session
	session, err := server.store.CreateLearningSession(ctx, db.CreateLearningSessionParams{
		UserID:         authPayload.ID,
		StudySetID:     studySetID,
		SessionType:    req.SessionType,
		TotalQuestions: sql.NullInt32{Int32: int32(len(words)), Valid: true},
		SessionData:    pqtype.NullRawMessage{RawMessage: sessionDataJSON, Valid: true},
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create learning session", err)
		return
	}

	response := NewLearningSessionResponse(session)
	SuccessResponse(ctx, http.StatusCreated, "Learning session started successfully", response)
}

// @Summary Get learning session
// @Description Get details of a learning session
// @Tags learning
// @Accept json
// @Produce json
// @Param id path int true "Session ID"
// @Success 200 {object} Response{data=LearningSessionResponse} "Learning session retrieved successfully"
// @Failure 400 {object} Response "Invalid session ID"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 404 {object} Response "Session not found"
// @Failure 500 {object} Response "Failed to retrieve learning session"
// @Security ApiKeyAuth
// @Router /api/v1/learning/sessions/{id} [get]
func (server *Server) getLearningSession(ctx *gin.Context) {
	var req getLearningSessionRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid session ID", err)
		return
	}

	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	session, err := server.store.GetLearningSession(ctx, db.GetLearningSessionParams{
		ID:     req.ID,
		UserID: authPayload.ID,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Learning session not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve learning session", err)
		return
	}

	response := NewLearningSessionResponse(session)
	SuccessResponse(ctx, http.StatusOK, "Learning session retrieved successfully", response)
}

// @Summary Submit learning attempt
// @Description Submit an answer for a word in a learning session
// @Tags learning
// @Accept json
// @Produce json
// @Param id path int true "Session ID"
// @Param request body submitLearningAttemptRequest true "Learning attempt details"
// @Success 200 {object} Response{data=LearningAttemptResponse} "Learning attempt submitted successfully"
// @Failure 400 {object} Response "Invalid request body or session ID"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 404 {object} Response "Session not found"
// @Failure 500 {object} Response "Failed to submit learning attempt"
// @Security ApiKeyAuth
// @Router /api/v1/learning/sessions/{id}/attempts [post]
func (server *Server) submitLearningAttempt(ctx *gin.Context) {
	var uriReq getLearningSessionRequest
	if err := ctx.ShouldBindUri(&uriReq); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid session ID", err)
		return
	}

	var req submitLearningAttemptRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	// Verify session belongs to user
	_, err := server.store.GetLearningSession(ctx, db.GetLearningSessionParams{
		ID:     uriReq.ID,
		UserID: authPayload.ID,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Learning session not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve learning session", err)
		return
	}

	// Get the word to determine correct answer
	word, err := server.store.GetWord(ctx, req.WordID)
	if err != nil {
		ErrorResponse(ctx, http.StatusNotFound, "Word not found", err)
		return
	}

	// Determine if answer is correct based on attempt type
	isCorrect := false
	correctAnswer := word.ShortMean
	switch req.AttemptType {
	case "flashcard":
		// For flashcard, any non-empty answer is considered an attempt
		isCorrect = true // User self-reports correctness in flashcard mode
	case "multiple_choice", "quiz":
		isCorrect = req.UserAnswer == correctAnswer
	case "type":
		// For type mode, we do a more flexible comparison
		isCorrect = compareTypedAnswer(req.UserAnswer, correctAnswer, word.Word)
	case "match":
		isCorrect = req.UserAnswer == correctAnswer
	}

	// Create learning attempt
	var responseTime sql.NullInt32
	if req.ResponseTimeMs != nil {
		responseTime = sql.NullInt32{Int32: *req.ResponseTimeMs, Valid: true}
	}

	var difficultyRating sql.NullInt32
	if req.DifficultyRating != nil {
		difficultyRating = sql.NullInt32{Int32: *req.DifficultyRating, Valid: true}
	}

	attempt, err := server.store.CreateLearningAttempt(ctx, db.CreateLearningAttemptParams{
		SessionID:        uriReq.ID,
		WordID:           req.WordID,
		AttemptType:      req.AttemptType,
		UserAnswer:       sql.NullString{String: req.UserAnswer, Valid: req.UserAnswer != ""},
		CorrectAnswer:    correctAnswer,
		IsCorrect:        isCorrect,
		ResponseTimeMs:   responseTime,
		DifficultyRating: difficultyRating,
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create learning attempt", err)
		return
	}

	// Update vocabulary statistics
	go server.updateVocabularyStats(authPayload.ID, req.WordID, isCorrect, req.ResponseTimeMs, req.DifficultyRating)

	response := LearningAttemptResponse{
		ID:            attempt.ID,
		SessionID:     attempt.SessionID,
		WordID:        attempt.WordID,
		Word:          word.Word,
		AttemptType:   attempt.AttemptType,
		CorrectAnswer: attempt.CorrectAnswer,
		IsCorrect:     attempt.IsCorrect,
		CreatedAt:     attempt.CreatedAt.Format("2006-01-02T15:04:05Z"),
	}

	if attempt.UserAnswer.Valid {
		response.UserAnswer = attempt.UserAnswer.String
	}
	if attempt.ResponseTimeMs.Valid {
		response.ResponseTimeMs = &attempt.ResponseTimeMs.Int32
	}
	if attempt.DifficultyRating.Valid {
		response.DifficultyRating = &attempt.DifficultyRating.Int32
	}

	SuccessResponse(ctx, http.StatusOK, "Learning attempt submitted successfully", response)
}

// @Summary Complete learning session
// @Description Mark a learning session as completed
// @Tags learning
// @Accept json
// @Produce json
// @Param id path int true "Session ID"
// @Param request body completeSessionRequest true "Session completion data"
// @Success 200 {object} Response{data=LearningSessionResponse} "Learning session completed successfully"
// @Failure 400 {object} Response "Invalid request body or session ID"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 404 {object} Response "Session not found"
// @Failure 500 {object} Response "Failed to complete learning session"
// @Security ApiKeyAuth
// @Router /api/v1/learning/sessions/{id}/complete [post]
func (server *Server) completeLearningSession(ctx *gin.Context) {
	var uriReq getLearningSessionRequest
	if err := ctx.ShouldBindUri(&uriReq); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid session ID", err)
		return
	}

	var req completeSessionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	// Get session stats
	stats, err := server.store.GetSessionStats(ctx, uriReq.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get session statistics", err)
		return
	}

	// Prepare session data
	sessionData := make(map[string]interface{})
	
	// Add final stats
	finalStats := SessionStats{
		TotalAttempts:     int32(stats.TotalAttempts),
		CorrectAttempts:   int32(stats.CorrectAttempts),
		AvgResponseTime:   stats.AvgResponseTime,
		AvgDifficulty:     stats.AvgDifficulty,
		AccuracyPercentage: float64(stats.CorrectAttempts) / float64(stats.TotalAttempts) * 100,
	}
	
	// Use provided final stats if available, otherwise use calculated ones
	if req.FinalStats != nil {
		sessionData["final_stats"] = *req.FinalStats
	} else {
		sessionData["final_stats"] = finalStats
	}

	sessionDataJSON, _ := json.Marshal(sessionData)
	now := time.Now()

	// Update session as completed
	session, err := server.store.UpdateLearningSession(ctx, db.UpdateLearningSessionParams{
		ID:             uriReq.ID,
		UserID:         authPayload.ID,
		CompletedAt:    sql.NullTime{Time: now, Valid: true},
		TotalQuestions: sql.NullInt32{Int32: int32(stats.TotalAttempts), Valid: true},
		CorrectAnswers: sql.NullInt32{Int32: int32(stats.CorrectAttempts), Valid: true},
		SessionData:    pqtype.NullRawMessage{RawMessage: sessionDataJSON, Valid: true},
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Learning session not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to complete learning session", err)
		return
	}

	response := NewLearningSessionResponse(session)
	SuccessResponse(ctx, http.StatusOK, "Learning session completed successfully", response)
}

// Helper functions for generating different types of questions

func generateFlashcardQuestions(words []db.Word) []FlashcardQuestion {
	var questions []FlashcardQuestion
	for _, word := range words {
		questions = append(questions, FlashcardQuestion{
			WordID:        word.ID,
			Word:          word.Word,
			Meaning:       word.ShortMean,
			Pronunciation: word.Pronounce,
			Level:         word.Level,
		})
	}
	return questions
}

func generateMultipleChoiceQuestions(words []db.Word) []MultipleChoiceQuestion {
	var questions []MultipleChoiceQuestion
	rand.Seed(time.Now().UnixNano())

	for i, word := range words {
		options := []string{word.ShortMean}
		
		// Add 3 random wrong options from other words
		for len(options) < 4 {
			randomIndex := rand.Intn(len(words))
			if randomIndex != i && words[randomIndex].ShortMean != word.ShortMean {
				// Check if option already exists
				exists := false
				for _, opt := range options {
					if opt == words[randomIndex].ShortMean {
						exists = true
						break
					}
				}
				if !exists {
					options = append(options, words[randomIndex].ShortMean)
				}
			}
		}

		// Shuffle options
		for i := range options {
			j := rand.Intn(i + 1)
			options[i], options[j] = options[j], options[i]
		}

		questions = append(questions, MultipleChoiceQuestion{
			WordID:        word.ID,
			Word:          word.Word,
			Pronunciation: word.Pronounce,
			Options:       options,
			CorrectAnswer: word.ShortMean,
		})
	}
	return questions
}

func generateMatchPairs(words []db.Word) []MatchPair {
	var pairs []MatchPair
	for i, word := range words {
		pairs = append(pairs, MatchPair{
			WordID:   word.ID,
			Word:     word.Word,
			Meaning:  word.ShortMean,
			Position: i,
		})
	}
	
	// Shuffle pairs for match game
	rand.Seed(time.Now().UnixNano())
	for i := range pairs {
		j := rand.Intn(i + 1)
		pairs[i], pairs[j] = pairs[j], pairs[i]
	}
	
	return pairs
}

func generateTypeQuestions(words []db.Word) []FlashcardQuestion {
	// Type questions are similar to flashcard but expect typed answers
	return generateFlashcardQuestions(words)
}

func compareTypedAnswer(userAnswer, correctAnswer, word string) bool {
	// Simple comparison for now - can be made more sophisticated
	userLower := strings.ToLower(strings.TrimSpace(userAnswer))
	correctLower := strings.ToLower(strings.TrimSpace(correctAnswer))
	wordLower := strings.ToLower(strings.TrimSpace(word))
	
	// Exact match with correct answer or the word itself
	return userLower == correctLower || userLower == wordLower
}

// updateVocabularyStats updates vocabulary statistics in a goroutine
func (server *Server) updateVocabularyStats(userID, wordID int32, isCorrect bool, responseTimeMs, difficultyRating *int32) {
	// This would be called in a goroutine to update stats without blocking the response
	// Implementation would use the vocabulary stats queries we created
}
