package api

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/logger"
)

// GrammarExample represents an example in grammar content
// swagger:model
type GrammarExample struct {
	Example *string `json:"e,omitempty"`
}

// GrammarContentElement represents individual content element in grammar
// swagger:model
type GrammarContentElement struct {
	Content  *string          `json:"c,omitempty"`
	Examples []GrammarExample `json:"e,omitempty"`
	Formulas []string         `json:"f,omitempty"`
}

// GrammarContent represents content section in grammar
// swagger:model
type GrammarContent struct {
	Content  []GrammarContentElement `json:"content,omitempty"`
	SubTitle *string                 `json:"sub_title,omitempty"`
}

// GrammarResponse defines the structure for grammar information returned to clients.
// swagger:model
type GrammarResponse struct {
	ID         int32            `json:"id"`
	Level      int32            `json:"level"`
	Title      string           `json:"title"`
	Tag        []string         `json:"tag"`
	GrammarKey string           `json:"grammar_key"`
	Related    []int32          `json:"related"`
	Contents   []GrammarContent `json:"contents,omitempty"`
}

// NewGrammarResponse creates a GrammarResponse from db.Grammar model
func NewGrammarResponse(grammar db.Grammar) GrammarResponse {
	response := GrammarResponse{
		ID:         grammar.ID,
		Level:      grammar.Level,
		Title:      grammar.Title,
		Tag:        grammar.Tag,
		GrammarKey: grammar.GrammarKey,
		Related:    grammar.Related,
	}

	// Parse Contents if it's valid
	if grammar.Contents != nil {
		var contents []GrammarContent
		if err := json.Unmarshal(grammar.Contents, &contents); err == nil {
			response.Contents = contents
		}
	}

	return response
}

// createGrammarRequest defines the structure for creating a new grammar entry.
// swagger:model
type createGrammarRequest struct {
	Level      int32            `json:"level" binding:"required,min=1"`
	Title      string           `json:"title" binding:"required"`
	Tag        []string         `json:"tag" binding:"required"`
	GrammarKey string           `json:"grammar_key" binding:"required"`
	Related    []int32          `json:"related" binding:"required"`
	Contents   []GrammarContent `json:"contents,omitempty"`
}

// @Summary     Create a new grammar
// @Description Add a new grammar to the database.
// @Tags        grammars
// @Accept      json
// @Produce     json
// @Param       grammar body createGrammarRequest true "Grammar object to create"
// @Success     201 {object} Response{data=GrammarResponse} "Grammar created successfully"
// @Failure     400 {object} Response "Invalid request body"
// @Failure     500 {object} Response "Failed to create grammar"
// @Security    ApiKeyAuth
// @Router      /api/v1/grammars [post]
func (server *Server) createGrammar(ctx *gin.Context) {
	var req createGrammarRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	arg := db.CreateGrammarParams{
		Level:      req.Level,
		Title:      req.Title,
		Tag:        req.Tag,
		GrammarKey: req.GrammarKey,
		Related:    req.Related,
		Contents:   toRawMessageFromGrammarContents(req.Contents),
	}

	grammar, err := server.store.CreateGrammar(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create grammar", err)
		return
	}

	SuccessResponse(ctx, http.StatusCreated, "Grammar created successfully", NewGrammarResponse(grammar))
}

// getGrammarRequest defines the structure for requests to get a grammar by ID.
type getGrammarRequest struct {
	ID int32 `uri:"id" binding:"required,min=1"`
}

// @Summary     Get a grammar by ID
// @Description Retrieve a specific grammar entry by its ID.
// @Tags        grammars
// @Accept      json
// @Produce     json
// @Param       id path int true "Grammar ID"
// @Success     200 {object} Response{data=GrammarResponse} "Grammar retrieved successfully"
// @Failure     400 {object} Response "Invalid grammar ID"
// @Failure     404 {object} Response "Grammar not found"
// @Failure     500 {object} Response "Failed to retrieve grammar"
// @Security    ApiKeyAuth
// @Router      /api/v1/grammars/{id} [get]
func (server *Server) getGrammar(ctx *gin.Context) {
	var req getGrammarRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid grammar ID", err)
		return
	}

	grammar, err := server.store.GetGrammar(ctx, req.ID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Grammar not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve grammar", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Grammar retrieved successfully", NewGrammarResponse(grammar))
}

// listGrammarsRequest defines the structure for listing grammars with pagination.
type listGrammarsRequest struct {
	Limit  int32 `form:"limit" binding:"required,min=1,max=100"`
	Offset int32 `form:"offset" binding:"min=0"`
}

