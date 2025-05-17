package api

import (
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
)

// ExamResponse defines the structure for exam information returned to clients.
type ExamResponse struct {
	ExamID           int32  `json:"exam_id"`
	Title            string `json:"title"`
	TimeLimitMinutes int32  `json:"time_limit_minutes"`
	IsUnlocked       bool   `json:"is_unlocked"`
}

// NewExamResponse creates an ExamResponse from a db.Exam model
func NewExamResponse(exam db.Exam) ExamResponse {
	return ExamResponse{
		ExamID:           exam.ExamID,
		Title:            exam.Title,
		TimeLimitMinutes: exam.TimeLimitMinutes,
		IsUnlocked:       exam.IsUnlocked,
	}
}

// createExamRequest defines the structure for creating a new exam
type createExamRequest struct {
	Title            string `json:"title" binding:"required"`
	TimeLimitMinutes int32  `json:"time_limit_minutes" binding:"required,min=1"`
	IsUnlocked       bool   `json:"is_unlocked"`
}

// @Summary     Create a new exam
// @Description Add a new exam to the database
// @Tags        exams
// @Accept      json
// @Produce     json
// @Param       exam body createExamRequest true "Exam object to create"
// @Success     201 {object} Response{data=ExamResponse} "Exam created successfully"
// @Failure     400 {object} Response "Invalid request body"
// @Failure     500 {object} Response "Failed to create exam"
// @Security    ApiKeyAuth
// @Router      /api/v1/exams [post]
func (server *Server) createExam(ctx *gin.Context) {
	var req createExamRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	arg := db.CreateExamParams{
		Title:            req.Title,
		TimeLimitMinutes: req.TimeLimitMinutes,
		IsUnlocked:       req.IsUnlocked,
	}

	exam, err := server.store.CreateExam(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create exam", err)
		return
	}

	SuccessResponse(ctx, http.StatusCreated, "Exam created successfully", NewExamResponse(exam))
}

// getExamRequest defines the structure for requests to get an exam by ID
type getExamRequest struct {
	ExamID int32 `uri:"id" binding:"required,min=1"`
}

// @Summary     Get an exam by ID
// @Description Retrieve a specific exam entry by its ID
// @Tags        exams
// @Accept      json
// @Produce     json
// @Param       id path int true "Exam ID"
// @Success     200 {object} Response{data=ExamResponse} "Exam retrieved successfully"
// @Failure     400 {object} Response "Invalid exam ID"
// @Failure     404 {object} Response "Exam not found"
// @Failure     500 {object} Response "Failed to retrieve exam"
// @Router      /api/v1/exams/{id} [get]
func (server *Server) getExam(ctx *gin.Context) {
	var req getExamRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid exam ID", err)
		return
	}

	exam, err := server.store.GetExam(ctx, req.ExamID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Exam not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve exam", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Exam retrieved successfully", NewExamResponse(exam))
}

// listExamsRequest defines the structure for listing exams
type listExamsRequest struct {
	Limit  int32 `form:"limit,default=10" binding:"min=1,max=100"`
	Offset int32 `form:"offset,default=0" binding:"min=0"`
}

// @Summary     List exams
// @Description Get a list of all exams with pagination
// @Tags        exams
// @Accept      json
// @Produce     json
// @Param       limit query int false "Limit" default(10)
// @Param       offset query int false "Offset" default(0)
// @Success     200 {object} Response{data=[]ExamResponse} "Exams retrieved successfully"
// @Failure     400 {object} Response "Invalid query parameters"
// @Failure     500 {object} Response "Failed to retrieve exams"
// @Router      /api/v1/exams [get]
func (server *Server) listExams(ctx *gin.Context) {
	var req listExamsRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
		return
	}

	exams, err := server.store.ListExams(ctx)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve exams", err)
		return
	}

	var examResponses []ExamResponse
	for _, exam := range exams {
		examResponses = append(examResponses, NewExamResponse(exam))
	}

	SuccessResponse(ctx, http.StatusOK, "Exams retrieved successfully", examResponses)
}

// updateExamRequest defines the structure for updating an existing exam
type updateExamRequest struct {
	Title            *string `json:"title,omitempty"`
	TimeLimitMinutes *int32  `json:"time_limit_minutes,omitempty" binding:"omitempty,min=1"`
	IsUnlocked       *bool   `json:"is_unlocked,omitempty"`
}

// @Summary     Update an exam
// @Description Update an existing exam by ID
// @Tags        exams
// @Accept      json
// @Produce     json
// @Param       id path int true "Exam ID"
// @Param       exam body updateExamRequest true "Exam fields to update"
// @Success     200 {object} Response{data=ExamResponse} "Exam updated successfully"
// @Failure     400 {object} Response "Invalid request body or exam ID"
// @Failure     404 {object} Response "Exam not found"
// @Failure     500 {object} Response "Failed to update exam"
// @Security    ApiKeyAuth
// @Router      /api/v1/exams/{id} [put]
func (server *Server) updateExam(ctx *gin.Context) {
	examID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid exam ID", err)
		return
	}

	var req updateExamRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Get existing exam to update only provided fields
	existingExam, err := server.store.GetExam(ctx, int32(examID))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Exam not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve exam for update", err)
		return
	}

	// Prepare update parameters
	arg := db.UpdateExamParams{
		ExamID:           int32(examID),
		Title:            existingExam.Title,
		TimeLimitMinutes: existingExam.TimeLimitMinutes,
		IsUnlocked:       existingExam.IsUnlocked,
	}

	// Update only provided fields
	if req.Title != nil {
		arg.Title = *req.Title
	}
	if req.TimeLimitMinutes != nil {
		arg.TimeLimitMinutes = *req.TimeLimitMinutes
	}
	if req.IsUnlocked != nil {
		arg.IsUnlocked = *req.IsUnlocked
	}

	exam, err := server.store.UpdateExam(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update exam", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Exam updated successfully", NewExamResponse(exam))
}

// @Summary     Delete an exam
// @Description Delete a specific exam by its ID
// @Tags        exams
// @Accept      json
// @Produce     json
// @Param       id path int true "Exam ID"
// @Success     200 {object} Response "Exam deleted successfully"
// @Failure     400 {object} Response "Invalid exam ID"
// @Failure     500 {object} Response "Failed to delete exam"
// @Security    ApiKeyAuth
// @Router      /api/v1/exams/{id} [delete]
func (server *Server) deleteExam(ctx *gin.Context) {
	examID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid exam ID", err)
		return
	}

	err = server.store.DeleteExam(ctx, int32(examID))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete exam", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Exam deleted successfully", nil)
}
