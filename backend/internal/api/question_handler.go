package api

import (
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
)

// QuestionResponse defines the structure for question information returned to clients.
type QuestionResponse struct {
	QuestionID      int32    `json:"question_id"`
	ContentID       int32    `json:"content_id"`
	Title           string   `json:"title"`
	MediaURL        string   `json:"media_url,omitempty"`
	ImageURL        string   `json:"image_url,omitempty"`
	PossibleAnswers []string `json:"possible_answers"`
	TrueAnswer      string   `json:"true_answer"`
	Explanation     string   `json:"explanation"`
	Keywords        string   `json:"keywords,omitempty"`
}

// NewQuestionResponse creates a QuestionResponse from a db.Question model
func NewQuestionResponse(question db.Question) QuestionResponse {
	var mediaURL, imageURL, keywords string
	if question.MediaUrl.Valid {
		mediaURL = question.MediaUrl.String
	}
	if question.ImageUrl.Valid {
		imageURL = question.ImageUrl.String
	}
	if question.Keywords.Valid {
		keywords = question.Keywords.String
	}

	return QuestionResponse{
		QuestionID:      question.QuestionID,
		ContentID:       question.ContentID,
		Title:           question.Title,
		MediaURL:        mediaURL,
		ImageURL:        imageURL,
		PossibleAnswers: question.PossibleAnswers,
		TrueAnswer:      question.TrueAnswer,
		Explanation:     question.Explanation,
		Keywords:        keywords,
	}
}

// createQuestionRequest defines the structure for creating a new question
type createQuestionRequest struct {
	ContentID       int32    `json:"content_id" binding:"required,min=1"`
	Title           string   `json:"title" binding:"required"`
	MediaURL        string   `json:"media_url,omitempty"`
	ImageURL        string   `json:"image_url,omitempty"`
	PossibleAnswers []string `json:"possible_answers" binding:"required,min=1"`
	TrueAnswer      string   `json:"true_answer" binding:"required"`
	Explanation     string   `json:"explanation" binding:"required"`
	Keywords        string   `json:"keywords,omitempty"`
}

// @Summary     Create a new question
// @Description Add a new question to content
// @Tags        questions
// @Accept      json
// @Produce     json
// @Param       question body createQuestionRequest true "Question object to create"
// @Success     201 {object} Response{data=QuestionResponse} "Question created successfully"
// @Failure     400 {object} Response "Invalid request body"
// @Failure     500 {object} Response "Failed to create question"
// @Security    ApiKeyAuth
// @Router      /api/v1/questions [post]
func (server *Server) createQuestion(ctx *gin.Context) {
	var req createQuestionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Handle optional string fields
	var mediaURL, imageURL, keywords sql.NullString
	if req.MediaURL != "" {
		mediaURL = sql.NullString{String: req.MediaURL, Valid: true}
	}
	if req.ImageURL != "" {
		imageURL = sql.NullString{String: req.ImageURL, Valid: true}
	}
	if req.Keywords != "" {
		keywords = sql.NullString{String: req.Keywords, Valid: true}
	}

	arg := db.CreateQuestionParams{
		ContentID:       req.ContentID,
		Title:           req.Title,
		MediaUrl:        mediaURL,
		ImageUrl:        imageURL,
		PossibleAnswers: req.PossibleAnswers,
		TrueAnswer:      req.TrueAnswer,
		Explanation:     req.Explanation,
		Keywords:        keywords,
	}

	question, err := server.store.CreateQuestion(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create question", err)
		return
	}

	SuccessResponse(ctx, http.StatusCreated, "Question created successfully", NewQuestionResponse(question))
}

// getQuestionRequest defines the structure for requests to get a question by ID
type getQuestionRequest struct {
	QuestionID int32 `uri:"id" binding:"required,min=1"`
}

// @Summary     Get a question by ID
// @Description Retrieve a specific question by its ID
// @Tags        questions
// @Accept      json
// @Produce     json
// @Param       id path int true "Question ID"
// @Success     200 {object} Response{data=QuestionResponse} "Question retrieved successfully"
// @Failure     400 {object} Response "Invalid question ID"
// @Failure     404 {object} Response "Question not found"
// @Failure     500 {object} Response "Failed to retrieve question"
// @Router      /api/v1/questions/{id} [get]
func (server *Server) getQuestion(ctx *gin.Context) {
	var req getQuestionRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid question ID", err)
		return
	}

	question, err := server.store.GetQuestion(ctx, req.QuestionID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Question not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve question", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Question retrieved successfully", NewQuestionResponse(question))
}

// listQuestionsByContentRequest defines the structure for listing questions by content
type listQuestionsByContentRequest struct {
	ContentID int32 `uri:"content_id" binding:"required,min=1"`
}