// @Summary     List grammars
// @Description Get a list of grammars with pagination.
// @Tags        grammars
// @Accept      json
// @Produce     json
// @Param       limit query int true "Limit" default(10)
// @Param       offset query int false "Offset" default(0)
// @Success     200 {object} Response{data=[]GrammarResponse} "Grammars retrieved successfully"
// @Failure     400 {object} Response "Invalid query parameters"
// @Failure     500 {object} Response "Failed to retrieve grammars"
// @Security    ApiKeyAuth
// @Router      /api/v1/grammars [get]
func (server *Server) listGrammars(ctx *gin.Context) {
	var req listGrammarsRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
		return
	}

	arg := db.ListGrammarsParams{
		Limit:  req.Limit,
		Offset: req.Offset,
	}
	grammars, err := server.store.ListGrammars(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve grammars", err)
		return
	}

	var grammarResponses []GrammarResponse
	for _, grammar := range grammars {
		grammarResponses = append(grammarResponses, NewGrammarResponse(grammar))
	}

	// Ensure we return an empty array instead of null if no results
	if grammarResponses == nil {
		grammarResponses = []GrammarResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "Grammars retrieved successfully", grammarResponses)
}

// updateGrammarRequest defines the structure for updating an existing grammar entry.
// swagger:model
type updateGrammarRequest struct {
	ID         int32            `json:"id" binding:"required,min=1"`
	Level      int32            `json:"level" binding:"omitempty,min=1"`
	Title      string           `json:"title" binding:"omitempty"`
	Tag        []string         `json:"tag" binding:"omitempty"`
	GrammarKey string           `json:"grammar_key" binding:"omitempty"`
	Related    []int32          `json:"related" binding:"omitempty"`
	Contents   []GrammarContent `json:"contents,omitempty"`
}

// toRawMessageFromGrammarContents converts []GrammarContent to json.RawMessage
func toRawMessageFromGrammarContents(contents []GrammarContent) json.RawMessage {
	if contents == nil {
		return nil
	} // Marshal the contents to json.RawMessage
	if len(contents) == 0 {
		return nil
	}
	data, err := json.Marshal(contents)
	if err != nil {
		return nil
	}
	return json.RawMessage(data)
}

// @Summary     Update a grammar
// @Description Update an existing grammar entry by its ID.
// @Tags        grammars
// @Accept      json
// @Produce     json
// @Param       id path int true "Grammar ID"
// @Param       grammar body updateGrammarRequest true "Grammar object with fields to update"
// @Success     200 {object} Response{data=GrammarResponse} "Grammar updated successfully"
// @Failure     400 {object} Response "Invalid request body or grammar ID"
// @Failure     404 {object} Response "Grammar not found"
// @Failure     500 {object} Response "Failed to update grammar"
// @Security    ApiKeyAuth
// @Router      /api/v1/grammars/{id} [put]
func (server *Server) updateGrammar(ctx *gin.Context) {
	var req updateGrammarRequest
	uriID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid grammar ID in URI", err)
		return
	}

	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Ensure the ID in the URI matches the ID in the request body if provided
	if req.ID != 0 && req.ID != int32(uriID) {
		ErrorResponse(ctx, http.StatusBadRequest, "Grammar ID in URI and body mismatch", nil)
		return
	}
	req.ID = int32(uriID) // Use ID from URI

	// Get existing grammar to update only provided fields
	existingGrammar, err := server.store.GetGrammar(ctx, req.ID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Grammar not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve grammar for update", err)
		return
	}

	arg := db.UpdateGrammarParams{
		ID:         req.ID,
		Level:      existingGrammar.Level,
		Title:      existingGrammar.Title,
		Tag:        existingGrammar.Tag,
		GrammarKey: existingGrammar.GrammarKey,
		Related:    existingGrammar.Related,
		Contents:   existingGrammar.Contents,
	}
	if req.Level != 0 {
		arg.Level = req.Level
	}
	if req.Title != "" {
		arg.Title = req.Title
	}
	if len(req.Tag) > 0 {
		arg.Tag = req.Tag
	}
	if req.GrammarKey != "" {
		arg.GrammarKey = req.GrammarKey
	}
	if arg.Related == nil {
		return
	}
	if req.Contents != nil {
		if len(req.Contents) > 0 {
			arg.Contents = toRawMessageFromGrammarContents(req.Contents)
		}
	}
	grammar, err := server.store.UpdateGrammar(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update grammar", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Grammar updated successfully", NewGrammarResponse(grammar))
}

