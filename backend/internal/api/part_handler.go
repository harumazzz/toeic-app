package api

import (
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
)

// PartResponse defines the structure for part information returned to clients.
type PartResponse struct {
	PartID int32  `json:"part_id"`
	ExamID int32  `json:"exam_id"`
	Title  string `json:"title"`
}

// NewPartResponse creates a PartResponse from a db.Part model
func NewPartResponse(part db.Part) PartResponse {
	return PartResponse{
		PartID: part.PartID,
		ExamID: part.ExamID,
		Title:  part.Title,
	}
}

// createPartRequest defines the structure for creating a new part
type createPartRequest struct {
	ExamID int32  `json:"exam_id" binding:"required,min=1"`
	Title  string `json:"title" binding:"required"`
}

// @Summary     Create a new part
// @Description Add a new part to an exam
// @Tags        parts
// @Accept      json
// @Produce     json
// @Param       part body createPartRequest true "Part object to create"
// @Success     201 {object} Response{data=PartResponse} "Part created successfully"
// @Failure     400 {object} Response "Invalid request body"
// @Failure     500 {object} Response "Failed to create part"
// @Security    ApiKeyAuth
// @Router      /api/v1/parts [post]
func (server *Server) createPart(ctx *gin.Context) {
	var req createPartRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	arg := db.CreatePartParams{
		ExamID: req.ExamID,
		Title:  req.Title,
	}

	part, err := server.store.CreatePart(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create part", err)
		return
	}

	SuccessResponse(ctx, http.StatusCreated, "Part created successfully", NewPartResponse(part))
}

// getPartRequest defines the structure for requests to get a part by ID
type getPartRequest struct {
	PartID int32 `uri:"id" binding:"required,min=1"`
}

// @Summary     Get a part by ID
// @Description Retrieve a specific part by its ID
// @Tags        parts
// @Accept      json
// @Produce     json
// @Param       id path int true "Part ID"
// @Success     200 {object} Response{data=PartResponse} "Part retrieved successfully"
// @Failure     400 {object} Response "Invalid part ID"
// @Failure     404 {object} Response "Part not found"
// @Failure     500 {object} Response "Failed to retrieve part"
// @Router      /api/v1/parts/{id} [get]
func (server *Server) getPart(ctx *gin.Context) {
	var req getPartRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid part ID", err)
		return
	}

	part, err := server.store.GetPart(ctx, req.PartID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Part not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve part", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Part retrieved successfully", NewPartResponse(part))
}

// listPartsByExamRequest defines the structure for listing parts by exam
type listPartsByExamRequest struct {
	ExamID int32 `uri:"exam_id" binding:"required,min=1"`
}

// @Summary     List parts by exam
// @Description Get a list of all parts for a specific exam
// @Tags        parts
// @Accept      json
// @Produce     json
// @Param       exam_id path int true "Exam ID"
// @Success     200 {object} Response{data=[]PartResponse} "Parts retrieved successfully"
// @Failure     400 {object} Response "Invalid exam ID"
// @Failure     500 {object} Response "Failed to retrieve parts"
// @Router      /api/v1/exam-parts/{exam_id} [get]
func (server *Server) listPartsByExam(ctx *gin.Context) {
	var req listPartsByExamRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid exam ID", err)
		return
	}

	parts, err := server.store.ListPartsByExam(ctx, req.ExamID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve parts", err)
		return
	}

	var partResponses []PartResponse
	for _, part := range parts {
		partResponses = append(partResponses, NewPartResponse(part))
	}

	SuccessResponse(ctx, http.StatusOK, "Parts retrieved successfully", partResponses)
}

// updatePartRequest defines the structure for updating an existing part
type updatePartRequest struct {
	ExamID *int32  `json:"exam_id,omitempty" binding:"omitempty,min=1"`
	Title  *string `json:"title,omitempty"`
}

// @Summary     Update a part
// @Description Update an existing part by ID
// @Tags        parts
// @Accept      json
// @Produce     json
// @Param       id path int true "Part ID"
// @Param       part body updatePartRequest true "Part fields to update"
// @Success     200 {object} Response{data=PartResponse} "Part updated successfully"
// @Failure     400 {object} Response "Invalid request body or part ID"
// @Failure     404 {object} Response "Part not found"
// @Failure     500 {object} Response "Failed to update part"
// @Security    ApiKeyAuth
// @Router      /api/v1/parts/{id} [put]
func (server *Server) updatePart(ctx *gin.Context) {
	partID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid part ID", err)
		return
	}

	var req updatePartRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Get existing part to update only provided fields
	existingPart, err := server.store.GetPart(ctx, int32(partID))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Part not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve part for update", err)
		return
	}

	// Prepare update parameters
	arg := db.UpdatePartParams{
		PartID: int32(partID),
		ExamID: existingPart.ExamID,
		Title:  existingPart.Title,
	}

	// Update only provided fields
	if req.ExamID != nil {
		arg.ExamID = *req.ExamID
	}
	if req.Title != nil {
		arg.Title = *req.Title
	}

	part, err := server.store.UpdatePart(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update part", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Part updated successfully", NewPartResponse(part))
}

// @Summary     Delete a part
// @Description Delete a specific part by its ID
// @Tags        parts
// @Accept      json
// @Produce     json
// @Param       id path int true "Part ID"
// @Success     200 {object} Response "Part deleted successfully"
// @Failure     400 {object} Response "Invalid part ID"
// @Failure     500 {object} Response "Failed to delete part"
// @Security    ApiKeyAuth
// @Router      /api/v1/parts/{id} [delete]
func (server *Server) deletePart(ctx *gin.Context) {
	partID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid part ID", err)
		return
	}

	err = server.store.DeletePart(ctx, int32(partID))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete part", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Part deleted successfully", nil)
}
