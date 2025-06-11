package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
)

// @Summary Get concurrency metrics
// @Description Returns detailed concurrency metrics including active operations, worker pool status, and performance statistics
// @Tags Performance
// @Produce json
// @Success 200 {object} object{concurrency_metrics=object,connection_pool_stats=object,request_handler_stats=object} "Concurrency metrics retrieved successfully"
// @Failure 500 {object} Response "Internal Server Error"
// @Router /api/v1/performance/concurrency [get]
func (server *Server) getConcurrencyMetrics(ctx *gin.Context) {
	if !server.config.ConcurrencyEnabled {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Concurrency management is not enabled", nil)
		return
	}

	response := gin.H{}

	// Get concurrency manager metrics
	if server.concurrencyManager != nil {
		metrics := server.concurrencyManager.GetMetrics()
		response["concurrency_metrics"] = gin.H{
			"active_db_operations":    metrics.ActiveDBOperations,
			"active_http_operations":  metrics.ActiveHTTPOperations,
			"active_cache_operations": metrics.ActiveCacheOperations,
			"total_db_operations":     metrics.TotalDBOperations,
			"total_http_operations":   metrics.TotalHTTPOperations,
			"total_cache_operations":  metrics.TotalCacheOperations,
			"avg_db_latency_ms":       metrics.AvgDBLatency.Milliseconds(),
			"avg_http_latency_ms":     metrics.AvgHTTPLatency.Milliseconds(),
			"avg_cache_latency_ms":    metrics.AvgCacheLatency.Milliseconds(),
		}
		// Get database stats
		dbStats := server.concurrencyManager.GetDatabaseStats()
		response["database_stats"] = gin.H{
			"max_open_connections": dbStats.MaxOpenConnections,
			"open_connections":     dbStats.OpenConnections,
			"in_use":               dbStats.InUseConnections,
			"idle":                 dbStats.IdleConnections,
			"wait_count":           dbStats.WaitCount,
			"wait_duration_ms":     dbStats.WaitDuration.Milliseconds(),
			"max_idle_closed":      dbStats.MaxIdleClosed,
			"max_lifetime_closed":  dbStats.MaxLifetimeClosed,
		}
		// Get system stats
		systemStats := server.concurrencyManager.GetSystemStats()
		response["system_stats"] = gin.H{
			"cpu_count":          systemStats.NumCPU,
			"memory_usage_bytes": systemStats.MemoryUsage,
			"memory_limit_bytes": systemStats.MemoryLimit,
			"goroutine_count":    systemStats.NumGoroutines,
			"last_updated":       systemStats.LastUpdate,
		}
	}

	// Get connection pool manager stats
	if server.poolManager != nil {
		poolStats := server.poolManager.GetStats()
		response["connection_pool_stats"] = gin.H{
			"current_max_open":     poolStats.Current.MaxOpenConnections,
			"current_open":         poolStats.Current.OpenConnections,
			"current_in_use":       poolStats.Current.InUse,
			"current_idle":         poolStats.Current.Idle,
			"max_connection_usage": poolStats.MaxConnUsage,
			"avg_connection_usage": poolStats.AvgConnUsage,
			"last_scale_event":     poolStats.LastScaleEvent,
		}
	}
	// Get concurrent request handler stats
	if server.concurrentHandler != nil {
		requestStats := server.concurrentHandler.GetStats()
		response["request_handler_stats"] = gin.H{
			"active_requests":          requestStats.ActiveRequests,
			"total_requests":           requestStats.TotalRequests,
			"completed_requests":       requestStats.CompletedRequests,
			"failed_requests":          requestStats.FailedRequests,
			"timeout_requests":         requestStats.TimeoutRequests,
			"degraded_requests":        requestStats.DegradedRequests,
			"average_response_time_ms": requestStats.AverageResponseTime.Milliseconds(),
			"max_response_time_ms":     requestStats.MaxResponseTime.Milliseconds(),
			"last_updated":             requestStats.LastUpdateTime,
		}
	}

	ctx.JSON(http.StatusOK, response)
}

