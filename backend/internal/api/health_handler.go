package api

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// Health check response
type HealthCheckResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Message   string    `json:"message"`
}

// @Summary     Health check
// @Description Check if the API server is running
// @Tags        health
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=HealthCheckResponse} "API is healthy"
// @Router      /health [get]
func (server *Server) healthCheck(ctx *gin.Context) {
	response := HealthCheckResponse{
		Status:    "UP",
		Timestamp: time.Now(),
		Message:   "API is running",
	}

	SuccessResponse(ctx, http.StatusOK, "Health check successful", response)
}
