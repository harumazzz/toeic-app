package api

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/sqlc-dev/pqtype"
	db "github.com/toeic-app/internal/db/sqlc" // Adjust import path if necessary
	"github.com/toeic-app/internal/logger"
)

// WordState represents the word state structure
// swagger:model
type WordState struct {
	P string `json:"p"`
	W string `json:"w"`
}

// ConjugationData represents verb conjugation information
// swagger:model
type ConjugationData struct {
	HTD  *WordState `json:"htd,omitempty"`  // simplePresent
	QKD  *WordState `json:"qkd,omitempty"`  // simplePast
	HTHT *WordState `json:"htht,omitempty"` // presentParticiple
	HTTD *WordState `json:"httd,omitempty"` // presentContinuous
}

// MeanModel represents individual meaning with examples
// swagger:model
type MeanModel struct {
	Mean     *string `json:"mean,omitempty"`
	Examples []int   `json:"examples,omitempty"`
}

// MeaningData represents meanings grouped by kind (noun, verb, etc.)
// swagger:model
type MeaningData struct {
	Kind  *string     `json:"kind,omitempty"`
	Means []MeanModel `json:"means,omitempty"`
}

// ContentModel represents synonym/antonym content
// swagger:model
type ContentModel struct {
	Antonym []string `json:"anto,omitempty"`
	Synonym []string `json:"syno,omitempty"`
}

// SynonymData represents synonym information
// swagger:model
type SynonymData struct {
	Kind    string         `json:"kind"`
	Content []ContentModel `json:"content"`
}

// WordResponse is used for Swagger documentation only
// swagger:model
// example: {"id":1,"word":"example","pronounce":"ex-am-ple","level":1,"descript_level":"A1","short_mean":"short meaning","means":[{"kind":"noun","means":[{"mean":"example meaning","examples":[1,2]}]}],"snym":[{"kind":"synonym","content":[{"syno":["sample","instance"]}]}],"freq":1.0,"conjugation":{"htd":{"p":"present","w":"example"}}}
type WordResponse struct {
	ID            int32            `json:"id"`
	Word          string           `json:"word"`
	Pronounce     string           `json:"pronounce"`
	Level         int32            `json:"level"`
	DescriptLevel string           `json:"descript_level"`
	ShortMean     string           `json:"short_mean"`
	Means         []MeaningData    `json:"means,omitempty"`
	Snym          []SynonymData    `json:"snym,omitempty"`
	Freq          float32          `json:"freq"`
	Conjugation   *ConjugationData `json:"conjugation,omitempty"`
}

// NewWordResponse creates a WordResponse from db.Word model
func NewWordResponse(word db.Word) WordResponse {
	response := WordResponse{
		ID:            word.ID,
		Word:          word.Word,
		Pronounce:     word.Pronounce,
		Level:         word.Level,
		DescriptLevel: word.DescriptLevel,
		ShortMean:     word.ShortMean,
		Freq:          word.Freq,
	}

	// Parse JSON fields if they are valid
	if word.Means.Valid {
		var means []MeaningData
		if err := json.Unmarshal(word.Means.RawMessage, &means); err == nil {
			response.Means = means
		}
	}
	if word.Snym.Valid {
		var snym []SynonymData
		if err := json.Unmarshal(word.Snym.RawMessage, &snym); err == nil {
			response.Snym = snym
		}
	}
	if word.Conjugation.Valid {
		var conjugation ConjugationData
		if err := json.Unmarshal(word.Conjugation.RawMessage, &conjugation); err == nil {
			response.Conjugation = &conjugation
		}
	}

	return response
}

