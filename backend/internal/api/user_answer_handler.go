package api

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/token"
)

// UserAnswerResponse defines the structure for user answer information returned to clients
type UserAnswerResponse struct {
	UserAnswerID   int32      `json:"user_answer_id"`
	AttemptID      int32      `json:"attempt_id"`
	QuestionID     int32      `json:"question_id"`
	SelectedAnswer string     `json:"selected_answer"`
	IsCorrect      bool       `json:"is_correct"`
	AnswerTime     *time.Time `json:"answer_time,omitempty"`
	CreatedAt      time.Time  `json:"created_at"`
}

// UserAnswerWithQuestionResponse includes question details
type UserAnswerWithQuestionResponse struct {
	UserAnswerResponse
	QuestionTitle   string   `json:"question_title,omitempty"`
	TrueAnswer      string   `json:"true_answer,omitempty"`
	Explanation     string   `json:"explanation,omitempty"`
	PossibleAnswers []string `json:"possible_answers,omitempty"`
}

// AttemptAnswersResponse provides all answers for an attempt
type AttemptAnswersResponse struct {
	AttemptID     int32                            `json:"attempt_id"`
	TotalAnswered int32                            `json:"total_answered"`
	CorrectCount  int32                            `json:"correct_count"`
	Answers       []UserAnswerWithQuestionResponse `json:"answers"`
}

// AttemptScoreResponse provides scoring information
type AttemptScoreResponse struct {
	AttemptID       int32   `json:"attempt_id"`
	TotalQuestions  int32   `json:"total_questions"`
	CorrectAnswers  int32   `json:"correct_answers"`
	CalculatedScore float64 `json:"calculated_score"`
}

// NewUserAnswerResponse creates a response from db.UserAnswer model
func NewUserAnswerResponse(userAnswer db.UserAnswer) UserAnswerResponse {
	response := UserAnswerResponse{
		UserAnswerID:   userAnswer.UserAnswerID,
		AttemptID:      userAnswer.AttemptID,
		QuestionID:     userAnswer.QuestionID,
		SelectedAnswer: userAnswer.SelectedAnswer,
		IsCorrect:      userAnswer.IsCorrect,
		CreatedAt:      userAnswer.CreatedAt,
	}

	// Handle nullable AnswerTime
	if userAnswer.AnswerTime.Valid {
		response.AnswerTime = &userAnswer.AnswerTime.Time
	}

	return response
}

// NewUserAnswerWithQuestionResponse creates a response from db.ListUserAnswersByAttemptWithQuestionsRow
func NewUserAnswerWithQuestionResponse(userAnswerWithQuestion db.ListUserAnswersByAttemptWithQuestionsRow) UserAnswerWithQuestionResponse {
	response := UserAnswerWithQuestionResponse{
		UserAnswerResponse: UserAnswerResponse{
			UserAnswerID:   userAnswerWithQuestion.UserAnswerID,
			AttemptID:      userAnswerWithQuestion.AttemptID,
			QuestionID:     userAnswerWithQuestion.QuestionID,
			SelectedAnswer: userAnswerWithQuestion.SelectedAnswer,
			IsCorrect:      userAnswerWithQuestion.IsCorrect,
			CreatedAt:      userAnswerWithQuestion.CreatedAt,
		},
		QuestionTitle:   userAnswerWithQuestion.QuestionTitle,
		TrueAnswer:      userAnswerWithQuestion.TrueAnswer,
		Explanation:     userAnswerWithQuestion.Explanation,
		PossibleAnswers: userAnswerWithQuestion.PossibleAnswers,
	}

	// Handle nullable AnswerTime
	if userAnswerWithQuestion.AnswerTime.Valid {
		response.AnswerTime = &userAnswerWithQuestion.AnswerTime.Time
	}

	return response
}

// createUserAnswerRequest defines the structure for creating a new user answer
type createUserAnswerRequest struct {
	AttemptID      int32  `json:"attempt_id" binding:"required,min=1"`
	QuestionID     int32  `json:"question_id" binding:"required,min=1"`
	SelectedAnswer string `json:"selected_answer" binding:"required"`
}

// getUserAnswerRequest defines the structure for getting a user answer by ID
type getUserAnswerRequest struct {
	UserAnswerID int32 `uri:"id" binding:"required,min=1"`
}

