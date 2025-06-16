package api

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/performance"
)

// PerformanceController handles performance monitoring endpoints
type PerformanceController struct {
	monitor *performance.PerformanceMonitor
}

// NewPerformanceController creates a new performance controller
func NewPerformanceController(monitor *performance.PerformanceMonitor) *PerformanceController {
	return &PerformanceController{
		monitor: monitor,
	}
}

// getUserID safely extracts user ID from context
func getUserID(c *gin.Context) int32 {
	if userID, exists := c.Get("user_id"); exists {
		if uid, ok := userID.(int32); ok {
			return uid
		}
	}
	return 0
}

// GetPerformanceMetrics gets comprehensive performance metrics
// @Summary Get database performance metrics
// @Description Retrieves comprehensive database performance metrics including index usage, table stats, and cache hit ratios
// @Tags performance
// @Security ApiKeyAuth
// @Produce json
// @Success 200 {object} performance.PerformanceMetrics
// @Failure 500 {object} Response "Server error"
// @Router /api/v1/performance/metrics [get]
func (pc *PerformanceController) GetPerformanceMetrics(c *gin.Context) {
	metrics, err := pc.monitor.GetPerformanceMetrics(c.Request.Context())
	if err != nil {
		logger.ErrorWithFields(logger.Fields{
			"component": "api",
			"handler":   "GetPerformanceMetrics",
			"error":     err.Error(),
		}, "Failed to get performance metrics")
		ErrorResponseWithMessage(c, http.StatusInternalServerError, "Failed to retrieve performance metrics", err)
		return
	}
	logger.InfoWithFields(logger.Fields{
		"component": "api",
		"handler":   "GetPerformanceMetrics",
		"user_id":   getUserID(c),
	}, "Performance metrics retrieved successfully")

	c.JSON(http.StatusOK, metrics)
}

// GetIndexUsageStats gets index usage statistics
// @Summary Get index usage statistics
// @Description Retrieves detailed index usage statistics for performance analysis
// @Tags performance
// @Security ApiKeyAuth
// @Produce json
// @Success 200 {array} performance.IndexUsageStats
// @Failure 500 {object} Response "Server error"
// @Router /api/v1/performance/indexes [get]
func (pc *PerformanceController) GetIndexUsageStats(c *gin.Context) {
	stats, err := pc.monitor.GetIndexUsageStats(c.Request.Context())
	if err != nil {
		logger.ErrorWithFields(logger.Fields{
			"component": "api",
			"handler":   "GetIndexUsageStats",
			"error":     err.Error(),
		}, "Failed to get index usage stats")

		ErrorResponseWithMessage(c, http.StatusInternalServerError, "Failed to retrieve index usage statistics", err)
		return
	}
	logger.InfoWithFields(logger.Fields{
		"component": "api",
		"handler":   "GetIndexUsageStats",
		"user_id":   getUserID(c),
		"count":     len(stats),
	}, "Index usage statistics retrieved successfully")

	c.JSON(http.StatusOK, stats)
}

// GetTableStats gets table statistics
// @Summary Get table statistics
// @Description Retrieves detailed table statistics including sequential scans and size information
// @Tags performance
// @Security ApiKeyAuth
// @Produce json
// @Success 200 {array} performance.TableStats
// @Failure 500 {object} Response "Server error"
// @Router /api/v1/performance/tables [get]
func (pc *PerformanceController) GetTableStats(c *gin.Context) {
	stats, err := pc.monitor.GetTableStats(c.Request.Context())
	if err != nil {
		logger.ErrorWithFields(logger.Fields{
			"component": "api",
			"handler":   "GetTableStats",
			"error":     err.Error(),
		}, "Failed to get table stats")
		ErrorResponseWithMessage(c, http.StatusInternalServerError, "Failed to retrieve table statistics", err)
		return
	}
	logger.InfoWithFields(logger.Fields{
		"component": "api",
		"handler":   "GetTableStats",
		"user_id":   getUserID(c),
		"count":     len(stats),
	}, "Table statistics retrieved successfully")

	c.JSON(http.StatusOK, stats)
}

