package api

import (
	"net/http"
	"runtime"
	"time"

	"github.com/gin-gonic/gin"
)

// MetricsResponse contains the system metrics
type MetricsResponse struct {
	Uptime       string    `json:"uptime"`
	NumGoroutine int       `json:"num_goroutine"`
	MemStats     MemStats  `json:"mem_stats"`
	Timestamp    time.Time `json:"timestamp"`
}

// MemStats contains memory-related metrics
type MemStats struct {
	Alloc        uint64 `json:"alloc"`
	TotalAlloc   uint64 `json:"total_alloc"`
	Sys          uint64 `json:"sys"`
	NumGC        uint32 `json:"num_gc"`
	PauseTotalNs uint64 `json:"pause_total_ns"`
}

// Global variable to store the server start time
var startTime = time.Now()

// @Summary     Get system metrics
// @Description Get system metrics and health information
// @Tags        monitoring
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=MetricsResponse} "Metrics retrieved successfully"
// @Router      /metrics [get]
func (server *Server) getMetrics(ctx *gin.Context) {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	metrics := MetricsResponse{
		Uptime:       time.Since(startTime).String(),
		NumGoroutine: runtime.NumGoroutine(),
		MemStats: MemStats{
			Alloc:        m.Alloc,
			TotalAlloc:   m.TotalAlloc,
			Sys:          m.Sys,
			NumGC:        m.NumGC,
			PauseTotalNs: m.PauseTotalNs,
		},
		Timestamp: time.Now(),
	}

	SuccessResponse(ctx, http.StatusOK, "Metrics retrieved successfully", metrics)
}