// @Summary     Submit a user answer
// @Description Submit an answer for a question in an exam attempt
// @Tags        user-answers
// @Accept      json
// @Produce     json
// @Param       answer body createUserAnswerRequest true "User answer to submit"
// @Success     201 {object} Response{data=UserAnswerResponse} "Answer submitted successfully"
// @Failure     400 {object} Response "Invalid request body"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     404 {object} Response "Attempt or question not found"
// @Failure     409 {object} Response "Answer already exists for this question"
// @Failure     500 {object} Response "Failed to submit answer"
// @Security    ApiKeyAuth
// @Router      /api/v1/user-answers [post]
func (server *Server) createUserAnswer(ctx *gin.Context) {
	var req createUserAnswerRequest
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

	// Verify the attempt belongs to the user
	_, err := server.store.GetExamAttemptByUser(ctx, db.GetExamAttemptByUserParams{
		AttemptID: req.AttemptID,
		UserID:    authPayload.ID,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "exam_attempt_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_verify_exam_attempt", err)
		return
	}

	// Check if answer already exists for this question
	_, err = server.store.GetUserAnswerByAttemptAndQuestion(ctx, db.GetUserAnswerByAttemptAndQuestionParams{
		AttemptID:  req.AttemptID,
		QuestionID: req.QuestionID,
	})
	if err == nil {
		ErrorResponse(ctx, http.StatusConflict, "answer_already_exists", nil)
		return
	} else if err != sql.ErrNoRows {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_check_existing_answer", err)
		return
	}

	// Get question to check correct answer
	question, err := server.store.GetQuestion(ctx, req.QuestionID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "question_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_question", err)
		return
	}

	// Determine if answer is correct
	isCorrect := req.SelectedAnswer == question.TrueAnswer

	// Create the user answer
	arg := db.CreateUserAnswerParams{
		AttemptID:      req.AttemptID,
		QuestionID:     req.QuestionID,
		SelectedAnswer: req.SelectedAnswer,
		IsCorrect:      isCorrect,
		AnswerTime:     sql.NullTime{Time: time.Now(), Valid: true},
	}

	userAnswer, err := server.store.CreateUserAnswer(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_create_user_answer", err)
		return
	}

	// Clear user cache
	if server.serviceCache != nil {
		go func() {
			server.ClearUserCache(int64(authPayload.ID))
		}()
	}

	response := NewUserAnswerResponse(userAnswer)
	SuccessResponse(ctx, http.StatusCreated, "user_answer_created_successfully", response)
}

// @Summary     Get a user answer by ID
// @Description Retrieve a specific user answer by its ID
// @Tags        user-answers
// @Accept      json
// @Produce     json
// @Param       id path int true "User Answer ID"
// @Success     200 {object} Response{data=UserAnswerResponse} "User answer retrieved successfully"
// @Failure     400 {object} Response "Invalid answer ID"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     404 {object} Response "User answer not found"
// @Failure     500 {object} Response "Failed to retrieve user answer"
// @Security    ApiKeyAuth
// @Router      /api/v1/user-answers/{id} [get]
func (server *Server) getUserAnswer(ctx *gin.Context) {
	var req getUserAnswerRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_answer_id", err)
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
	cacheKey := fmt.Sprintf("user_answer:%d", req.UserAnswerID)
	if server.serviceCache != nil {
		var cachedBytes []byte
		if err := server.serviceCache.Get(ctx, cacheKey, &cachedBytes); err == nil {
			var userAnswerResp UserAnswerResponse
			if err := json.Unmarshal(cachedBytes, &userAnswerResp); err == nil {
				SuccessResponse(ctx, http.StatusOK, "user_answer_retrieved_successfully", userAnswerResp)
				return
			}
		}
	}

	userAnswer, err := server.store.GetUserAnswer(ctx, req.UserAnswerID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "user_answer_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_user_answer", err)
		return
	}

	// Verify the answer belongs to user's attempt
	_, err = server.store.GetExamAttemptByUser(ctx, db.GetExamAttemptByUserParams{
		AttemptID: userAnswer.AttemptID,
		UserID:    authPayload.ID,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "user_answer_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_verify_answer_ownership", err)
		return
	}

	response := NewUserAnswerResponse(userAnswer)

	// Cache the results
	if server.serviceCache != nil {
		go func() {
			if responseBytes, err := json.Marshal(response); err == nil {
				server.serviceCache.Set(ctx, cacheKey, responseBytes, 30*time.Minute)
			}
		}()
	}

	SuccessResponse(ctx, http.StatusOK, "user_answer_retrieved_successfully", response)
}

