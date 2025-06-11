package api

import (
	"database/sql"
	"net/http"
	"runtime"
	"time"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/logger"
)

// PerformanceStats represents performance metrics
type PerformanceStats struct {
	Database        DatabaseStats          `json:"database"`
	Memory          MemoryStats            `json:"memory"`
	Cache           CacheStats             `json:"cache"`
	Server          ServerStats            `json:"server"`
	Indexes         IndexStats             `json:"indexes"`
	BackgroundTasks map[string]interface{} `json:"background_tasks,omitempty"`
	RequestTime     time.Time              `json:"request_time"`
}

type DatabaseStats struct {
	OpenConnections int    `json:"open_connections"`
	InUse           int    `json:"in_use"`
	Idle            int    `json:"idle"`
	WaitCount       int64  `json:"wait_count"`
	WaitDuration    string `json:"wait_duration"` // Duration as string for Swagger compatibility
	MaxIdleClosed   int64  `json:"max_idle_closed"`
	MaxLifetime     string `json:"max_lifetime"` // Duration as string for Swagger compatibility
}

type MemoryStats struct {
	Alloc       uint64 `json:"alloc_mb"`
	TotalAlloc  uint64 `json:"total_alloc_mb"`
	Sys         uint64 `json:"sys_mb"`
	NumGC       uint32 `json:"num_gc"`
	Goroutines  int    `json:"goroutines"`
	HeapInuse   uint64 `json:"heap_inuse_mb"`
	HeapObjects uint64 `json:"heap_objects"`
}

type CacheStats struct {
	Enabled    bool                   `json:"enabled"`
	Type       string                 `json:"type"`
	HTTPCache  map[string]interface{} `json:"http_cache,omitempty"`
	BasicStats map[string]interface{} `json:"basic_stats,omitempty"`
}

type ServerStats struct {
	Uptime          string `json:"uptime"` // Duration as string for Swagger compatibility
	CompressionUsed bool   `json:"compression_enabled"`
	RateLimitUsed   bool   `json:"rate_limit_enabled"`
	HTTPCacheUsed   bool   `json:"http_cache_enabled"`
}

type IndexStats struct {
	WordsIndexes    []string `json:"words_indexes"`
	GrammarsIndexes []string `json:"grammars_indexes"`
	TotalIndexes    int      `json:"total_indexes"`
}

var serverStartTime = time.Now()

// @Summary Get performance statistics
// @Description Get comprehensive performance metrics for the application
// @Tags Performance
// @Accept json
// @Produce json
// @Success 200 {object} PerformanceStats "Performance statistics"
// @Failure 500 {object} Response "Failed to get performance stats"
// @Router /api/v1/performance/stats [get]
func (server *Server) getPerformanceStats(ctx *gin.Context) {
	stats := PerformanceStats{
		RequestTime: time.Now(),
	} // Get database stats (simplified - cannot access underlying sql.DB from Querier interface)
	stats.Database = DatabaseStats{
		OpenConnections: 0, // Would need direct access to sql.DB
		InUse:           0,
		Idle:            0,
		WaitCount:       0,
		WaitDuration:    "0s", // Duration as string
		MaxIdleClosed:   0,
		MaxLifetime:     (5 * time.Minute).String(), // Duration as string
	}

	// Get memory stats
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)
	stats.Memory = MemoryStats{
		Alloc:       bToMb(memStats.Alloc),
		TotalAlloc:  bToMb(memStats.TotalAlloc),
		Sys:         bToMb(memStats.Sys),
		NumGC:       memStats.NumGC,
		Goroutines:  runtime.NumGoroutine(),
		HeapInuse:   bToMb(memStats.HeapInuse),
		HeapObjects: memStats.HeapObjects,
	}

	// Get cache stats
	stats.Cache = CacheStats{
		Enabled: server.config.CacheEnabled,
		Type:    server.config.CacheType,
	}
	if server.httpCache != nil {
		stats.Cache.HTTPCache = server.httpCache.GetCacheStats(ctx)
	}
	// Get background processor stats
	if server.backgroundProcessor != nil {
		bgStats := server.backgroundProcessor.GetStats()
		stats.BackgroundTasks = map[string]interface{}{
			"total_tasks":     bgStats.TotalTasks,
			"completed_tasks": bgStats.CompletedTasks,
			"failed_tasks":    bgStats.FailedTasks,
			"queued_tasks":    bgStats.QueuedTasks,
			"active_tasks":    bgStats.ActiveTasks,
			"active_workers":  bgStats.ActiveWorkers,
			"total_workers":   bgStats.TotalWorkers,
			"average_time_ms": bgStats.AverageTime.Milliseconds(),
		}
	}
	// Get server stats
	stats.Server = ServerStats{
		Uptime:          time.Since(serverStartTime).String(), // Duration as string
		CompressionUsed: true,                                 // We enabled gzip compression
		RateLimitUsed:   server.config.RateLimitEnabled,
		HTTPCacheUsed:   server.config.HTTPCacheEnabled,
	}

	// Get index information (simplified)
	stats.Indexes = IndexStats{
		WordsIndexes: []string{
			"idx_words_level",
			"idx_words_freq",
			"idx_words_word_trgm",
			"idx_words_short_mean_trgm",
			"idx_words_level_freq",
		},
		GrammarsIndexes: []string{
			"idx_grammars_level",
			"idx_grammars_tag_gin",
			"idx_grammars_title_trgm",
			"idx_grammars_grammar_key_trgm",
		},
		TotalIndexes: 15, // Approximate count of performance indexes
	}

	logger.Debug("Performance stats requested")
	SuccessResponse(ctx, http.StatusOK, "Performance statistics retrieved successfully", stats)
}