// deleteGrammarRequest defines the structure for requests to delete a grammar by ID.
type deleteGrammarRequest struct {
	ID int32 `uri:"id" binding:"required,min=1"`
}

// @Summary     Delete a grammar
// @Description Delete a specific grammar entry by its ID.
// @Tags        grammars
// @Accept      json
// @Produce     json
// @Param       id path int true "Grammar ID"
// @Success     200 {object} Response "Grammar deleted successfully"
// @Failure     400 {object} Response "Invalid grammar ID"
// @Failure     404 {object} Response "Grammar not found"
// @Failure     500 {object} Response "Failed to delete grammar"
// @Security    ApiKeyAuth
// @Router      /api/v1/grammars/{id} [delete]
func (server *Server) deleteGrammar(ctx *gin.Context) {
	var req deleteGrammarRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid grammar ID", err)
		return
	}

	err := server.store.DeleteGrammar(ctx, req.ID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Grammar not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete grammar", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Grammar deleted successfully", nil)
}

// @Summary     Get a random grammar
// @Description Retrieve a single random grammar entry from the database.
// @Tags        grammars
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=GrammarResponse} "Random grammar retrieved successfully"
// @Failure     500 {object} Response "Failed to retrieve random grammar"
// @Security    ApiKeyAuth
// @Router      /api/v1/grammars/random [get]
func (server *Server) getRandomGrammar(ctx *gin.Context) {
	grammar, err := server.store.GetRandomGrammar(ctx)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve random grammar", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Random grammar retrieved successfully", NewGrammarResponse(grammar))
}

// listGrammarsByLevelRequest defines the structure for listing grammars by level with pagination.
type listGrammarsByLevelRequest struct {
	Level  int32 `form:"level" binding:"required,min=1"`
	Limit  int32 `form:"limit" binding:"required,min=1,max=100"`
	Offset int32 `form:"offset" binding:"min=0"`
}

// @Summary     List grammars by level
// @Description Get a list of grammars filtered by level, with pagination.
// @Tags        grammars
// @Accept      json
// @Produce     json
// @Param       level query int true "Level to filter by"
// @Param       limit query int true "Limit" default(10)
// @Param       offset query int false "Offset" default(0)
// @Success     200 {object} Response{data=[]GrammarResponse} "Grammars retrieved successfully"
// @Failure     400 {object} Response "Invalid query parameters"
// @Failure     500 {object} Response "Failed to retrieve grammars by level"
// @Security    ApiKeyAuth
// @Router      /api/v1/grammars/level [get]
func (server *Server) listGrammarsByLevel(ctx *gin.Context) {
	var req listGrammarsByLevelRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
		return
	}

	arg := db.ListGrammarsByLevelParams{
		Level:  req.Level,
		Limit:  req.Limit,
		Offset: req.Offset,
	}
	grammars, err := server.store.ListGrammarsByLevel(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve grammars by level", err)
		return
	}

	var grammarResponses []GrammarResponse
	for _, grammar := range grammars {
		grammarResponses = append(grammarResponses, NewGrammarResponse(grammar))
	}

	// Ensure we return an empty array instead of null if no results
	if grammarResponses == nil {
		grammarResponses = []GrammarResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "Grammars retrieved successfully for the level", grammarResponses)
}

// listGrammarsByTagRequest defines the structure for listing grammars by tag with pagination.
type listGrammarsByTagRequest struct {
	Tag    string `form:"tag" binding:"required"` // Expecting a single tag as a string
	Limit  int32  `form:"limit" binding:"required,min=1,max=100"`
	Offset int32  `form:"offset" binding:"min=0"`
}

// @Summary     List grammars by tag
// @Description Get a list of grammars filtered by a specific tag, with pagination.
// @Tags        grammars
// @Accept      json
// @Produce     json
// @Param       tag query string true "Tag to filter by"
// @Param       limit query int true "Limit" default(10)
// @Param       offset query int false "Offset" default(0)
// @Success     200 {object} Response{data=[]GrammarResponse} "Grammars retrieved successfully"
// @Failure     400 {object} Response "Invalid query parameters"
// @Failure     500 {object} Response "Failed to retrieve grammars by tag"
// @Security    ApiKeyAuth
// @Router      /api/v1/grammars/tag [get]
func (server *Server) listGrammarsByTag(ctx *gin.Context) {
	var req listGrammarsByTagRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
		return
	}

	arg := db.ListGrammarsByTagParams{
		Tag:    []string{req.Tag}, // SQLC expects a slice of strings for ANY(tag)
		Limit:  req.Limit,
		Offset: req.Offset,
	}
	grammars, err := server.store.ListGrammarsByTag(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve grammars by tag", err)
		return
	}

	var grammarResponses []GrammarResponse
	for _, grammar := range grammars {
		grammarResponses = append(grammarResponses, NewGrammarResponse(grammar))
	}

	// Ensure we return an empty array instead of null if no results
	if grammarResponses == nil {
		grammarResponses = []GrammarResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "Grammars retrieved successfully for the tag", grammarResponses)
}

