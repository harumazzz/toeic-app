package middleware

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
)

// DynamicRateLimiter applies different rate limits based on authentication status
func DynamicRateLimiter(cfg config.Config) gin.HandlerFunc {
	// Create rate limiters with different configurations
	standardLimiter := NewRateLimiter(RateLimitConfig{
		Rate:      cfg.RateLimitRequests,
		Burst:     cfg.RateLimitBurst,
		ExpiresIn: cfg.RateLimitExpiresIn,
	})

	authLimiter := NewRateLimiter(RateLimitConfig{
		Rate:      cfg.AuthRateLimitRequests,
		Burst:     cfg.AuthRateLimitBurst,
		ExpiresIn: cfg.RateLimitExpiresIn,
	})

	return func(c *gin.Context) {
		// Skip rate limiting if disabled
		if !cfg.RateLimitEnabled {
			c.Next()
			return
		}

		// Check if the current path should use auth rate limiting
		path := c.Request.URL.Path

		// Apply stricter rate limiting for authentication endpoints
		if isAuthEndpoint(path) && cfg.AuthRateLimitEnabled {
			logger.Debug("Applying auth rate limit to %s", path)
			authLimiter.Middleware()(c)
			return
		}

		// Apply standard rate limiting for all other endpoints
		standardLimiter.Middleware()(c)
	}
}

// isAuthEndpoint checks if a path is an authentication-related endpoint
func isAuthEndpoint(path string) bool {
	authPaths := []string{
		"/api/login",
		"/api/register",
		"/api/refresh-token",
	}

	for _, authPath := range authPaths {
		if strings.HasPrefix(path, authPath) {
			return true
		}
	}

	return false
}
