package api

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/token"
)

// StudySetResponse represents a study set response
type StudySetResponse struct {
	ID          int32  `json:"id"`
	UserID      int32  `json:"user_id"`
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
	IsPublic    bool   `json:"is_public"`
	WordCount   int    `json:"word_count,omitempty"`
	CreatedAt   string `json:"created_at"`
	UpdatedAt   string `json:"updated_at"`
}

// StudySetWithWordsResponse represents a study set with its words
type StudySetWithWordsResponse struct {
	StudySetResponse
	Words []WordResponse `json:"words"`
}

// createStudySetRequest defines the structure for creating a study set
type createStudySetRequest struct {
	Name        string  `json:"name" binding:"required,min=1,max=255"`
	Description *string `json:"description,omitempty"`
	IsPublic    bool    `json:"is_public"`
}

// updateStudySetRequest defines the structure for updating a study set
type updateStudySetRequest struct {
	Name        string  `json:"name" binding:"required,min=1,max=255"`
	Description *string `json:"description,omitempty"`
	IsPublic    bool    `json:"is_public"`
}

// addWordToStudySetRequest defines the structure for adding a word to a study set
type addWordToStudySetRequest struct {
	WordID int32 `json:"word_id" binding:"required,min=1"`
}

// getStudySetRequest defines the URI parameter for study set ID
type getStudySetRequest struct {
	ID int32 `uri:"id" binding:"required,min=1"`
}

// listStudySetsRequest defines query parameters for listing study sets
type listStudySetsRequest struct {
	Limit  int32 `form:"limit,default=10" binding:"min=1,max=50"`
	Offset int32 `form:"offset,default=0" binding:"min=0"`
}

// NewStudySetResponse creates a StudySetResponse from database model
func NewStudySetResponse(studySet db.StudySet) StudySetResponse {
	var description string
	if studySet.Description.Valid {
		description = studySet.Description.String
	}

	var isPublic bool
	if studySet.IsPublic.Valid {
		isPublic = studySet.IsPublic.Bool
	}

	return StudySetResponse{
		ID:          studySet.ID,
		UserID:      studySet.UserID,
		Name:        studySet.Name,
		Description: description,
		IsPublic:    isPublic,
		CreatedAt:   studySet.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:   studySet.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	}
}

// @Summary Create a new study set
// @Description Create a new study set for vocabulary learning
// @Tags study-sets
// @Accept json
// @Produce json
// @Param request body createStudySetRequest true "Study set details"
// @Success 201 {object} Response{data=StudySetResponse} "Study set created successfully"
// @Failure 400 {object} Response "Invalid request body"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Failed to create study set"
// @Security ApiKeyAuth
// @Router /api/v1/study-sets [post]
func (server *Server) createStudySet(ctx *gin.Context) {
	var req createStudySetRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Get user from token
	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	var description sql.NullString
	if req.Description != nil {
		description = sql.NullString{String: *req.Description, Valid: true}
	}

	arg := db.CreateStudySetParams{
		UserID:      authPayload.ID,
		Name:        req.Name,
		Description: description,
		IsPublic:    sql.NullBool{Bool: req.IsPublic, Valid: true},
	}

	studySet, err := server.store.CreateStudySet(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create study set", err)
		return
	}

	response := NewStudySetResponse(studySet)
	SuccessResponse(ctx, http.StatusCreated, "Study set created successfully", response)
}

// @Summary Get a study set
// @Description Get a study set by ID with its words
// @Tags study-sets
// @Accept json
// @Produce json
// @Param id path int true "Study Set ID"
// @Success 200 {object} Response{data=StudySetWithWordsResponse} "Study set retrieved successfully"
// @Failure 400 {object} Response "Invalid study set ID"
// @Failure 404 {object} Response "Study set not found"
// @Failure 500 {object} Response "Failed to retrieve study set"
// @Security ApiKeyAuth
// @Router /api/v1/study-sets/{id} [get]
func (server *Server) getStudySet(ctx *gin.Context) {
	var req getStudySetRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid study set ID", err)
		return
	}

	// Get the study set first
	studySet, err := server.store.GetStudySet(ctx, req.ID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Study set not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve study set", err)
		return
	}

	// Check access permissions
	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)
	if studySet.UserID != authPayload.ID && (!studySet.IsPublic.Valid || !studySet.IsPublic.Bool) {
		ErrorResponse(ctx, http.StatusForbidden, "Access denied", nil)
		return
	}

	// Get words in the study set
	words, err := server.store.GetStudySetWords(ctx, req.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve study set words", err)
		return
	}

	// Convert to response
	response := StudySetWithWordsResponse{
		StudySetResponse: NewStudySetResponse(studySet),
		Words:            make([]WordResponse, len(words)),
	}

	for i, word := range words {
		response.Words[i] = NewWordResponse(word.Word)
	}

	response.WordCount = len(words)

	SuccessResponse(ctx, http.StatusOK, "Study set retrieved successfully", response)
}