type createWordRequest struct {
	Word          string           `json:"word" binding:"required"`
	Pronounce     string           `json:"pronounce" binding:"required"`
	Level         int32            `json:"level" binding:"required"`
	DescriptLevel string           `json:"descript_level" binding:"required"`
	ShortMean     string           `json:"short_mean" binding:"required"`
	Means         []MeaningData    `json:"means,omitempty"`
	Snym          []SynonymData    `json:"snym,omitempty"`
	Freq          float32          `json:"freq" binding:"required"`
	Conjugation   *ConjugationData `json:"conjugation,omitempty"`
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
		Means:         toNullRawMessageFromMeaning(req.Means),
		Snym:          toNullRawMessageFromSynonym(req.Snym),
		Freq:          req.Freq,
		Conjugation:   toNullRawMessageFromConjugation(req.Conjugation),
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
	// Try to get from cache first if caching is enabled
	if server.config.CacheEnabled && server.serviceCache != nil {
		cacheKey := server.serviceCache.GenerateKey("word", req.ID)

		var cachedWord db.Word
		if err := server.serviceCache.Get(ctx, cacheKey, &cachedWord); err == nil {
			logger.Debug("Word %d retrieved from cache", req.ID)
			wordResponse := NewWordResponse(cachedWord)
			SuccessResponse(ctx, http.StatusOK, "Word retrieved successfully", wordResponse)
			return
		}
		logger.Debug("Word %d not found in cache, fetching from database", req.ID)
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
	// Cache the word if caching is enabled
	if server.config.CacheEnabled && server.serviceCache != nil {
		cacheKey := server.serviceCache.GenerateKey("word", req.ID)
		go func() {
			bgCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			if err := server.serviceCache.Set(bgCtx, cacheKey, word, server.config.CacheDefaultTTL); err != nil {
				logger.Warn("Failed to cache word %d: %v", req.ID, err)
			} else {
				logger.Debug("Word %d cached successfully", req.ID)
			}
		}()
	}

	wordResponse := NewWordResponse(word)
	SuccessResponse(ctx, http.StatusOK, "Word retrieved successfully", wordResponse)
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
	for _, word := range words {
		wordResponses = append(wordResponses, NewWordResponse(word))
	}

	// Ensure we return an empty array instead of null if no results
	if wordResponses == nil {
		wordResponses = []WordResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "Words retrieved successfully", wordResponses)
}

type updateWordRequest struct {
	ID            int32            `json:"id" binding:"required,min=1"`
	Word          string           `json:"word"`
	Pronounce     string           `json:"pronounce"`
	Level         int32            `json:"level"`
	DescriptLevel string           `json:"descript_level"`
	ShortMean     string           `json:"short_mean"`
	Means         []MeaningData    `json:"means,omitempty"`
	Snym          []SynonymData    `json:"snym,omitempty"`
	Freq          float32          `json:"freq"`
	Conjugation   *ConjugationData `json:"conjugation,omitempty"`
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
		Means:         toNullRawMessageFromMeaning(req.Means),
		Snym:          toNullRawMessageFromSynonym(req.Snym),
		Freq:          req.Freq,
		Conjugation:   toNullRawMessageFromConjugation(req.Conjugation),
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

	// Clear cache for the updated word
	if server.config.CacheEnabled && server.serviceCache != nil {
		cacheKey := server.serviceCache.GenerateKey("word", req.ID)
		go func() {
			bgCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			if err := server.serviceCache.Delete(bgCtx, cacheKey); err != nil {
				logger.Warn("Failed to clear cache for updated word %d: %v", req.ID, err)
			} else {
				logger.Debug("Cache cleared for updated word %d", req.ID)
			}
		}()
	}

	wordResponse := NewWordResponse(word)
	SuccessResponse(ctx, http.StatusOK, "Word updated successfully", wordResponse)
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

	// Clear cache for the deleted word
	if server.config.CacheEnabled && server.serviceCache != nil {
		cacheKey := server.serviceCache.GenerateKey("word", req.ID)
		go func() {
			bgCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			if err := server.serviceCache.Delete(bgCtx, cacheKey); err != nil {
				logger.Warn("Failed to clear cache for deleted word %d: %v", req.ID, err)
			} else {
				logger.Debug("Cache cleared for deleted word %d", req.ID)
			}
		}()
	}

	SuccessResponse(ctx, http.StatusOK, "Word deleted successfully", nil)
}

type searchWordsRequest struct {
	Query  string `form:"query" binding:"required"`
	Limit  int32  `form:"limit,default=10"`
	Offset int32  `form:"offset,default=0"`
}

// @Summary Search words
// @Description Search words by query string
// @Tags words
// @Accept json
// @Produce json
// @Param query query string true "Search query"
// @Param limit query int false "Limit" default(10)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} Response{data=[]WordResponse} "Search results"
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
	words, err := server.store.SearchWords(ctx, db.SearchWordsParams{
		Column1: sql.NullString{String: req.Query, Valid: true},
		Limit:   req.Limit,
		Offset:  req.Offset,
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to search words", err)
		return
	}

	var wordResponses []WordResponse
	for _, word := range words {
		wordResponses = append(wordResponses, NewWordResponse(word))
	}

	// Ensure we return an empty array instead of null if no results
	if wordResponses == nil {
		wordResponses = []WordResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "Words found successfully", wordResponses)
}

// Helper functions to convert structured types to pqtype.NullRawMessage

// toNullRawMessageFromMeaning converts []MeaningData to pqtype.NullRawMessage
func toNullRawMessageFromMeaning(meanings []MeaningData) pqtype.NullRawMessage {
	if len(meanings) == 0 {
		return pqtype.NullRawMessage{Valid: false}
	}

	data, err := json.Marshal(meanings)
	if err != nil {
		return pqtype.NullRawMessage{Valid: false}
	}
	return pqtype.NullRawMessage{RawMessage: json.RawMessage(data), Valid: true}
}

// toNullRawMessageFromSynonym converts []SynonymData to pqtype.NullRawMessage
func toNullRawMessageFromSynonym(synonyms []SynonymData) pqtype.NullRawMessage {
	if len(synonyms) == 0 {
		return pqtype.NullRawMessage{Valid: false}
	}

	data, err := json.Marshal(synonyms)
	if err != nil {
		return pqtype.NullRawMessage{Valid: false}
	}
	return pqtype.NullRawMessage{RawMessage: json.RawMessage(data), Valid: true}
}

// toNullRawMessageFromConjugation converts *ConjugationData to pqtype.NullRawMessage
func toNullRawMessageFromConjugation(conjugation *ConjugationData) pqtype.NullRawMessage {
	if conjugation == nil {
		return pqtype.NullRawMessage{Valid: false}
	}

	data, err := json.Marshal(conjugation)
	if err != nil {
		return pqtype.NullRawMessage{Valid: false}
	}
	return pqtype.NullRawMessage{RawMessage: json.RawMessage(data), Valid: true}
}
