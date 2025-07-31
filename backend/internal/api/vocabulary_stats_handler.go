package api

import (
	"database/sql"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/token"
)

// VocabularyStatsResponse represents vocabulary statistics for a word
type VocabularyStatsResponse struct {
	UserID              int32   `json:"user_id"`
	WordID              int32   `json:"word_id"`
	Word                string  `json:"word,omitempty"`
	TotalAttempts       int32   `json:"total_attempts"`
	CorrectAttempts     int32   `json:"correct_attempts"`
	AccuracyPercentage  float64 `json:"accuracy_percentage"`
	TotalResponseTimeMs int64   `json:"total_response_time_ms"`
	AvgResponseTimeMs   float64 `json:"avg_response_time_ms"`
	MasteryLevel        int32   `json:"mastery_level"`
	LastAttemptAt       *string `json:"last_attempt_at,omitempty"`
	CreatedAt           string  `json:"created_at"`
	UpdatedAt           string  `json:"updated_at"`
}

// LearningProgressResponse represents overall learning progress
type LearningProgressResponse struct {
	TotalWordsStudied   int64   `json:"total_words_studied"`
	MasteredWords       int64   `json:"mastered_words"`
	AverageMastery      float64 `json:"average_mastery"`
	TotalAttempts       int64   `json:"total_attempts"`
	TotalCorrect        int64   `json:"total_correct"`
	OverallAccuracy     float64 `json:"overall_accuracy"`
	TotalStudyTimeMs    int64   `json:"total_study_time_ms"`
	TotalStudyTimeHours float64 `json:"total_study_time_hours"`
}

// MasteryDistribution represents mastery level distribution
type MasteryDistribution struct {
	MasteryLevel int32 `json:"mastery_level"`
	WordCount    int64 `json:"word_count"`
}

// WordForReviewResponse represents a word that needs review
type WordForReviewResponse struct {
	WordResponse
	VocabularyStatsResponse
}

// updateMasteryRequest defines the structure for updating word mastery level
type updateMasteryRequest struct {
	MasteryLevel int32 `json:"mastery_level" binding:"required,min=1,max=10"`
}

// getWordMasteryRequest defines the URI parameter for word ID
type getWordMasteryRequest struct {
	WordID int32 `uri:"word_id" binding:"required,min=1"`
}

// listVocabularyStatsRequest defines query parameters for listing vocabulary stats
type listVocabularyStatsRequest struct {
	Limit  int32 `form:"limit,default=20" binding:"min=1,max=100"`
	Offset int32 `form:"offset,default=0" binding:"min=0"`
}

// getWordsForReviewRequest defines the query parameters for getting words needing review
type getWordsForReviewRequest struct {
	MasteryThreshold int32 `form:"mastery_threshold,default=5" binding:"min=1,max=10"`
	Limit            int32 `form:"limit,default=20" binding:"min=1,max=100"`
}

// NewVocabularyStatsResponse creates a VocabularyStatsResponse from database models
func NewVocabularyStatsResponse(stats db.VocabularyStat, word *db.Word) VocabularyStatsResponse {
	response := VocabularyStatsResponse{
		UserID:    stats.UserID,
		WordID:    stats.WordID,
		CreatedAt: stats.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt: stats.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	}

	// Handle nullable fields
	if stats.TotalAttempts.Valid {
		response.TotalAttempts = stats.TotalAttempts.Int32
	}
	if stats.CorrectAttempts.Valid {
		response.CorrectAttempts = stats.CorrectAttempts.Int32
	}
	if stats.TotalResponseTimeMs.Valid {
		response.TotalResponseTimeMs = stats.TotalResponseTimeMs.Int64
	}
	if stats.MasteryLevel.Valid {
		response.MasteryLevel = stats.MasteryLevel.Int32
	}

	// Calculate accuracy percentage
	if response.TotalAttempts > 0 {
		response.AccuracyPercentage = float64(response.CorrectAttempts) / float64(response.TotalAttempts) * 100
		response.AvgResponseTimeMs = float64(response.TotalResponseTimeMs) / float64(response.TotalAttempts)
	}

	if stats.LastAttemptAt.Valid {
		lastAttempt := stats.LastAttemptAt.Time.Format("2006-01-02T15:04:05Z")
		response.LastAttemptAt = &lastAttempt
	}

	if word != nil {
		response.Word = word.Word
	}

	return response
}