// @Summary     List questions by content
// @Description Get a list of all questions for a specific content
// @Tags        questions
// @Accept      json
// @Produce     json
// @Param       content_id path int true "Content ID"
// @Success     200 {object} Response{data=[]QuestionResponse} "Questions retrieved successfully"
// @Failure     400 {object} Response "Invalid content ID"
// @Failure     500 {object} Response "Failed to retrieve questions"
// @Router      /api/v1/content-questions/{content_id} [get]
func (server *Server) listQuestionsByContent(ctx *gin.Context) {
	var req listQuestionsByContentRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid content ID", err)
		return
	}

	questions, err := server.store.ListQuestionsByContent(ctx, req.ContentID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve questions", err)
		return
	}

	var questionResponses []QuestionResponse
	for _, question := range questions {
		questionResponses = append(questionResponses, NewQuestionResponse(question))
	}

	SuccessResponse(ctx, http.StatusOK, "Questions retrieved successfully", questionResponses)
}

// updateQuestionRequest defines the structure for updating an existing question
type updateQuestionRequest struct {
	ContentID       *int32   `json:"content_id,omitempty" binding:"omitempty,min=1"`
	Title           *string  `json:"title,omitempty"`
	MediaURL        *string  `json:"media_url,omitempty"`
	ImageURL        *string  `json:"image_url,omitempty"`
	PossibleAnswers []string `json:"possible_answers,omitempty" binding:"omitempty,min=1"`
	TrueAnswer      *string  `json:"true_answer,omitempty"`
	Explanation     *string  `json:"explanation,omitempty"`
	Keywords        *string  `json:"keywords,omitempty"`
}

// @Summary     Update a question
// @Description Update an existing question by ID
// @Tags        questions
// @Accept      json
// @Produce     json
// @Param       id path int true "Question ID"
// @Param       question body updateQuestionRequest true "Question fields to update"
// @Success     200 {object} Response{data=QuestionResponse} "Question updated successfully"
// @Failure     400 {object} Response "Invalid request body or question ID"
// @Failure     404 {object} Response "Question not found"
// @Failure     500 {object} Response "Failed to update question"
// @Security    ApiKeyAuth
// @Router      /api/v1/questions/{id} [put]
func (server *Server) updateQuestion(ctx *gin.Context) {
	questionID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid question ID", err)
		return
	}

	var req updateQuestionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Get existing question to update only provided fields
	existingQuestion, err := server.store.GetQuestion(ctx, int32(questionID))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Question not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve question for update", err)
		return
	}

	// Prepare update parameters
	arg := db.UpdateQuestionParams{
		QuestionID:      int32(questionID),
		ContentID:       existingQuestion.ContentID,
		Title:           existingQuestion.Title,
		MediaUrl:        existingQuestion.MediaUrl,
		ImageUrl:        existingQuestion.ImageUrl,
		PossibleAnswers: existingQuestion.PossibleAnswers,
		TrueAnswer:      existingQuestion.TrueAnswer,
		Explanation:     existingQuestion.Explanation,
		Keywords:        existingQuestion.Keywords,
	}

	// Update only provided fields
	if req.ContentID != nil {
		arg.ContentID = *req.ContentID
	}
	if req.Title != nil {
		arg.Title = *req.Title
	}
	if req.MediaURL != nil {
		arg.MediaUrl = sql.NullString{String: *req.MediaURL, Valid: true}
	}
	if req.ImageURL != nil {
		arg.ImageUrl = sql.NullString{String: *req.ImageURL, Valid: true}
	}
	if len(req.PossibleAnswers) > 0 {
		arg.PossibleAnswers = req.PossibleAnswers
	}
	if req.TrueAnswer != nil {
		arg.TrueAnswer = *req.TrueAnswer
	}
	if req.Explanation != nil {
		arg.Explanation = *req.Explanation
	}
	if req.Keywords != nil {
		arg.Keywords = sql.NullString{String: *req.Keywords, Valid: true}
	}

	question, err := server.store.UpdateQuestion(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update question", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Question updated successfully", NewQuestionResponse(question))
}

// @Summary     Delete a question
// @Description Delete a specific question by its ID
// @Tags        questions
// @Accept      json
// @Produce     json
// @Param       id path int true "Question ID"
// @Success     200 {object} Response "Question deleted successfully"
// @Failure     400 {object} Response "Invalid question ID"
// @Failure     500 {object} Response "Failed to delete question"
// @Security    ApiKeyAuth
// @Router      /api/v1/questions/{id} [delete]
func (server *Server) deleteQuestion(ctx *gin.Context) {
	questionID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid question ID", err)
		return
	}

	err = server.store.DeleteQuestion(ctx, int32(questionID))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete question", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Question deleted successfully", nil)
}