// searchGrammarsRequest defines the structure for searching grammars with pagination.
type searchGrammarsRequest struct {
	Query  string `form:"query" binding:"required"`
	Limit  int32  `form:"limit" binding:"required,min=1,max=100"`
	Offset int32  `form:"offset" binding:"min=0"`
}

// @Summary     Search grammars
// @Description Search grammars by title, key, or tag, with pagination.
// @Tags        grammars
// @Accept      json
// @Produce     json
// @Param       query query string true "Search query"
// @Param       limit query int true "Limit" default(10)
// @Param       offset query int false "Offset" default(0)
// @Success     200 {object} Response{data=[]GrammarResponse} "Grammars retrieved successfully"
// @Failure     400 {object} Response "Invalid query parameters"
// @Failure     500 {object} Response "Failed to search grammars"
// @Security    ApiKeyAuth
// @Router      /api/v1/grammars/search [get]
func (server *Server) searchGrammars(ctx *gin.Context) {
	var req searchGrammarsRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
		return
	}

	// Try cache first for frequent searches
	cacheKey := fmt.Sprintf("search:grammars:%s:%d:%d", req.Query, req.Limit, req.Offset)
	if server.config.CacheEnabled && server.serviceCache != nil {
		var cachedGrammars []GrammarResponse
		if err := server.serviceCache.Get(ctx, cacheKey, &cachedGrammars); err == nil {
			logger.Debug("Grammar search results retrieved from cache for query: %s", req.Query)
			SuccessResponse(ctx, http.StatusOK, "Grammar search completed successfully", cachedGrammars)
			return
		}
	}

	arg := db.SearchGrammarsParams{
		Column1: sql.NullString{String: req.Query, Valid: true},
		Limit:   req.Limit,
		Offset:  req.Offset,
	}
	grammars, err := server.store.SearchGrammars(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to search grammars", err)
		return
	}

	var grammarResponses []GrammarResponse
	for _, grammar := range grammars {
		grammarResponses = append(grammarResponses, NewGrammarResponse(grammar))
	}

	// Ensure we return an empty array instead of null if no results
	if grammarResponses == nil {
		grammarResponses = []GrammarResponse{}
	}

	// Cache the results for 15 minutes (grammars change less frequently)
	if server.config.CacheEnabled && server.serviceCache != nil && len(grammarResponses) > 0 {
		go func() {
			bgCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()
			if err := server.serviceCache.Set(bgCtx, cacheKey, grammarResponses, 15*time.Minute); err != nil {
				logger.Warn("Failed to cache grammar search results: %v", err)
			}
		}()
	}

	SuccessResponse(ctx, http.StatusOK, "Grammar search completed successfully", grammarResponses)
}

// batchGetGrammarsRequest defines the structure for batch getting grammars by IDs.
type batchGetGrammarsRequest struct {
	IDs []int32 `json:"ids" binding:"required"`
}

// @Summary Batch get grammars by IDs
// @Description Get multiple grammars by their IDs in a single request
// @Tags grammars
// @Accept json
// @Produce json
// @Param request body batchGetGrammarsRequest true "List of grammar IDs"
// @Success 200 {object} Response{data=[]GrammarResponse} "Grammars retrieved successfully"
// @Failure 400 {object} Response "Invalid request body"
// @Failure 500 {object} Response "Failed to retrieve grammars"
// @Security    ApiKeyAuth
// @Router /api/v1/grammars/batch [post]
func (server *Server) batchGetGrammars(ctx *gin.Context) {
	var req batchGetGrammarsRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	if len(req.IDs) == 0 {
		ErrorResponse(ctx, http.StatusBadRequest, "IDs list cannot be empty", nil)
		return
	}
	grammars, err := server.store.BatchGetGrammars(ctx, req.IDs)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve grammars", err)
		return
	}

	var grammarResponses []GrammarResponse
	for _, grammar := range grammars {
		grammarResponses = append(grammarResponses, NewGrammarResponse(grammar))
	}

	// Ensure we return an empty array instead of null if no results
	if grammarResponses == nil {
		grammarResponses = []GrammarResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "Grammars retrieved successfully", grammarResponses)
}