// @Summary Get concurrency health status
// @Description Returns health status of concurrency management components
// @Tags Performance
// @Produce json
// @Success 200 {object} object{overall_health=string,components=object} "Health status retrieved successfully"
// @Failure 500 {object} Response "Internal Server Error"
// @Router /api/v1/performance/concurrency/health [get]
func (server *Server) getConcurrencyHealth(ctx *gin.Context) {
	if !server.config.ConcurrencyEnabled {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Concurrency management is not enabled", nil)
		return
	}

	response := gin.H{
		"overall_health": "healthy",
		"components":     gin.H{},
	}

	healthIssues := 0

	// Check concurrency manager health
	if server.concurrencyManager != nil {
		metrics := server.concurrencyManager.GetMetrics()
		isHealthy := true
		issues := []string{}
		// Check if we're approaching limits
		if metrics.ActiveDBOperations > int64(server.config.MaxConcurrentDBOps*80/100) {
			isHealthy = false
			issues = append(issues, "High DB operation usage")
		}
		if metrics.ActiveHTTPOperations > int64(server.config.MaxConcurrentHTTPOps*80/100) {
			isHealthy = false
			issues = append(issues, "High HTTP operation usage")
		}

		status := "healthy"
		if !isHealthy {
			status = "degraded"
			healthIssues++
		}

		response["components"].(gin.H)["concurrency_manager"] = gin.H{
			"status": status,
			"issues": issues,
		}
	}

	// Check connection pool health
	if server.poolManager != nil {
		poolStats := server.poolManager.GetStats()
		isHealthy := true
		issues := []string{}

		// Check connection usage
		if poolStats.MaxConnUsage > 90.0 {
			isHealthy = false
			issues = append(issues, "Very high connection usage")
		} else if poolStats.MaxConnUsage > 80.0 {
			isHealthy = false
			issues = append(issues, "High connection usage")
		}

		status := "healthy"
		if !isHealthy {
			status = "degraded"
			healthIssues++
		}

		response["components"].(gin.H)["connection_pool"] = gin.H{
			"status": status,
			"issues": issues,
		}
	}

	// Check request handler health
	if server.concurrentHandler != nil {
		requestStats := server.concurrentHandler.GetStats()
		isHealthy := true
		issues := []string{}

		// Check request processing health
		if requestStats.ActiveRequests > int64(server.config.MaxConcurrentHTTPOps*80/100) {
			isHealthy = false
			issues = append(issues, "High active request count")
		}
		// Check error rate
		if requestStats.TotalRequests > 0 {
			errorRate := float64(requestStats.FailedRequests) / float64(requestStats.TotalRequests) * 100
			if errorRate > 10.0 {
				isHealthy = false
				issues = append(issues, "High error rate")
			}
		}

		status := "healthy"
		if !isHealthy {
			status = "degraded"
			healthIssues++
		}

		response["components"].(gin.H)["request_handler"] = gin.H{
			"status": status,
			"issues": issues,
		}
	}

	// Set overall health
	if healthIssues > 0 {
		response["overall_health"] = "degraded"
	}

	ctx.JSON(http.StatusOK, response)
}

// @Summary Reset concurrency metrics
// @Description Resets all concurrency metrics and statistics (admin only)
// @Tags Performance
// @Security ApiKeyAuth
// @Produce json
// @Success 200 {object} Response "Metrics reset successfully"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 403 {object} Response "Forbidden - Admin access required"
// @Failure 500 {object} Response "Internal Server Error"
// @Router /api/v1/admin/performance/concurrency/reset [post]
func (server *Server) resetConcurrencyMetrics(ctx *gin.Context) {
	if !server.config.ConcurrencyEnabled {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Concurrency management is not enabled", nil)
		return
	}

	// Reset concurrency manager metrics
	if server.concurrencyManager != nil {
		if err := server.concurrencyManager.ResetMetrics(); err != nil {
			logger.Error("Failed to reset concurrency manager metrics: %v", err)
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to reset concurrency metrics", err)
			return
		}
	}

	// Reset connection pool manager stats
	if server.poolManager != nil {
		if err := server.poolManager.ResetStats(); err != nil {
			logger.Error("Failed to reset connection pool stats: %v", err)
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to reset connection pool stats", err)
			return
		}
	}

	// Reset request handler stats
	if server.concurrentHandler != nil {
		if err := server.concurrentHandler.ResetStats(); err != nil {
			logger.Error("Failed to reset request handler stats: %v", err)
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to reset request handler stats", err)
			return
		}
	}
	logger.Info("Concurrency metrics reset by admin")
	ctx.JSON(http.StatusOK, gin.H{"message": "Concurrency metrics reset successfully"})
}
