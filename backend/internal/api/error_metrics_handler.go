package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/errors"
	"github.com/toeic-app/internal/logger"
)

// ErrorMetricsHandler handles error metrics endpoints
type ErrorMetricsHandler struct {
	metrics *errors.ErrorMetrics
}

// NewErrorMetricsHandler creates a new error metrics handler
func NewErrorMetricsHandler(metrics *errors.ErrorMetrics) *ErrorMetricsHandler {
	return &ErrorMetricsHandler{
		metrics: metrics,
	}
}

// @Summary     Get error metrics summary
// @Description Get a comprehensive summary of error metrics including counts, rates, and top errors
// @Tags        monitoring
// @Accept      json
// @Produce     json
// @Param       top_errors query int false "Number of top errors to include" default(10)
// @Success     200 {object} Response{data=errors.ErrorSummary} "Error metrics retrieved successfully"
// @Failure     500 {object} Response "Server error"
// @Router      /api/v1/admin/metrics/errors/summary [get]
// @Security    ApiKeyAuth
func (h *ErrorMetricsHandler) GetErrorSummary(c *gin.Context) {
	// Parse query parameter for top errors limit
	topLimit := 10
	if topStr := c.Query("top_errors"); topStr != "" {
		if parsed, err := strconv.Atoi(topStr); err == nil && parsed > 0 && parsed <= 100 {
			topLimit = parsed
		}
	}

	summary := h.metrics.GetSummary(topLimit)

	logger.InfoWithFields(logger.Fields{
		"component":    "error_metrics",
		"operation":    "get_summary",
		"top_limit":    topLimit,
		"total_errors": summary.TotalErrors,
		"error_rate":   summary.ErrorRate,
	}, "Error metrics summary requested")

	SuccessResponse(c, http.StatusOK, "Error metrics retrieved successfully", summary)
}

// @Summary     Get error counts by code
// @Description Get error counts grouped by error code
// @Tags        monitoring
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=map[string]int64} "Error counts retrieved successfully"
// @Failure     500 {object} Response "Server error"
// @Router      /api/v1/admin/metrics/errors/counts [get]
// @Security    ApiKeyAuth
func (h *ErrorMetricsHandler) GetErrorCounts(c *gin.Context) {
	counts := h.metrics.GetErrorCounts()

	// Convert to map[string]int64 for JSON serialization
	result := make(map[string]int64)
	for code, count := range counts {
		result[string(code)] = count
	}

	logger.InfoWithFields(logger.Fields{
		"component":    "error_metrics",
		"operation":    "get_counts",
		"unique_codes": len(result),
	}, "Error counts by code requested")

	SuccessResponse(c, http.StatusOK, "Error counts retrieved successfully", result)
}

// @Summary     Get error counts by category
// @Description Get error counts grouped by category (CLIENT, SERVER, DATABASE, etc.)
// @Tags        monitoring
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=map[string]int64} "Category counts retrieved successfully"
// @Failure     500 {object} Response "Server error"
// @Router      /api/v1/admin/metrics/errors/categories [get]
// @Security    ApiKeyAuth
func (h *ErrorMetricsHandler) GetCategoryCounts(c *gin.Context) {
	counts := h.metrics.GetCategoryCounts()

	// Convert to map[string]int64 for JSON serialization
	result := make(map[string]int64)
	for category, count := range counts {
		result[string(category)] = count
	}

	logger.InfoWithFields(logger.Fields{
		"component":         "error_metrics",
		"operation":         "get_categories",
		"unique_categories": len(result),
	}, "Error counts by category requested")

	SuccessResponse(c, http.StatusOK, "Category counts retrieved successfully", result)
}

// @Summary     Get error counts by severity
// @Description Get error counts grouped by severity level (LOW, MEDIUM, HIGH, CRITICAL)
// @Tags        monitoring
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=map[string]int64} "Severity counts retrieved successfully"
// @Failure     500 {object} Response "Server error"
// @Router      /api/v1/admin/metrics/errors/severity [get]
// @Security    ApiKeyAuth
func (h *ErrorMetricsHandler) GetSeverityCounts(c *gin.Context) {
	counts := h.metrics.GetSeverityCounts()

	// Convert to map[string]int64 for JSON serialization
	result := make(map[string]int64)
	for severity, count := range counts {
		result[string(severity)] = count
	}

	logger.InfoWithFields(logger.Fields{
		"component":         "error_metrics",
		"operation":         "get_severity",
		"unique_severities": len(result),
	}, "Error counts by severity requested")

	SuccessResponse(c, http.StatusOK, "Severity counts retrieved successfully", result)
}