// @Summary Get vocabulary statistics for current user
// @Description Get vocabulary learning statistics for the current user
// @Tags vocabulary-stats
// @Accept json
// @Produce json
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} Response{data=[]VocabularyStatsResponse} "Vocabulary statistics retrieved successfully"
// @Failure 400 {object} Response "Invalid query parameters"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Failed to retrieve vocabulary statistics"
// @Security ApiKeyAuth
// @Router /api/v1/vocabulary/stats [get]
func (server *Server) listUserVocabularyStats(ctx *gin.Context) {
	var req listVocabularyStatsRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
		return
	}

	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	statsWithWords, err := server.store.ListUserVocabularyStats(ctx, db.ListUserVocabularyStatsParams{
		UserID: authPayload.ID,
		Limit:  req.Limit,
		Offset: req.Offset,
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve vocabulary statistics", err)
		return
	}

	var responses []VocabularyStatsResponse
	for _, item := range statsWithWords {
		response := NewVocabularyStatsResponse(item.VocabularyStat, &item.Word)
		responses = append(responses, response)
	}

	if responses == nil {
		responses = []VocabularyStatsResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "Vocabulary statistics retrieved successfully", responses)
}

// @Summary Get overall learning progress
// @Description Get overall vocabulary learning progress for the current user
// @Tags vocabulary-stats
// @Accept json
// @Produce json
// @Success 200 {object} Response{data=LearningProgressResponse} "Learning progress retrieved successfully"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Failed to retrieve learning progress"
// @Security ApiKeyAuth
// @Router /api/v1/vocabulary/progress [get]
func (server *Server) getUserLearningProgress(ctx *gin.Context) {
	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	progress, err := server.store.GetUserLearningProgress(ctx, authPayload.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve learning progress", err)
		return
	}

	response := LearningProgressResponse{
		TotalWordsStudied: progress.TotalWordsStudied,
		MasteredWords:     progress.MasteredWords,
		TotalAttempts:     progress.TotalAttempts,
		TotalCorrect:      progress.TotalCorrect,
		TotalStudyTimeMs:  progress.TotalStudyTimeMs,
	}

	// Calculate averages and derived metrics
	response.AverageMastery = progress.AverageMastery

	if progress.TotalAttempts > 0 {
		response.OverallAccuracy = float64(progress.TotalCorrect) / float64(progress.TotalAttempts) * 100
	}

	// Convert milliseconds to hours
	response.TotalStudyTimeHours = float64(progress.TotalStudyTimeMs) / (1000 * 60 * 60)

	SuccessResponse(ctx, http.StatusOK, "Learning progress retrieved successfully", response)
}

// @Summary Get mastery level distribution
// @Description Get distribution of words across different mastery levels
// @Tags vocabulary-stats
// @Accept json
// @Produce json
// @Success 200 {object} Response{data=[]MasteryDistribution} "Mastery distribution retrieved successfully"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Failed to retrieve mastery distribution"
// @Security ApiKeyAuth
// @Router /api/v1/vocabulary/mastery-distribution [get]
func (server *Server) getUserMasteryDistribution(ctx *gin.Context) {
	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	distribution, err := server.store.GetUserMasteryDistribution(ctx, authPayload.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve mastery distribution", err)
		return
	}

	var responses []MasteryDistribution
	for _, item := range distribution {
		masteryLevel := int32(0)
		if item.MasteryLevel.Valid {
			masteryLevel = item.MasteryLevel.Int32
		}
		responses = append(responses, MasteryDistribution{
			MasteryLevel: masteryLevel,
			WordCount:    item.WordCount,
		})
	}

	if responses == nil {
		responses = []MasteryDistribution{}
	}

	SuccessResponse(ctx, http.StatusOK, "Mastery distribution retrieved successfully", responses)
}

