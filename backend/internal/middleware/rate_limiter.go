package middleware

import (
	"net"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
	"golang.org/x/time/rate"
)

// RateLimitConfig stores the configuration for rate limiting
type RateLimitConfig struct {
	// Rate defines the maximum number of requests per second
	Rate int

	// Burst defines the maximum burst size
	Burst int

	// ExpiresIn defines how long to keep a client's rate limiter in the store
	ExpiresIn time.Duration

	// TrustedProxies is a list of trusted proxy IPs for X-Forwarded-For header
	TrustedProxies []string
}

// visitor represents a client with rate limiting information
type visitor struct {
	limiter  *rate.Limiter
	lastSeen time.Time
}

// RateLimiter implements a simple rate limiter middleware for Gin
type RateLimiter struct {
	visitors    map[string]*visitor
	mu          sync.RWMutex
	config      RateLimitConfig
	cleanup     *time.Ticker
	stopCleanup chan struct{}
}

// NewRateLimiter creates a new rate limiter with the given configuration
func NewRateLimiter(config RateLimitConfig) *RateLimiter {
	limiter := &RateLimiter{
		visitors:    make(map[string]*visitor),
		config:      config,
		cleanup:     time.NewTicker(time.Minute),
		stopCleanup: make(chan struct{}),
	}

	// Start cleanup goroutine
	go limiter.cleanupVisitors()

	return limiter
}

// Stop terminates the cleanup goroutine
func (rl *RateLimiter) Stop() {
	rl.cleanup.Stop()
	rl.stopCleanup <- struct{}{}
}

// cleanupVisitors periodically removes old entries from the visitors map
func (rl *RateLimiter) cleanupVisitors() {
	for {
		select {
		case <-rl.cleanup.C:
			rl.mu.Lock()
			for ip, v := range rl.visitors {
				if time.Since(v.lastSeen) > rl.config.ExpiresIn {
					delete(rl.visitors, ip)
					logger.Debug("Rate limiter: removed %s due to inactivity", ip)
				}
			}
			rl.mu.Unlock()
		case <-rl.stopCleanup:
			logger.Debug("Rate limiter: cleanup stopped")
			return
		}
	}
}

// getVisitor returns the visitor for the given IP, creating it if it doesn't exist
func (rl *RateLimiter) getVisitor(ip string) *rate.Limiter {
	rl.mu.RLock()
	v, exists := rl.visitors[ip]
	rl.mu.RUnlock()

	if !exists {
		// Create a new rate limiter for this visitor
		limiter := rate.NewLimiter(rate.Limit(rl.config.Rate), rl.config.Burst)

		// Store it in the map
		rl.mu.Lock()
		rl.visitors[ip] = &visitor{
			limiter:  limiter,
			lastSeen: time.Now(),
		}
		rl.mu.Unlock()

		return limiter
	}

	// Update last seen
	rl.mu.Lock()
	v.lastSeen = time.Now()
	rl.mu.Unlock()

	return v.limiter
}

// getClientIP extracts the real client IP address
func (rl *RateLimiter) getClientIP(c *gin.Context) string {
	// First try to get IP from X-Forwarded-For header
	clientIP := c.Request.Header.Get("X-Forwarded-For")

	// If X-Forwarded-For exists and we're behind a trusted proxy
	if clientIP != "" {
		// Extract the first IP which should be the client's real IP
		if ip, _, err := net.SplitHostPort(clientIP); err == nil {
			return ip
		}
		return clientIP
	}

	// Use the built-in ClientIP method as fallback
	return c.ClientIP()
}

// Middleware returns a Gin middleware that implements rate limiting
func (rl *RateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get client IP
		clientIP := rl.getClientIP(c)

		// Get the rate limiter for this IP
		limiter := rl.getVisitor(clientIP)

		// Check if this request is allowed
		if !limiter.Allow() {
			logger.Warn("Rate limit exceeded for IP: %s on path: %s", clientIP, c.Request.URL.Path)
			c.JSON(http.StatusTooManyRequests, gin.H{
				"status":  "error",
				"message": "Rate limit exceeded. Please try again later.",
			})
			c.Abort()
			return
		}

		// Continue processing the request
		c.Next()
	}
}

// APIRateLimiter creates middleware that applies rate limiting to API endpoints
func APIRateLimiter(config RateLimitConfig) gin.HandlerFunc {
	limiter := NewRateLimiter(config)
	return limiter.Middleware()
}
