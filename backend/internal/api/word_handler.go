package api

import (
	"database/sql"
	"encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/sqlc-dev/pqtype"
	db "github.com/toeic-app/internal/db/sqlc" // Adjust import path if necessary
)

// WordJSONField is a placeholder for JSONB fields in Swagger docs
// swagger:model
// example: {"en": "example"}
type WordJSONField struct {
	Raw interface{} `json:"raw"`
}

// WordResponse is used for Swagger documentation only
// swagger:model
// example: {"id":1,"word":"example","pronounce":"ex-am-ple","level":1,"descript_level":"A1","short_mean":"short meaning","means":{"raw":{"en":"meaning"}},"snym":{"raw":null},"freq":1.0,"conjugation":{"raw":null}}
type WordResponse struct {
	ID            int32         `json:"id"`
	Word          string        `json:"word"`
	Pronounce     string        `json:"pronounce"`
	Level         int32         `json:"level"`
	DescriptLevel string        `json:"descript_level"`
	ShortMean     string        `json:"short_mean"`
	Means         WordJSONField `json:"means"`
	Snym          WordJSONField `json:"snym"`
	Freq          float32       `json:"freq"`
	Conjugation   WordJSONField `json:"conjugation"`
}

// NewWordResponse creates a WordResponse from db.Word model
func NewWordResponse(word db.Word) WordResponse {
	return WordResponse{
		ID:            word.ID,
		Word:          word.Word,
		Pronounce:     word.Pronounce,
		Level:         word.Level,
		DescriptLevel: word.DescriptLevel,
		ShortMean:     word.ShortMean,
		Means:         WordJSONField{Raw: word.Means.RawMessage},
		Snym:          WordJSONField{Raw: word.Snym.RawMessage},
		Freq:          word.Freq,
		Conjugation:   WordJSONField{Raw: word.Conjugation.RawMessage},
	}
}

type createWordRequest struct {
	Word          string        `json:"word" binding:"required"`
	Pronounce     string        `json:"pronounce" binding:"required"`
	Level         int32         `json:"level" binding:"required"`
	DescriptLevel string        `json:"descript_level" binding:"required"`
	ShortMean     string        `json:"short_mean" binding:"required"`
	Means         WordJSONField `json:"means"`
	Snym          WordJSONField `json:"snym"`
	Freq          float32       `json:"freq" binding:"required"`
	Conjugation   WordJSONField `json:"conjugation"`
}

// @Summary Create a new word
// @Description Create a new word with the input payload
// @Tags words
// @Accept json
// @Produce json
// @Param body body createWordRequest true "Create Word Request"
// @Success 200 {object} Response{data=WordResponse} "Word created successfully"
// @Failure 400 {object} Response "Invalid request payload"
// @Failure 500 {object} Response "Failed to create word"
// @Router /api/v1/words [post]
// @Security ApiKeyAuth
func (server *Server) createWord(ctx *gin.Context) {
	var req createWordRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	arg := db.CreateWordParams{
		Word:          req.Word,
		Pronounce:     req.Pronounce,
		Level:         req.Level,
		DescriptLevel: req.DescriptLevel,
		ShortMean:     req.ShortMean,
		Means:         toNullRawMessage(req.Means),
		Snym:          toNullRawMessage(req.Snym),
		Freq:          req.Freq,
		Conjugation:   toNullRawMessage(req.Conjugation),
	}

	word, err := server.store.CreateWord(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create word", err)
		return
	}

	ctx.JSON(http.StatusOK, word)
}

type getWordRequest struct {
	ID int32 `uri:"id" binding:"required,min=1"`
}

// @Summary Get a word by ID
// @Description Get a word by its ID
// @Tags words
// @Accept json
// @Produce json
// @Param id path int true "Word ID"
// @Success 200 {object} Response{data=WordResponse}
// @Failure 400 {object} Response "Invalid word ID"
// @Failure 404 {object} Response "Word not found"
// @Failure 500 {object} Response "Failed to get word"
// @Router /api/v1/words/{id} [get]
// @Security ApiKeyAuth
func (server *Server) getWord(ctx *gin.Context) {
	var req getWordRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid word ID", err)
		return
	}

	word, err := server.store.GetWord(ctx, req.ID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Word not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get word", err)
		return
	}

	ctx.JSON(http.StatusOK, word)
}

type listWordsRequest struct {
	Limit  int32 `form:"limit,default=10"`
	Offset int32 `form:"offset,default=0"`
}

// @Summary List words
// @Description List words with pagination
// @Tags words
// @Accept json
// @Produce json
// @Param limit query int false "Limit" default(10)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} Response{data=[]WordResponse} "List of words"
// @Failure 400 {object} Response "Invalid query parameters"
// @Failure 500 {object} Response "Failed to list words"
// @Router /api/v1/words [get]
// @Security ApiKeyAuth
func (server *Server) listWords(ctx *gin.Context) {
	var req listWordsRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
		return
	}
	words, err := server.store.ListWords(ctx, db.ListWordsParams{
		Limit:  req.Limit,
		Offset: req.Offset,
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to list words", err)
		return
	}

	var wordResponses []WordResponse
	if words != nil {
		for _, word := range words {
			wordResponses = append(wordResponses, NewWordResponse(word))
		}
	}
	
	// Ensure we return an empty array instead of null if no results
	if wordResponses == nil {
		wordResponses = []WordResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "Words retrieved successfully", wordResponses)
}

