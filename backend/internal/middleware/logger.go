package middleware

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
)

// Logger is a middleware that logs request information with structured logging
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

		// Create structured log fields
		fields := logger.Fields{
			"component":     "http",
			"method":        method,
			"path":          path,
			"status_code":   statusCode,
			"latency_ms":    latency.Milliseconds(),
			"latency":       latency.String(),
			"client_ip":     clientIP,
			"user_agent":    c.GetHeader("User-Agent"),
			"request_id":    c.GetHeader("X-Request-ID"),
			"content_type":  c.GetHeader("Content-Type"),
			"response_size": c.Writer.Size(),
		}

		// Add user information if available
		if userID := c.GetHeader("X-User-ID"); userID != "" {
			fields["user_id"] = userID
		}
		// Get user from auth payload if available
		if payload, exists := c.Get("authorization_payload"); exists && payload != nil {
			if userPayload, ok := payload.(interface{ GetID() int32 }); ok {
				fields["authenticated_user_id"] = userPayload.GetID()
			}
		}

		// Format the message
		message := fmt.Sprintf("HTTP %s %s", method, path)
		// Log with different level based on status code
		switch {
		case statusCode >= 500:
			logger.ErrorWithFields(fields, "%s", message)
		case statusCode >= 400:
			logger.WarnWithFields(fields, "%s", message)
		case latency > 5*time.Second:
			// Log slow requests as warnings
			fields["slow_request"] = true
			logger.WarnWithFields(fields, "%s", message)
		default:
			logger.InfoWithFields(fields, "%s", message)
		}
	}
}
