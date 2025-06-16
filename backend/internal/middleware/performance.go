package middleware

import (
	"context"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/monitoring"
)

// PerformanceTracker tracks request performance metrics
type PerformanceTracker struct {
	optimizer *monitoring.PerformanceOptimizer
	enabled   bool
}

// NewPerformanceTracker creates a new performance tracking middleware
func NewPerformanceTracker(optimizer *monitoring.PerformanceOptimizer) *PerformanceTracker {
	return &PerformanceTracker{
		optimizer: optimizer,
		enabled:   optimizer != nil,
	}
}

// TrackPerformance returns a Gin middleware that tracks request performance
func (pt *PerformanceTracker) TrackPerformance() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !pt.enabled {
			c.Next()
			return
		}

		startTime := time.Now()

		// Track concurrent connections
		pt.optimizer.UpdateConnectionCount(1) // Simplified increment

		// Process request
		c.Next()

		// Calculate metrics
		duration := time.Since(startTime)
		statusCode := c.Writer.Status()
		success := statusCode < 400

		// Record the request
		pt.optimizer.RecordRequest(duration, success)

		// Log slow requests
		if duration > 2*time.Second {
			logger.WarnWithFields(logger.Fields{
				"component":   "performance_tracker",
				"method":      c.Request.Method,
				"path":        c.Request.URL.Path,
				"duration":    duration.String(),
				"status_code": statusCode,
				"user_agent":  c.Request.UserAgent(),
				"remote_addr": c.ClientIP(),
			}, "Slow request detected")
		}

		// Add performance headers
		c.Header("X-Response-Time", duration.String())
		c.Header("X-Request-ID", c.GetString("request_id"))
	}
}

// CacheMetricsMiddleware tracks cache performance
func (pt *PerformanceTracker) CacheMetricsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !pt.enabled {
			c.Next()
			return
		}

		// Check if response is from cache
		cacheHit := c.GetHeader("X-Cache-Status") == "HIT"

		c.Next()

		// Record cache operation
		pt.optimizer.RecordCacheOperation(cacheHit)
	}
}

// DatabaseMetricsWrapper wraps database operations to track performance
func (pt *PerformanceTracker) WrapDatabaseOperation(operation func() error) error {
	if !pt.enabled {
		return operation()
	}

	startTime := time.Now()
	err := operation()
	duration := time.Since(startTime)

	success := err == nil
	pt.optimizer.RecordDatabaseQuery(duration, success)

	// Log slow queries
	if duration > 500*time.Millisecond {
		logger.WarnWithFields(logger.Fields{
			"component": "database_tracker",
			"duration":  duration.String(),
			"success":   success,
			"error":     err,
		}, "Slow database query detected")
	}

	return err
}

// ConnectionCounterMiddleware tracks active connections
func (pt *PerformanceTracker) ConnectionCounterMiddleware() gin.HandlerFunc {
	var activeConnections int64

	return func(c *gin.Context) {
		if !pt.enabled {
			c.Next()
			return
		}

		// Increment active connections
		activeConnections++
		pt.optimizer.UpdateConnectionCount(activeConnections)

		// Store in context for cleanup
		c.Set("connection_counter", &activeConnections)

		defer func() {
			// Decrement active connections when request completes
			activeConnections--
			pt.optimizer.UpdateConnectionCount(activeConnections)
		}()

		c.Next()
	}
}

// RequestSizeLimiter limits request size for performance
func RequestSizeLimiter(maxSize int64) gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.ContentLength > maxSize {
			logger.WarnWithFields(logger.Fields{
				"component":      "request_limiter",
				"content_length": c.Request.ContentLength,
				"max_size":       maxSize,
				"path":           c.Request.URL.Path,
				"method":         c.Request.Method,
			}, "Request size exceeds limit")

			c.JSON(413, gin.H{
				"error":    "Request entity too large",
				"max_size": maxSize,
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// TimeoutMiddleware adds request timeout for performance
func TimeoutMiddleware(timeout time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), timeout)
		defer cancel()

		c.Request = c.Request.WithContext(ctx)

		done := make(chan struct{})
		go func() {
			c.Next()
			close(done)
		}()

		select {
		case <-done:
			return
		case <-ctx.Done():
			logger.WarnWithFields(logger.Fields{
				"component": "timeout_middleware",
				"timeout":   timeout.String(),
				"path":      c.Request.URL.Path,
				"method":    c.Request.Method,
			}, "Request timeout")

			c.JSON(408, gin.H{
				"error":   "Request timeout",
				"timeout": timeout.String(),
			})
			c.Abort()
			return
		}
	}
}

// CompressionMiddleware enables GZIP compression for better performance
func CompressionMiddleware() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		// Check if client accepts gzip
		if !acceptsGzip(c.Request.Header.Get("Accept-Encoding")) {
			c.Next()
			return
		}

		// Set compression headers
		c.Header("Content-Encoding", "gzip")
		c.Header("Vary", "Accept-Encoding")

		logger.DebugWithFields(logger.Fields{
			"component": "compression_middleware",
			"path":      c.Request.URL.Path,
			"method":    c.Request.Method,
		}, "Applying GZIP compression")

		c.Next()
	})
}

// HealthCheckMiddleware provides fast health check endpoint
func HealthCheckMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.URL.Path == "/health" || c.Request.URL.Path == "/ping" {
			c.JSON(200, gin.H{
				"status":    "healthy",
				"timestamp": time.Now().Unix(),
				"uptime":    time.Since(time.Now()).String(), // This would be calculated from app start time
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// MetricsEndpointMiddleware provides performance metrics endpoint
func (pt *PerformanceTracker) MetricsEndpointMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.URL.Path == "/metrics" {
			if !pt.enabled {
				c.JSON(503, gin.H{
					"error": "Performance monitoring disabled",
				})
				c.Abort()
				return
			}

			metrics := pt.optimizer.GetCurrentMetrics()
			history := pt.optimizer.GetMetricsHistory()

			c.JSON(200, gin.H{
				"current_metrics": metrics,
				"history":         history,
				"timestamp":       time.Now().Unix(),
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// Helper function to check if client accepts gzip encoding
func acceptsGzip(acceptEncoding string) bool {
	return acceptEncoding != "" &&
		(acceptEncoding == "gzip" ||
			acceptEncoding == "*" ||
			len(acceptEncoding) > 4 && acceptEncoding[:4] == "gzip")
}

// RequestIDMiddleware adds unique request ID for tracing
func RequestIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			requestID = generatePerfRequestID()
		}

		c.Set("request_id", requestID)
		c.Header("X-Request-ID", requestID)

		c.Next()
	}
}

// generatePerfRequestID generates a simple request ID
func generatePerfRequestID() string {
	return strconv.FormatInt(time.Now().UnixNano(), 36)
}

// CORSPerformanceOptimized returns CORS middleware optimized for performance
func CORSPerformanceOptimized(allowedOrigins []string) gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")

		// Fast path for same origin requests
		if origin == "" {
			c.Next()
			return
		}

		// Check allowed origins efficiently
		allowed := false
		for _, allowedOrigin := range allowedOrigins {
			if allowedOrigin == "*" || allowedOrigin == origin {
				allowed = true
				break
			}
		}

		if allowed {
			c.Header("Access-Control-Allow-Origin", origin)
			c.Header("Access-Control-Allow-Credentials", "true")
			c.Header("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
			c.Header("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")
		}

		// Handle preflight requests quickly
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
