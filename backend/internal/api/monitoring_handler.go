package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// @Summary Get active alerts
// @Description Get all currently active monitoring alerts
// @Tags monitoring
// @Accept json
// @Produce json
// @Success 200 {object} Response{data=[]monitoring.Alert} "Active alerts retrieved successfully"
// @Router /alerts [get]
func (server *Server) getActiveAlerts(ctx *gin.Context) {
	if server.monitoringService == nil || server.monitoringService.GetAlertManager() == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Alert manager not available", nil)
		return
	}

	alerts := server.monitoringService.GetAlertManager().GetActiveAlerts()
	SuccessResponse(ctx, http.StatusOK, "Active alerts retrieved successfully", alerts)
}

// @Summary Get alert history
// @Description Get recent alert history
// @Tags monitoring
// @Accept json
// @Produce json
// @Param limit query int false "Maximum number of alerts to return" default(50)
// @Success 200 {object} Response{data=[]monitoring.Alert} "Alert history retrieved successfully"
// @Router /alerts/history [get]
func (server *Server) getAlertHistory(ctx *gin.Context) {
	if server.monitoringService == nil || server.monitoringService.GetAlertManager() == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Alert manager not available", nil)
		return
	}

	// Parse limit parameter
	limit := 50 // default
	if limitStr := ctx.Query("limit"); limitStr != "" {
		if parsedLimit, err := strconv.Atoi(limitStr); err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}

	// Cap the limit to prevent excessive memory usage
	if limit > 1000 {
		limit = 1000
	}

	alerts := server.monitoringService.GetAlertManager().GetAlertHistory(limit)
	SuccessResponse(ctx, http.StatusOK, "Alert history retrieved successfully", alerts)
}

// @Summary Get monitoring status
// @Description Get the overall monitoring system status
// @Tags monitoring
// @Accept json
// @Produce json
// @Success 200 {object} Response{data=object} "Monitoring status retrieved successfully"
// @Router /monitoring/status [get]
func (server *Server) getMonitoringStatus(ctx *gin.Context) {
	if server.monitoringService == nil {
		ErrorResponse(ctx, http.StatusServiceUnavailable, "Monitoring service not available", nil)
		return
	}

	status := map[string]interface{}{
		"enabled": server.monitoringService.IsEnabled(),
		"components": map[string]interface{}{
			"metrics_enabled": server.monitoringService.GetMonitor() != nil,
			"health_enabled":  server.monitoringService.GetHealthService() != nil,
			"alerts_enabled":  server.monitoringService.GetAlertManager() != nil,
		},
	}

	if server.monitoringService.GetAlertManager() != nil {
		activeAlerts := server.monitoringService.GetAlertManager().GetActiveAlerts()
		status["active_alerts_count"] = len(activeAlerts)
	}

	if server.monitoringService.GetHealthService() != nil {
		healthCheck := server.monitoringService.GetHealthService().CheckHealth(ctx.Request.Context())
		status["overall_health"] = healthCheck.Status
		status["healthy_components"] = 0
		status["total_components"] = len(healthCheck.Components)

		for _, component := range healthCheck.Components {
			if component.Status == "UP" {
				status["healthy_components"] = status["healthy_components"].(int) + 1
			}
		}
	}

	SuccessResponse(ctx, http.StatusOK, "Monitoring status retrieved successfully", status)
}