// @Summary List user's study sets
// @Description List study sets created by the current user
// @Tags study-sets
// @Accept json
// @Produce json
// @Param limit query int false "Limit" default(10)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} Response{data=[]StudySetResponse} "Study sets retrieved successfully"
// @Failure 400 {object} Response "Invalid query parameters"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Failed to retrieve study sets"
// @Security ApiKeyAuth
// @Router /api/v1/study-sets [get]
func (server *Server) listUserStudySets(ctx *gin.Context) {
	var req listStudySetsRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
		return
	}

	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	arg := db.ListUserStudySetsParams{
		UserID: authPayload.ID,
		Limit:  req.Limit,
		Offset: req.Offset,
	}

	studySets, err := server.store.ListUserStudySets(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve study sets", err)
		return
	}

	var responses []StudySetResponse
	for _, studySet := range studySets {
		response := NewStudySetResponse(studySet)
		
		// Get word count for each study set
		count, err := server.store.CountWordsInStudySet(ctx, studySet.ID)
		if err == nil {
			response.WordCount = int(count)
		}
		
		responses = append(responses, response)
	}

	if responses == nil {
		responses = []StudySetResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "Study sets retrieved successfully", responses)
}

// @Summary List public study sets
// @Description List publicly available study sets
// @Tags study-sets
// @Accept json
// @Produce json
// @Param limit query int false "Limit" default(10)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} Response{data=[]StudySetResponse} "Public study sets retrieved successfully"
// @Failure 400 {object} Response "Invalid query parameters"
// @Failure 500 {object} Response "Failed to retrieve public study sets"
// @Security ApiKeyAuth
// @Router /api/v1/study-sets/public [get]
func (server *Server) listPublicStudySets(ctx *gin.Context) {
	var req listStudySetsRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
		return
	}

	arg := db.ListPublicStudySetsParams{
		Limit:  req.Limit,
		Offset: req.Offset,
	}

	studySets, err := server.store.ListPublicStudySets(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve public study sets", err)
		return
	}

	var responses []StudySetResponse
	for _, studySet := range studySets {
		response := NewStudySetResponse(studySet)
		
		// Get word count for each study set
		count, err := server.store.CountWordsInStudySet(ctx, studySet.ID)
		if err == nil {
			response.WordCount = int(count)
		}
		
		responses = append(responses, response)
	}

	if responses == nil {
		responses = []StudySetResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "Public study sets retrieved successfully", responses)
}

// @Summary Update a study set
// @Description Update an existing study set
// @Tags study-sets
// @Accept json
// @Produce json
// @Param id path int true "Study Set ID"
// @Param request body updateStudySetRequest true "Study set details"
// @Success 200 {object} Response{data=StudySetResponse} "Study set updated successfully"
// @Failure 400 {object} Response "Invalid request body or study set ID"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 404 {object} Response "Study set not found"
// @Failure 500 {object} Response "Failed to update study set"
// @Security ApiKeyAuth
// @Router /api/v1/study-sets/{id} [put]
func (server *Server) updateStudySet(ctx *gin.Context) {
	var uriReq getStudySetRequest
	if err := ctx.ShouldBindUri(&uriReq); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid study set ID", err)
		return
	}

	var req updateStudySetRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	var description sql.NullString
	if req.Description != nil {
		description = sql.NullString{String: *req.Description, Valid: true}
	}

	arg := db.UpdateStudySetParams{
		ID:          uriReq.ID,
		Name:        req.Name,
		Description: description,
		IsPublic:    sql.NullBool{Bool: req.IsPublic, Valid: true},
		UserID:      authPayload.ID,
	}

	studySet, err := server.store.UpdateStudySet(ctx, arg)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Study set not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update study set", err)
		return
	}

	response := NewStudySetResponse(studySet)
	SuccessResponse(ctx, http.StatusOK, "Study set updated successfully", response)
}

