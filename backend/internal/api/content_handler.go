package api

import (
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
)

// ContentResponse defines the structure for content information returned to clients.
type ContentResponse struct {
	ContentID   int32  `json:"content_id"`
	PartID      int32  `json:"part_id"`
	Type        string `json:"type"`
	Description string `json:"description"`
}

// NewContentResponse creates a ContentResponse from a db.Content model
func NewContentResponse(content db.Content) ContentResponse {
	return ContentResponse{
		ContentID:   content.ContentID,
		PartID:      content.PartID,
		Type:        content.Type,
		Description: content.Description,
	}
}

// createContentRequest defines the structure for creating new content
type createContentRequest struct {
	PartID      int32  `json:"part_id" binding:"required,min=1"`
	Type        string `json:"type" binding:"required"`
	Description string `json:"description" binding:"required"`
}

// @Summary     Create new content
// @Description Add new content to a part
// @Tags        contents
// @Accept      json
// @Produce     json
// @Param       content body createContentRequest true "Content object to create"
// @Success     201 {object} Response{data=ContentResponse} "Content created successfully"
// @Failure     400 {object} Response "Invalid request body"
// @Failure     500 {object} Response "Failed to create content"
// @Security    ApiKeyAuth
// @Router      /api/v1/contents [post]
func (server *Server) createContent(ctx *gin.Context) {
	var req createContentRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	arg := db.CreateContentParams{
		PartID:      req.PartID,
		Type:        req.Type,
		Description: req.Description,
	}

	content, err := server.store.CreateContent(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create content", err)
		return
	}

	SuccessResponse(ctx, http.StatusCreated, "Content created successfully", NewContentResponse(content))
}

// getContentRequest defines the structure for requests to get content by ID
type getContentRequest struct {
	ContentID int32 `uri:"id" binding:"required,min=1"`
}

// @Summary     Get content by ID
// @Description Retrieve specific content by its ID
// @Tags        contents
// @Accept      json
// @Produce     json
// @Param       id path int true "Content ID"
// @Success     200 {object} Response{data=ContentResponse} "Content retrieved successfully"
// @Failure     400 {object} Response "Invalid content ID"
// @Failure     404 {object} Response "Content not found"
// @Failure     500 {object} Response "Failed to retrieve content"
// @Security    ApiKeyAuth
// @Router      /api/v1/contents/{id} [get]
func (server *Server) getContent(ctx *gin.Context) {
	var req getContentRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid content ID", err)
		return
	}

	content, err := server.store.GetContent(ctx, req.ContentID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Content not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve content", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Content retrieved successfully", NewContentResponse(content))
}

// listContentsByPartRequest defines the structure for listing contents by part
type listContentsByPartRequest struct {
	PartID int32 `uri:"part_id" binding:"required,min=1"`
}

// @Summary     List contents by part
// @Description Get a list of all contents for a specific part
// @Tags        contents
// @Accept      json
// @Produce     json
// @Param       part_id path int true "Part ID"
// @Success     200 {object} Response{data=[]ContentResponse} "Contents retrieved successfully"
// @Failure     400 {object} Response "Invalid part ID"
// @Failure     500 {object} Response "Failed to retrieve contents"
// @Security    ApiKeyAuth
// @Router      /api/v1/part-contents/{part_id} [get]
func (server *Server) listContentsByPart(ctx *gin.Context) {
	var req listContentsByPartRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid part ID", err)
		return
	}

	contents, err := server.store.ListContentsByPart(ctx, req.PartID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve contents", err)
		return
	}

	var contentResponses []ContentResponse
	for _, content := range contents {
		contentResponses = append(contentResponses, NewContentResponse(content))
	}
	// Ensure we return an empty array instead of null if no results
	if contentResponses == nil {
		contentResponses = []ContentResponse{}
	}
	SuccessResponse(ctx, http.StatusOK, "Contents retrieved successfully", contentResponses)
}

// updateContentRequest defines the structure for updating existing content
type updateContentRequest struct {
	PartID      *int32  `json:"part_id,omitempty" binding:"omitempty,min=1"`
	Type        *string `json:"type,omitempty"`
	Description *string `json:"description,omitempty"`
}

// @Summary     Update content
// @Description Update existing content by ID
// @Tags        contents
// @Accept      json
// @Produce     json
// @Param       id path int true "Content ID"
// @Param       content body updateContentRequest true "Content fields to update"
// @Success     200 {object} Response{data=ContentResponse} "Content updated successfully"
// @Failure     400 {object} Response "Invalid request body or content ID"
// @Failure     404 {object} Response "Content not found"
// @Failure     500 {object} Response "Failed to update content"
// @Security    ApiKeyAuth
// @Router      /api/v1/contents/{id} [put]
func (server *Server) updateContent(ctx *gin.Context) {
	contentID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid content ID", err)
		return
	}

	var req updateContentRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Get existing content to update only provided fields
	existingContent, err := server.store.GetContent(ctx, int32(contentID))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Content not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve content for update", err)
		return
	}

	// Prepare update parameters
	arg := db.UpdateContentParams{
		ContentID:   int32(contentID),
		PartID:      existingContent.PartID,
		Type:        existingContent.Type,
		Description: existingContent.Description,
	}

	// Update only provided fields
	if req.PartID != nil {
		arg.PartID = *req.PartID
	}
	if req.Type != nil {
		arg.Type = *req.Type
	}
	if req.Description != nil {
		arg.Description = *req.Description
	}

	content, err := server.store.UpdateContent(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update content", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Content updated successfully", NewContentResponse(content))
}

// @Summary     Delete content
// @Description Delete specific content by its ID
// @Tags        contents
// @Accept      json
// @Produce     json
// @Param       id path int true "Content ID"
// @Success     200 {object} Response "Content deleted successfully"
// @Failure     400 {object} Response "Invalid content ID"
// @Failure     500 {object} Response "Failed to delete content"
// @Security    ApiKeyAuth
// @Router      /api/v1/contents/{id} [delete]
func (server *Server) deleteContent(ctx *gin.Context) {
	contentID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid content ID", err)
		return
	}

	err = server.store.DeleteContent(ctx, int32(contentID))
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete content", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Content deleted successfully", nil)
}
