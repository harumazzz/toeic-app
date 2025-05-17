package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
)

// Logger is a middleware that logs request information
func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Start timer
		startTime := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		// Process request
		c.Next()

		// Calculate latency
		endTime := time.Now()
		latency := endTime.Sub(startTime)

		// Get status and request details
		statusCode := c.Writer.Status()
		clientIP := c.ClientIP()
		method := c.Request.Method

		// Format query string if present
		if raw != "" {
			path = path + "?" + raw
		}

		// Format the log line for HTTP request
		logMsg := "%s | %3d | %13v | %15s | %-7s %s"
		logArgs := []interface{}{
			"GIN",
			statusCode,
			latency,
			clientIP,
			method,
			path,
		}

		// Log with different level based on status code
		switch {
		case statusCode >= 500:
			logger.Error(logMsg, logArgs...)
		case statusCode >= 400:
			logger.Warn(logMsg, logArgs...)
		case statusCode >= 300:
			logger.Info(logMsg, logArgs...)
		default:
			logger.Info(logMsg, logArgs...)
		}
	}
}