// @Summary Delete a study set
// @Description Delete an existing study set
// @Tags study-sets
// @Accept json
// @Produce json
// @Param id path int true "Study Set ID"
// @Success 200 {object} Response "Study set deleted successfully"
// @Failure 400 {object} Response "Invalid study set ID"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 404 {object} Response "Study set not found"
// @Failure 500 {object} Response "Failed to delete study set"
// @Security ApiKeyAuth
// @Router /api/v1/study-sets/{id} [delete]
func (server *Server) deleteStudySet(ctx *gin.Context) {
	var req getStudySetRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid study set ID", err)
		return
	}

	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	err := server.store.DeleteStudySet(ctx, db.DeleteStudySetParams{
		ID:     req.ID,
		UserID: authPayload.ID,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Study set not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete study set", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Study set deleted successfully", nil)
}

// @Summary Add word to study set
// @Description Add a word to an existing study set
// @Tags study-sets
// @Accept json
// @Produce json
// @Param id path int true "Study Set ID"
// @Param request body addWordToStudySetRequest true "Word to add"
// @Success 200 {object} Response "Word added to study set successfully"
// @Failure 400 {object} Response "Invalid request body or study set ID"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 404 {object} Response "Study set not found"
// @Failure 500 {object} Response "Failed to add word to study set"
// @Security ApiKeyAuth
// @Router /api/v1/study-sets/{id}/words [post]
func (server *Server) addWordToStudySet(ctx *gin.Context) {
	var uriReq getStudySetRequest
	if err := ctx.ShouldBindUri(&uriReq); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid study set ID", err)
		return
	}

	var req addWordToStudySetRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	// Check if study set exists and user has permission
	studySet, err := server.store.GetStudySet(ctx, uriReq.ID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Study set not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve study set", err)
		return
	}

	if studySet.UserID != authPayload.ID {
		ErrorResponse(ctx, http.StatusForbidden, "Access denied", nil)
		return
	}

	// Check if word exists
	_, err = server.store.GetWord(ctx, req.WordID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Word not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve word", err)
		return
	}

	// Add word to study set
	err = server.store.AddWordToStudySet(ctx, db.AddWordToStudySetParams{
		StudySetID: uriReq.ID,
		WordID:     req.WordID,
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to add word to study set", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Word added to study set successfully", nil)
}

// @Summary Remove word from study set
// @Description Remove a word from an existing study set
// @Tags study-sets
// @Accept json
// @Produce json
// @Param id path int true "Study Set ID"
// @Param word_id path int true "Word ID"
// @Success 200 {object} Response "Word removed from study set successfully"
// @Failure 400 {object} Response "Invalid study set ID or word ID"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 404 {object} Response "Study set not found"
// @Failure 500 {object} Response "Failed to remove word from study set"
// @Security ApiKeyAuth
// @Router /api/v1/study-sets/{id}/words/{word_id} [delete]
func (server *Server) removeWordFromStudySet(ctx *gin.Context) {
	var req struct {
		StudySetID int32 `uri:"id" binding:"required,min=1"`
		WordID     int32 `uri:"word_id" binding:"required,min=1"`
	}
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid study set ID or word ID", err)
		return
	}

	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	// Check if study set exists and user has permission
	studySet, err := server.store.GetStudySet(ctx, req.StudySetID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Study set not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve study set", err)
		return
	}

	if studySet.UserID != authPayload.ID {
		ErrorResponse(ctx, http.StatusForbidden, "Access denied", nil)
		return
	}

	// Remove word from study set
	err = server.store.RemoveWordFromStudySet(ctx, db.RemoveWordFromStudySetParams{
		StudySetID: req.StudySetID,
		WordID:     req.WordID,
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to remove word from study set", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Word removed from study set successfully", nil)
}