// GetCacheHitRatio gets cache hit ratio statistics
// @Summary Get cache hit ratio
// @Description Retrieves cache hit ratio statistics for buffer and index caches
// @Tags performance
// @Security ApiKeyAuth
// @Produce json
// @Success 200 {object} performance.CacheStats
// @Failure 500 {object} Response "Server error"
// @Router /api/v1/performance/cache [get]
func (pc *PerformanceController) GetCacheHitRatio(c *gin.Context) {
	stats, err := pc.monitor.GetCacheHitRatio(c.Request.Context())
	if err != nil {
		logger.ErrorWithFields(logger.Fields{
			"component": "api",
			"handler":   "GetCacheHitRatio",
			"error":     err.Error(),
		}, "Failed to get cache hit ratio")
		ErrorResponseWithMessage(c, http.StatusInternalServerError, "Failed to retrieve cache hit ratio", err)
		return
	}
	logger.InfoWithFields(logger.Fields{
		"component":  "api",
		"handler":    "GetCacheHitRatio",
		"user_id":    getUserID(c),
		"buffer_hit": stats.BufferCacheHitRatio,
		"index_hit":  stats.IndexCacheHitRatio,
	}, "Cache hit ratio retrieved successfully")

	c.JSON(http.StatusOK, stats)
}

// GetOptimizationRecommendations gets optimization recommendations
// @Summary Get optimization recommendations
// @Description Retrieves automated recommendations for database optimization
// @Tags performance
// @Security ApiKeyAuth
// @Produce json
// @Success 200 {array} performance.OptimizationRecommendation
// @Failure 500 {object} Response "Server error"
// @Router /api/v1/performance/recommendations [get]
func (pc *PerformanceController) GetOptimizationRecommendations(c *gin.Context) {
	recommendations, err := pc.monitor.GetOptimizationRecommendations(c.Request.Context())
	if err != nil {
		logger.ErrorWithFields(logger.Fields{
			"component": "api",
			"handler":   "GetOptimizationRecommendations",
			"error":     err.Error(),
		}, "Failed to get optimization recommendations")

		ErrorResponseWithMessage(c, http.StatusInternalServerError, "Failed to retrieve optimization recommendations", err)
		return
	}
	logger.InfoWithFields(logger.Fields{
		"component": "api",
		"handler":   "GetOptimizationRecommendations",
		"user_id":   getUserID(c),
		"count":     len(recommendations),
	}, "Optimization recommendations retrieved successfully")

	c.JSON(http.StatusOK, recommendations)
}

// RunOptimization executes database optimization
// @Summary Run database optimization
// @Description Executes automated database optimization procedures
// @Tags performance
// @Security ApiKeyAuth
// @Produce json
// @Success 200 {object} map[string]string
// @Failure 500 {object} Response "Server error"
// @Router /api/v1/performance/optimize [post]
func (pc *PerformanceController) RunOptimization(c *gin.Context) {
	result, err := pc.monitor.RunOptimization(c.Request.Context())
	if err != nil {
		logger.ErrorWithFields(logger.Fields{
			"component": "api",
			"handler":   "RunOptimization",
			"error":     err.Error(),
		}, "Failed to run optimization")

		ErrorResponseWithMessage(c, http.StatusInternalServerError, "Failed to run database optimization", err)
		return
	}
	logger.InfoWithFields(logger.Fields{
		"component": "api",
		"handler":   "RunOptimization",
		"user_id":   getUserID(c),
		"result":    result,
	}, "Database optimization executed successfully")

	c.JSON(http.StatusOK, map[string]string{
		"result":    result,
		"timestamp": time.Now().Format(time.RFC3339),
	})
}

