package middleware

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
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

		// Format the log line
		logLine := fmt.Sprintf("[GIN] %v | %3d | %13v | %15s | %-7s %s",
			endTime.Format("2006/01/02 - 15:04:05"),
			statusCode,
			latency,
			clientIP,
			method,
			path,
		)

		// Log with different color based on status code
		switch {
		case statusCode >= 400:
			fmt.Printf("\033[31m%s\033[0m\n", logLine) // Red for errors
		case statusCode >= 300:
			fmt.Printf("\033[33m%s\033[0m\n", logLine) // Yellow for redirects
		default:
			fmt.Printf("\033[32m%s\033[0m\n", logLine) // Green for success
		}
	}
}