// @Summary Get words needing review
// @Description Get words that need review based on mastery level
// @Tags vocabulary-stats
// @Accept json
// @Produce json
// @Param mastery_threshold query int false "Mastery threshold" default(5)
// @Param limit query int false "Limit" default(20)
// @Success 200 {object} Response{data=[]WordForReviewResponse} "Words for review retrieved successfully"
// @Failure 400 {object} Response "Invalid query parameters"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Failed to retrieve words for review"
// @Security ApiKeyAuth
// @Router /api/v1/vocabulary/review [get]
func (server *Server) getWordsNeedingReview(ctx *gin.Context) {
	var req getWordsForReviewRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
		return
	}

	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	wordsForReview, err := server.store.GetWordsNeedingReview(ctx, db.GetWordsNeedingReviewParams{
		UserID:       authPayload.ID,
		MasteryLevel: sql.NullInt32{Int32: req.MasteryThreshold, Valid: true},
		Limit:        req.Limit,
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve words for review", err)
		return
	}

	var responses []WordForReviewResponse
	for _, item := range wordsForReview {
		wordResponse := NewWordResponse(item.Word)
		var statsResponse VocabularyStatsResponse

		if item.VocabularyStat.UserID != 0 { // Check if stats exist
			statsResponse = NewVocabularyStatsResponse(item.VocabularyStat, &item.Word)
		} else {
			// Create default stats for words without statistics
			statsResponse = VocabularyStatsResponse{
				UserID:              authPayload.ID,
				WordID:              item.Word.ID,
				Word:                item.Word.Word,
				TotalAttempts:       0,
				CorrectAttempts:     0,
				AccuracyPercentage:  0,
				TotalResponseTimeMs: 0,
				AvgResponseTimeMs:   0,
				MasteryLevel:        1, // Default to lowest mastery
				CreatedAt:           time.Now().Format("2006-01-02T15:04:05Z"),
				UpdatedAt:           time.Now().Format("2006-01-02T15:04:05Z"),
			}
		}

		responses = append(responses, WordForReviewResponse{
			WordResponse:            wordResponse,
			VocabularyStatsResponse: statsResponse,
		})
	}

	if responses == nil {
		responses = []WordForReviewResponse{}
	}

	SuccessResponse(ctx, http.StatusOK, "Words for review retrieved successfully", responses)
}

// @Summary Update word mastery level
// @Description Update the mastery level for a specific word
// @Tags vocabulary-stats
// @Accept json
// @Produce json
// @Param word_id path int true "Word ID"
// @Param request body updateMasteryRequest true "Mastery level update"
// @Success 200 {object} Response{data=VocabularyStatsResponse} "Word mastery updated successfully"
// @Failure 400 {object} Response "Invalid request body or word ID"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 404 {object} Response "Word not found"
// @Failure 500 {object} Response "Failed to update word mastery"
// @Security ApiKeyAuth
// @Router /api/v1/vocabulary/words/{word_id}/mastery [put]
func (server *Server) updateWordMastery(ctx *gin.Context) {
	var uriReq getWordMasteryRequest
	if err := ctx.ShouldBindUri(&uriReq); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid word ID", err)
		return
	}

	var req updateMasteryRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	authPayload := ctx.MustGet(AuthorizationPayloadKey).(*token.Payload)

	// Check if word exists
	word, err := server.store.GetWord(ctx, uriReq.WordID)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Word not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve word", err)
		return
	}

	// Update or create vocabulary stats with new mastery level
	stats, err := server.store.CreateOrUpdateVocabularyStats(ctx, db.CreateOrUpdateVocabularyStatsParams{
		UserID:              authPayload.ID,
		WordID:              uriReq.WordID,
		TotalAttempts:       sql.NullInt32{Int32: 0, Valid: false}, // Won't be added if already exists
		CorrectAttempts:     sql.NullInt32{Int32: 0, Valid: false}, // Won't be added if already exists
		TotalResponseTimeMs: sql.NullInt64{Int64: 0, Valid: false}, // Won't be added if already exists
		MasteryLevel:        sql.NullInt32{Int32: req.MasteryLevel, Valid: true},
		LastAttemptAt:       sql.NullTime{Time: time.Now(), Valid: true},
	})
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update word mastery", err)
		return
	}

	response := NewVocabularyStatsResponse(stats, &word)
	SuccessResponse(ctx, http.StatusOK, "Word mastery updated successfully", response)
}