// @Summary     Get error counts by HTTP status
// @Description Get error counts grouped by HTTP status code
// @Tags        monitoring
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=map[string]int64} "HTTP status counts retrieved successfully"
// @Failure     500 {object} Response "Server error"
// @Router      /api/v1/admin/metrics/errors/status [get]
// @Security    ApiKeyAuth
func (h *ErrorMetricsHandler) GetHTTPStatusCounts(c *gin.Context) {
	counts := h.metrics.GetHTTPStatusCounts()

	// Convert to map[string]int64 for JSON serialization
	result := make(map[string]int64)
	for status, count := range counts {
		result[strconv.Itoa(status)] = count
	}

	logger.InfoWithFields(logger.Fields{
		"component":       "error_metrics",
		"operation":       "get_http_status",
		"unique_statuses": len(result),
	}, "Error counts by HTTP status requested")

	SuccessResponse(c, http.StatusOK, "HTTP status counts retrieved successfully", result)
}

// @Summary     Get error rate
// @Description Get the current error rate per minute
// @Tags        monitoring
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=object} "Error rate retrieved successfully"
// @Failure     500 {object} Response "Server error"
// @Router      /api/v1/admin/metrics/errors/rate [get]
// @Security    ApiKeyAuth
func (h *ErrorMetricsHandler) GetErrorRate(c *gin.Context) {
	rate := h.metrics.GetErrorRate()
	totalErrors := h.metrics.GetTotalErrors()

	result := map[string]interface{}{
		"error_rate_per_minute": rate,
		"total_errors":          totalErrors,
	}

	logger.InfoWithFields(logger.Fields{
		"component":    "error_metrics",
		"operation":    "get_rate",
		"error_rate":   rate,
		"total_errors": totalErrors,
	}, "Error rate requested")

	SuccessResponse(c, http.StatusOK, "Error rate retrieved successfully", result)
}

// @Summary     Reset error metrics
// @Description Reset all error metrics counters to zero
// @Tags        monitoring
// @Accept      json
// @Produce     json
// @Success     200 {object} Response "Error metrics reset successfully"
// @Failure     500 {object} Response "Server error"
// @Router      /api/v1/admin/metrics/errors/reset [post]
// @Security    ApiKeyAuth
func (h *ErrorMetricsHandler) ResetMetrics(c *gin.Context) {
	oldTotal := h.metrics.GetTotalErrors()
	h.metrics.Reset()

	logger.InfoWithFields(logger.Fields{
		"component":      "error_metrics",
		"operation":      "reset",
		"previous_total": oldTotal,
	}, "Error metrics reset")

	SuccessResponseWithMessage(c, http.StatusOK, "Error metrics reset successfully", map[string]interface{}{
		"previous_total_errors": oldTotal,
		"reset_at":              h.metrics.GetSummary(0).SinceReset,
	})
}

// @Summary     Get top errors
// @Description Get the most frequently occurring errors
// @Tags        monitoring
// @Accept      json
// @Produce     json
// @Param       limit query int false "Number of top errors to return" default(10)
// @Success     200 {object} Response{data=[]object} "Top errors retrieved successfully"
// @Failure     500 {object} Response "Server error"
// @Router      /api/v1/admin/metrics/errors/top [get]
// @Security    ApiKeyAuth
func (h *ErrorMetricsHandler) GetTopErrors(c *gin.Context) {
	// Parse limit parameter
	limit := 10
	if limitStr := c.Query("limit"); limitStr != "" {
		if parsed, err := strconv.Atoi(limitStr); err == nil && parsed > 0 && parsed <= 100 {
			limit = parsed
		}
	}

	topErrors := h.metrics.GetTopErrors(limit)

	// Convert to a more detailed structure
	result := make([]map[string]interface{}, len(topErrors))
	totalErrors := h.metrics.GetTotalErrors()

	for i, errorStat := range topErrors {
		percentage := 0.0
		if totalErrors > 0 {
			percentage = float64(errorStat.Count) / float64(totalErrors) * 100
		}

		result[i] = map[string]interface{}{
			"code":        string(errorStat.Code),
			"count":       errorStat.Count,
			"percentage":  percentage,
			"severity":    string(errorStat.Code.GetSeverity()),
			"category":    string(errorStat.Code.GetCategory()),
			"http_status": errorStat.Code.GetHTTPStatus(),
		}
	}

	logger.InfoWithFields(logger.Fields{
		"component":    "error_metrics",
		"operation":    "get_top_errors",
		"limit":        limit,
		"returned":     len(result),
		"total_errors": totalErrors,
	}, "Top errors requested")

	SuccessResponse(c, http.StatusOK, "Top errors retrieved successfully", result)
}
