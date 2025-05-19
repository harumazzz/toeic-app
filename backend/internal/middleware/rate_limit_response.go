package middleware

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
)

// RateLimitResponse represents the standard response for rate limit errors
type RateLimitResponse struct {
	Status    string         `json:"status"`
	Message   string         `json:"message"`
	Error     string         `json:"error,omitempty"`
	RateLimit *RateLimitInfo `json:"rate_limit,omitempty"`
}

// RateLimitInfo contains information about the rate limits
type RateLimitInfo struct {
	Limit          int   `json:"limit"`
	Remaining      int   `json:"remaining"`
	ResetTimestamp int64 `json:"reset_timestamp"`
	RetryAfter     int   `json:"retry_after_seconds"`
}

// SendRateLimitExceededResponse sends a standardized rate limit exceeded response
func SendRateLimitExceededResponse(c *gin.Context, quota int, remaining int, resetTime time.Time, shortTerm bool) {
	// Get the client IP for logging
	clientIP := c.ClientIP()
	path := c.Request.URL.Path
	method := c.Request.Method

	now := time.Now()
	retryAfter := int(resetTime.Sub(now).Seconds())
	if retryAfter < 1 {
		retryAfter = 1 // Minimum retry of 1 second
	}

	// Set rate limit headers
	c.Header("X-RateLimit-Limit", strconv.Itoa(quota))
	c.Header("X-RateLimit-Remaining", strconv.Itoa(remaining))
	c.Header("X-RateLimit-Reset", strconv.FormatInt(resetTime.Unix(), 10))
	c.Header("Retry-After", strconv.Itoa(retryAfter))

	var errorType string
	var errorMessage string

	if shortTerm {
		errorType = "Rate limit exceeded"
		errorMessage = "Too many requests in a short period of time. Please slow down."
	} else {
		errorType = "Quota limit exceeded"
		errorMessage = "You've reached your quota limit for this time window."
	}

	response := RateLimitResponse{
		Status:  "error",
		Message: errorType,
		Error:   errorMessage,
		RateLimit: &RateLimitInfo{
			Limit:          quota,
			Remaining:      remaining,
			ResetTimestamp: resetTime.Unix(),
			RetryAfter:     retryAfter,
		},
	}

	logger.Warn("Rate limit exceeded: %s %s - IP: %s - Reset in %d seconds",
		method, path, clientIP, retryAfter)

	c.JSON(http.StatusTooManyRequests, response)
	c.Abort()
}
