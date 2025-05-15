package api

import (
	"database/sql"
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

type createWordRequest struct {
	Word          string                `json:"word" binding:"required"`
	Pronounce     string                `json:"pronounce" binding:"required"`
	Level         int32                 `json:"level" binding:"required"`
	DescriptLevel string                `json:"descript_level" binding:"required"`
	ShortMean     string                `json:"short_mean" binding:"required"`
	Means         pqtype.NullRawMessage `json:"means"`
	Snym          pqtype.NullRawMessage `json:"snym"`
	Freq          float32               `json:"freq" binding:"required"`
	Conjugation   pqtype.NullRawMessage `json:"conjugation"`
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
		Means:         req.Means,
		Snym:          req.Snym,
		Freq:          req.Freq,
		Conjugation:   req.Conjugation,
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

	ctx.JSON(http.StatusOK, words)
}

type updateWordRequest struct {
	ID            int32                 `json:"id" binding:"required,min=1"`
	Word          string                `json:"word"`
	Pronounce     string                `json:"pronounce"`
	Level         int32                 `json:"level"`
	DescriptLevel string                `json:"descript_level"`
	ShortMean     string                `json:"short_mean"`
	Means         pqtype.NullRawMessage `json:"means"`
	Snym          pqtype.NullRawMessage `json:"snym"`
	Freq          float32               `json:"freq"`
	Conjugation   pqtype.NullRawMessage `json:"conjugation"`
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
		Means:         req.Means,
		Snym:          req.Snym,
		Freq:          req.Freq,
		Conjugation:   req.Conjugation,
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