type updateWordRequest struct {
	ID            int32         `json:"id" binding:"required,min=1"`
	Word          string        `json:"word"`
	Pronounce     string        `json:"pronounce"`
	Level         int32         `json:"level"`
	DescriptLevel string        `json:"descript_level"`
	ShortMean     string        `json:"short_mean"`
	Means         WordJSONField `json:"means"`
	Snym          WordJSONField `json:"snym"`
	Freq          float32       `json:"freq"`
	Conjugation   WordJSONField `json:"conjugation"`
}

// @Summary Update a word
// @Description Update a word with the input payload
// @Tags words
// @Accept json
// @Produce json
// @Param id path int true "Word ID"
// @Param body body updateWordRequest true "Update Word Request"
// @Success 200 {object} Response{data=WordResponse}
// @Failure 400 {object} Response "Invalid request payload"
// @Failure 404 {object} Response "Word not found"
// @Failure 500 {object} Response "Failed to update word"
// @Router /api/v1/words/{id} [put]
// @Security ApiKeyAuth
func (server *Server) updateWord(ctx *gin.Context) {
	var req updateWordRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	arg := db.UpdateWordParams{
		ID:            req.ID,
		Word:          req.Word,
		Pronounce:     req.Pronounce,
		Level:         req.Level,
		DescriptLevel: req.DescriptLevel,
		ShortMean:     req.ShortMean,
		Means:         toNullRawMessage(req.Means),
		Snym:          toNullRawMessage(req.Snym),
		Freq:          req.Freq,
		Conjugation:   toNullRawMessage(req.Conjugation),
	}

	word, err := server.store.UpdateWord(ctx, arg)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Word not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update word", err)
		return
	}

	ctx.JSON(http.StatusOK, word)
}

// toNullRawMessage converts a WordJSONField to pqtype.NullRawMessage
func toNullRawMessage(field WordJSONField) pqtype.NullRawMessage {
	// If field.Raw is nil, return NullRawMessage with Valid=false
	if field.Raw == nil {
		return pqtype.NullRawMessage{Valid: false}
	}
	// Marshal the Raw value to JSON
	b, err := json.Marshal(field.Raw)
	if err != nil {
		return pqtype.NullRawMessage{Valid: false}
	}
	return pqtype.NullRawMessage{RawMessage: b, Valid: true}
}

// @Summary Delete a word
// @Description Delete a word by its ID
// @Tags words
// @Accept json
// @Produce json
// @Param id path int true "Word ID"
// @Success 200 {object} Response "Word deleted successfully"
// @Failure 400 {object} Response "Invalid word ID"
// @Failure 404 {object} Response "Word not found"
// @Failure 500 {object} Response "Failed to delete word"
// @Router /api/v1/words/{id} [delete]
// @Security ApiKeyAuth
func (server *Server) deleteWord(ctx *gin.Context) {
	var req getWordRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid word ID", err)
		return
	}

	err := server.store.DeleteWord(ctx, req.ID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Word not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete word", err)
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Word deleted successfully"})
}

// searchWordsRequest defines the structure for searching words with pagination.
type searchWordsRequest struct {
	Query  string `form:"query" binding:"required"`
	Limit  int32  `form:"limit" binding:"required,min=1,max=100"`
	Offset int32  `form:"offset" binding:"min=0"`
}

// @Summary Search words
// @Description Search words by word, short meaning, or meanings with pagination
// @Tags words
// @Accept json
// @Produce json
// @Param query query string true "Search query"
// @Param limit query int true "Limit" default(10)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} Response{data=[]WordResponse} "Words search completed successfully"
// @Failure 400 {object} Response "Invalid query parameters"
// @Failure 500 {object} Response "Failed to search words"
// @Router /api/v1/words/search [get]
// @Security ApiKeyAuth
func (server *Server) searchWords(ctx *gin.Context) {
	var req searchWordsRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
		return
	}
	arg := db.SearchWordsParams{
		Column1: sql.NullString{String: req.Query, Valid: true},
		Limit:   req.Limit,
		Offset:  req.Offset,
	}
	words, err := server.store.SearchWords(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to search words", err)
		return
	}

	var wordResponses []WordResponse
	if words != nil {
		for _, word := range words {
			wordResponses = append(wordResponses, NewWordResponse(word))
		}
	}
	
	// Ensure we return an empty array instead of null if no results
	if wordResponses == nil {
		wordResponses = []WordResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "Word search completed successfully", wordResponses)
}
