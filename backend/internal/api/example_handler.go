package api

import (
	"database/sql"
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
)

type createExampleRequest struct {
	Title   string `json:"title" binding:"required"`
	Meaning string `json:"meaning" binding:"required"`
}

type ExampleResponse struct {
	ID      int32  `json:"id"`
	Title   string `json:"title"`
	Meaning string `json:"meaning"`
}

// NewExampleResponse creates a response from db.Example model
func NewExampleResponse(example db.Example) ExampleResponse {
	return ExampleResponse{
		ID:      example.ID,
		Title:   example.Title,
		Meaning: example.Meaning,
	}
}

// @Summary Create example
// @Description Create a new example
// @Tags examples
// @Accept json
// @Produce json
// @Param request body createExampleRequest true "Example details"
// @Success 201 {object} Response{data=ExampleResponse} "Example created successfully"
// @Failure 400 {object} Response "Invalid request body"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Failed to create example"
// @Security ApiKeyAuth
// @Router /examples [post]
func (server *Server) createExample(ctx *gin.Context) {
	var req createExampleRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	arg := db.CreateExampleParams{
		Title:   req.Title,
		Meaning: req.Meaning,
	}

	example, err := server.store.CreateExample(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create example", err)
		return
	}

	SuccessResponse(ctx, http.StatusCreated, "Example created successfully", NewExampleResponse(example))
}

// @Summary Get example by ID
// @Description Get details of an example by its ID
// @Tags examples
// @Produce json
// @Param id path int true "Example ID"
// @Success 200 {object} Response{data=ExampleResponse} "Example retrieved successfully"
// @Failure 400 {object} Response "Invalid example ID"
// @Failure 404 {object} Response "Example not found"
// @Failure 500 {object} Response "Failed to retrieve example"
// @Router /examples/{id} [get]
func (server *Server) getExample(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid example ID", err)
		return
	}

	example, err := server.store.GetExample(ctx, int32(id))
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			ErrorResponse(ctx, http.StatusNotFound, "Example not found", err)
			return
		}

		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve example", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Example retrieved successfully", NewExampleResponse(example))
}

// @Summary List examples
// @Description Get a list of all examples
// @Tags examples
// @Produce json
// @Success 200 {object} Response{data=[]ExampleResponse} "Examples retrieved successfully"
// @Failure 500 {object} Response "Failed to retrieve examples"
// @Router /examples [get]
func (server *Server) listExamples(ctx *gin.Context) {
	examples, err := server.store.ListExamples(ctx)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve examples", err)
		return
	}

	var exampleResponses []ExampleResponse
	for _, example := range examples {
		exampleResponses = append(exampleResponses, NewExampleResponse(example))
	}

	SuccessResponse(ctx, http.StatusOK, "Examples retrieved successfully", exampleResponses)
}

type updateExampleRequest struct {
	Title   string `json:"title" binding:"required"`
	Meaning string `json:"meaning" binding:"required"`
}

// @Summary Update example
// @Description Update an existing example
// @Tags examples
// @Accept json
// @Produce json
// @Param id path int true "Example ID"
// @Param request body updateExampleRequest true "Example details"
// @Success 200 {object} Response{data=ExampleResponse} "Example updated successfully"
// @Failure 400 {object} Response "Invalid request body or example ID"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 404 {object} Response "Example not found"
// @Failure 500 {object} Response "Failed to update example"
// @Security ApiKeyAuth
// @Router /examples/{id} [put]
func (server *Server) updateExample(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid example ID", err)
		return
	}

	var req updateExampleRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	arg := db.UpdateExampleParams{
		ID:      int32(id),
		Title:   req.Title,
		Meaning: req.Meaning,
	}

	example, err := server.store.UpdateExample(ctx, arg)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			ErrorResponse(ctx, http.StatusNotFound, "Example not found", err)
			return
		}

		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update example", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Example updated successfully", NewExampleResponse(example))
}

// @Summary Delete example
// @Description Delete an existing example
// @Tags examples
// @Param id path int true "Example ID"
// @Success 200 {object} Response "Example deleted successfully"
// @Failure 400 {object} Response "Invalid example ID"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Failed to delete example"
// @Security ApiKeyAuth
// @Router /examples/{id} [delete]
func (server *Server) deleteExample(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid example ID", err)
		return
	}

	err = server.store.DeleteExample(ctx, int32(id))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete example", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Example deleted successfully", nil)
}