// Helper function to convert bytes to megabytes
func bToMb(b uint64) uint64 {
	return b / 1024 / 1024
}

// @Summary Get search performance test
// @Description Test search performance with timing information
// @Tags Performance
// @Accept json
// @Produce json
// @Param query query string true "Search query to test"
// @Param limit query int false "Limit" default(10)
// @Success 200 {object} map[string]interface{} "Search performance results"
// @Failure 400 {object} Response "Invalid parameters"
// @Failure 500 {object} Response "Search failed"
// @Router /api/v1/performance/search-test [get]
func (server *Server) searchPerformanceTest(ctx *gin.Context) {
	type testRequest struct {
		Query string `form:"query" binding:"required"`
		Limit int32  `form:"limit" binding:"min=1,max=100"`
	}

	var req testRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid parameters", err)
		return
	}

	if req.Limit == 0 {
		req.Limit = 10
	}

	results := make(map[string]interface{})

	// Test word search performance
	startTime := time.Now()
	arg := db.SearchWordsParams{
		Column1: sql.NullString{String: req.Query, Valid: true},
		Limit:   req.Limit,
		Offset:  0,
	}
	words, err := server.store.SearchWords(ctx, arg)
	wordSearchDuration := time.Since(startTime)

	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Word search failed", err)
		return
	}

	results["word_search"] = map[string]interface{}{
		"duration_ms":  wordSearchDuration.Milliseconds(),
		"result_count": len(words),
		"query":        req.Query,
		"limit":        req.Limit,
	}

	// Test grammar search performance
	startTime = time.Now()
	grammarArg := db.SearchGrammarsParams{
		Column1: sql.NullString{String: req.Query, Valid: true},
		Limit:   req.Limit,
		Offset:  0,
	}
	grammars, err := server.store.SearchGrammars(ctx, grammarArg)
	grammarSearchDuration := time.Since(startTime)

	if err != nil {
		logger.Warn("Grammar search failed during performance test: %v", err)
		results["grammar_search"] = map[string]interface{}{
			"error":       "Grammar search failed",
			"duration_ms": grammarSearchDuration.Milliseconds(),
		}
	} else {
		results["grammar_search"] = map[string]interface{}{
			"duration_ms":  grammarSearchDuration.Milliseconds(),
			"result_count": len(grammars),
			"query":        req.Query,
			"limit":        req.Limit,
		}
	}

	results["total_duration_ms"] = wordSearchDuration.Milliseconds() + grammarSearchDuration.Milliseconds()
	results["test_time"] = time.Now()

	logger.Info("Search performance test completed: %s (Words: %dms, Grammars: %dms)",
		req.Query, wordSearchDuration.Milliseconds(), grammarSearchDuration.Milliseconds())

	SuccessResponse(ctx, http.StatusOK, "Search performance test completed", results)
}