// @Summary     Update a user answer
// @Description Update a user's answer for a question
// @Tags        user-answers
// @Accept      json
// @Produce     json
// @Param       id path int true "User Answer ID"
// @Param       answer body map[string]string true "Updated answer data"
// @Success     200 {object} Response{data=UserAnswerResponse} "Answer updated successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     404 {object} Response "Answer not found"
// @Failure     500 {object} Response "Failed to update answer"
// @Security    ApiKeyAuth
// @Router      /api/v1/user-answers/{id} [put]
func (server *Server) updateUserAnswer(ctx *gin.Context) {
	var req getUserAnswerRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_answer_id", err)
		return
	}

	var updateReq struct {
		SelectedAnswer string `json:"selected_answer" binding:"required"`
	}
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

	// Get existing answer to verify ownership
	userAnswer, err := server.store.GetUserAnswer(ctx, req.UserAnswerID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "user_answer_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_user_answer", err)
		return
	}

	// Verify the answer belongs to user's attempt
	_, err = server.store.GetExamAttemptByUser(ctx, db.GetExamAttemptByUserParams{
		AttemptID: userAnswer.AttemptID,
		UserID:    authPayload.ID,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "user_answer_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_verify_answer_ownership", err)
		return
	}

	// Get question to check correct answer
	question, err := server.store.GetQuestion(ctx, userAnswer.QuestionID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_question", err)
		return
	}

	// Determine if new answer is correct
	isCorrect := updateReq.SelectedAnswer == question.TrueAnswer

	// Update the user answer
	updatedAnswer, err := server.store.UpdateUserAnswer(ctx, db.UpdateUserAnswerParams{
		UserAnswerID:   req.UserAnswerID,
		SelectedAnswer: updateReq.SelectedAnswer,
		IsCorrect:      isCorrect,
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_update_user_answer", err)
		return
	}

	// Clear user cache
	if server.serviceCache != nil {
		go func() {
			server.ClearUserCache(int64(authPayload.ID))
		}()
	}

	response := NewUserAnswerResponse(updatedAnswer)
	SuccessResponse(ctx, http.StatusOK, "user_answer_updated_successfully", response)
}

// @Summary     Get answers by attempt
// @Description Get all answers for a specific exam attempt
// @Tags        user-answers
// @Accept      json
// @Produce     json
// @Param       id path int true "Attempt ID"
// @Success     200 {object} Response{data=AttemptAnswersResponse} "Answers retrieved successfully"
// @Failure     400 {object} Response "Invalid attempt ID"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     404 {object} Response "Attempt not found"
// @Failure     500 {object} Response "Failed to retrieve answers"
// @Security    ApiKeyAuth
// @Router      /api/v1/exam-attempts/{id}/answers [get]
func (server *Server) getUserAnswersByAttempt(ctx *gin.Context) {
	attemptIDStr := ctx.Param("id")
	attemptID, err := strconv.ParseInt(attemptIDStr, 10, 32)
	if err != nil {
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

	// Check cache first
	cacheKey := fmt.Sprintf("attempt_answers:%d", attemptID)
	if server.serviceCache != nil {
		var cachedBytes []byte
		if err := server.serviceCache.Get(ctx, cacheKey, &cachedBytes); err == nil {
			var answersResp AttemptAnswersResponse
			if err := json.Unmarshal(cachedBytes, &answersResp); err == nil {
				SuccessResponse(ctx, http.StatusOK, "attempt_answers_retrieved_successfully", answersResp)
				return
			}
		}
	}

	// Verify the attempt belongs to the user
	_, err = server.store.GetExamAttemptByUser(ctx, db.GetExamAttemptByUserParams{
		AttemptID: int32(attemptID),
		UserID:    authPayload.ID,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "exam_attempt_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_verify_exam_attempt", err)
		return
	}

	// Get answers with question details
	answersWithQuestions, err := server.store.ListUserAnswersByAttemptWithQuestions(ctx, int32(attemptID))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_answers", err)
		return
	}

	// Count correct answers
	correctCount := int32(0)
	answers := make([]UserAnswerWithQuestionResponse, len(answersWithQuestions))

	for i, answerWithQuestion := range answersWithQuestions {
		answers[i] = NewUserAnswerWithQuestionResponse(answerWithQuestion)
		if answerWithQuestion.IsCorrect {
			correctCount++
		}
	}

	response := AttemptAnswersResponse{
		AttemptID:     int32(attemptID),
		TotalAnswered: int32(len(answersWithQuestions)),
		CorrectCount:  correctCount,
		Answers:       answers,
	}

	// Cache the results
	if server.serviceCache != nil {
		go func() {
			if responseBytes, err := json.Marshal(response); err == nil {
				server.serviceCache.Set(ctx, cacheKey, responseBytes, 10*time.Minute)
			}
		}()
	}

	SuccessResponse(ctx, http.StatusOK, "attempt_answers_retrieved_successfully", response)
}