// PerformanceDashboard provides a comprehensive performance dashboard
// @Summary Get performance dashboard
// @Description Provides a comprehensive performance dashboard with key metrics and alerts
// @Tags performance
// @Security ApiKeyAuth
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Failure 500 {object} Response "Server error"
// @Router /api/v1/performance/dashboard [get]
func (pc *PerformanceController) PerformanceDashboard(c *gin.Context) {
	// Get comprehensive metrics
	metrics, err := pc.monitor.GetPerformanceMetrics(c.Request.Context())
	if err != nil {
		logger.ErrorWithFields(logger.Fields{
			"component": "api",
			"handler":   "PerformanceDashboard",
			"error":     err.Error(),
		}, "Failed to get performance metrics for dashboard")

		ErrorResponseWithMessage(c, http.StatusInternalServerError, "Failed to retrieve performance dashboard", err)
		return
	}

	// Get recommendations
	recommendations, err := pc.monitor.GetOptimizationRecommendations(c.Request.Context())
	if err != nil {
		logger.WarnWithFields(logger.Fields{
			"component": "api",
			"handler":   "PerformanceDashboard",
			"error":     err.Error(),
		}, "Failed to get recommendations for dashboard")
		recommendations = []performance.OptimizationRecommendation{}
	}

	// Analyze metrics and create alerts
	alerts := analyzeMetricsForAlerts(metrics)

	// Create dashboard summary
	dashboard := map[string]interface{}{
		"timestamp":       time.Now().Format(time.RFC3339),
		"metrics":         metrics,
		"recommendations": recommendations,
		"alerts":          alerts,
		"summary": map[string]interface{}{
			"total_indexes":          len(metrics.IndexUsage),
			"unused_indexes":         countUnusedIndexes(metrics.IndexUsage),
			"high_seq_scan_tables":   countHighSeqScanTables(metrics.TableStats),
			"buffer_cache_hit_ratio": metrics.CacheHitRatio.BufferCacheHitRatio,
			"index_cache_hit_ratio":  metrics.CacheHitRatio.IndexCacheHitRatio,
			"total_recommendations":  len(recommendations),
			"critical_alerts":        countCriticalAlerts(alerts),
		},
	}
	logger.InfoWithFields(logger.Fields{
		"component": "api",
		"handler":   "PerformanceDashboard",
		"user_id":   getUserID(c),
	}, "Performance dashboard generated successfully")

	c.JSON(http.StatusOK, dashboard)
}

// Helper functions for performance analysis

func analyzeMetricsForAlerts(metrics *performance.PerformanceMetrics) []map[string]interface{} {
	var alerts []map[string]interface{}

	// Check cache hit ratios
	if metrics.CacheHitRatio.BufferCacheHitRatio < 95 {
		alerts = append(alerts, map[string]interface{}{
			"type":           "warning",
			"category":       "cache",
			"message":        "Low buffer cache hit ratio",
			"value":          metrics.CacheHitRatio.BufferCacheHitRatio,
			"threshold":      95.0,
			"recommendation": "Consider increasing shared_buffers configuration",
		})
	}

	// Check for tables with high sequential scan ratios
	for _, table := range metrics.TableStats {
		if table.SeqScanPercentage > 75 && table.SequentialScans > 100 {
			alerts = append(alerts, map[string]interface{}{
				"type":           "critical",
				"category":       "table_scans",
				"message":        "High sequential scan ratio detected",
				"table":          table.TableName,
				"value":          table.SeqScanPercentage,
				"threshold":      75.0,
				"recommendation": "Consider adding appropriate indexes",
			})
		}
	}

	// Check for unused indexes
	for _, idx := range metrics.IndexUsage {
		if idx.UsageLevel == "UNUSED" && idx.Scans == 0 {
			alerts = append(alerts, map[string]interface{}{
				"type":           "info",
				"category":       "unused_indexes",
				"message":        "Unused index detected",
				"table":          idx.TableName,
				"index":          idx.IndexName,
				"size":           idx.IndexSize,
				"recommendation": "Consider dropping if not needed for constraints",
			})
		}
	}

	return alerts
}

func countUnusedIndexes(indexStats []performance.IndexUsageStats) int {
	count := 0
	for _, idx := range indexStats {
		if idx.UsageLevel == "UNUSED" {
			count++
		}
	}
	return count
}

func countHighSeqScanTables(tableStats []performance.TableStats) int {
	count := 0
	for _, table := range tableStats {
		if table.SeqScanPercentage > 50 {
			count++
		}
	}
	return count
}

func countCriticalAlerts(alerts []map[string]interface{}) int {
	count := 0
	for _, alert := range alerts {
		if alert["type"] == "critical" {
			count++
		}
	}
	return count
}