// @Summary     Get attempt score
// @Description Get scoring information for an exam attempt
// @Tags        user-answers
// @Accept      json
// @Produce     json
// @Param       id path int true "Attempt ID"
// @Success     200 {object} Response{data=AttemptScoreResponse} "Score retrieved successfully"
// @Failure     400 {object} Response "Invalid attempt ID"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     404 {object} Response "Attempt not found"
// @Failure     500 {object} Response "Failed to retrieve score"
// @Security    ApiKeyAuth
// @Router      /api/v1/exam-attempts/{id}/score [get]
func (server *Server) getAttemptScore(ctx *gin.Context) {
	attemptIDStr := ctx.Param("id")
	attemptID, err := strconv.ParseInt(attemptIDStr, 10, 32)
	if err != nil {
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

	// Check cache first
	cacheKey := fmt.Sprintf("attempt_score:%d", attemptID)
	if server.serviceCache != nil {
		var cachedBytes []byte
		if err := server.serviceCache.Get(ctx, cacheKey, &cachedBytes); err == nil {
			var scoreResp AttemptScoreResponse
			if err := json.Unmarshal(cachedBytes, &scoreResp); err == nil {
				SuccessResponse(ctx, http.StatusOK, "attempt_score_retrieved_successfully", scoreResp)
				return
			}
		}
	}

	// Verify the attempt belongs to the user
	_, err = server.store.GetExamAttemptByUser(ctx, db.GetExamAttemptByUserParams{
		AttemptID: int32(attemptID),
		UserID:    authPayload.ID,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "exam_attempt_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_verify_exam_attempt", err)
		return
	}

	// Get score data
	scoreData, err := server.store.GetAttemptScore(ctx, int32(attemptID))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_attempt_score", err)
		return
	}

	calculatedScore, err := strconv.ParseFloat(scoreData.CalculatedScore, 64)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "invalid_calculated_score_format", err)
		return
	}
	response := AttemptScoreResponse{
		AttemptID:       int32(attemptID),
		TotalQuestions:  int32(scoreData.TotalQuestions),
		CorrectAnswers:  int32(scoreData.CorrectAnswers),
		CalculatedScore: calculatedScore,
	}

	// Cache the results
	if server.serviceCache != nil {
		go func() {
			if responseBytes, err := json.Marshal(response); err == nil {
				server.serviceCache.Set(ctx, cacheKey, responseBytes, 15*time.Minute)
			}
		}()
	}

	SuccessResponse(ctx, http.StatusOK, "attempt_score_retrieved_successfully", response)
}

// @Summary     Delete a user answer
// @Description Delete a user's answer (admin only or own incomplete attempts)
// @Tags        user-answers
// @Accept      json
// @Produce     json
// @Param       id path int true "User Answer ID"
// @Success     200 {object} Response "Answer deleted successfully"
// @Failure     400 {object} Response "Invalid answer ID"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     403 {object} Response "Access denied"
// @Failure     404 {object} Response "Answer not found"
// @Failure     500 {object} Response "Failed to delete answer"
// @Security    ApiKeyAuth
// @Router      /api/v1/user-answers/{id} [delete]
func (server *Server) deleteUserAnswer(ctx *gin.Context) {
	var req getUserAnswerRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_answer_id", err)
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

	// Get existing answer to verify ownership
	userAnswer, err := server.store.GetUserAnswer(ctx, req.UserAnswerID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "user_answer_not_found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_retrieve_user_answer", err)
		return
	}

	// Check if user is admin or if it's their own answer
	isAdmin, err := server.IsUserAdmin(ctx, authPayload.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_check_admin_status", err)
		return
	}

	if !isAdmin {
		// Non-admin users can only delete their own answers from incomplete attempts
		attempt, err := server.store.GetExamAttemptByUser(ctx, db.GetExamAttemptByUserParams{
			AttemptID: userAnswer.AttemptID,
			UserID:    authPayload.ID,
		})
		if err != nil {
			if err == sql.ErrNoRows {
				ErrorResponse(ctx, http.StatusNotFound, "user_answer_not_found", err)
				return
			}
			ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_verify_answer_ownership", err)
			return
		}

		// Only allow deletion from in-progress attempts
		if attempt.Status != db.ExamStatusEnumInProgress {
			ErrorResponse(ctx, http.StatusForbidden, "cannot_delete_answer_from_completed_attempt", nil)
			return
		}
	}

	// Delete the user answer
	err = server.store.DeleteUserAnswer(ctx, req.UserAnswerID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "failed_to_delete_user_answer", err)
		return
	}

	// Clear user cache
	if server.serviceCache != nil {
		go func() {
			server.ClearUserCache(int64(authPayload.ID))
		}()
	}

	logger.Info("User answer %d deleted by user %d", req.UserAnswerID, authPayload.ID)
	SuccessResponse(ctx, http.StatusOK, "user_answer_deleted_successfully", nil)
}
