package middleware

import (
	"strconv"
	"sync"
	"time"

	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/token"
	"golang.org/x/time/rate"
)

// Constants for authenticated and unauthenticated users
const (
	userTypeAnonymous = "anonymous"
	userTypeAuth      = "authenticated"
)

// ThrottleConfig stores the configuration for throttling
type ThrottleConfig struct {
	// Rate defines requests per second
	Rate float64

	// Burst defines maximum burst size
	Burst int

	// QuotaPeriod defines the time window for quota
	QuotaPeriod time.Duration

	// MaxQuota defines maximum requests in quota period
	MaxQuota int
}

// userLimiter represents rate limiters for a specific user
type userLimiter struct {
	rateLimiter    *rate.Limiter // short-term rate limiter
	quotaLimiter   *rate.Limiter // long-term quota limiter
	lastSeen       time.Time
	requestCount   int
	quotaResetTime time.Time
}

// AdvancedRateLimit implements sophisticated rate limiting with different
// strategies for authenticated and unauthenticated users
type AdvancedRateLimit struct {
	ipLimiters      map[string]*userLimiter // IP-based limiters for anonymous users
	authLimiters    map[int64]*userLimiter  // User ID based limiters for authenticated
	anonConfig      ThrottleConfig          // Config for anonymous users
	authConfig      ThrottleConfig          // Config for authenticated users
	mu              sync.RWMutex
	cleanupInterval time.Duration
	expirationTime  time.Duration
	tokenMaker      token.Maker
	cleanupTicker   *time.Ticker
	stopCleanup     chan struct{}
}

// NewAdvancedRateLimit creates a new advanced rate limiter
func NewAdvancedRateLimit(cfg config.Config, tokenMaker token.Maker) *AdvancedRateLimit {
	// Configure rate limiters for anonymous users (IP-based)
	anonConfig := ThrottleConfig{
		Rate:        float64(cfg.RateLimitRequests),
		Burst:       cfg.RateLimitBurst,
		QuotaPeriod: 1 * time.Hour,
		MaxQuota:    600, // 600 requests per hour for anonymous users
	}

	// Configure rate limiters for authenticated users (API key or token-based)
	authConfig := ThrottleConfig{
		Rate:        float64(cfg.RateLimitRequests) * 2, // Authenticated users get 2x the rate
		Burst:       cfg.RateLimitBurst * 2,             // And 2x the burst
		QuotaPeriod: 1 * time.Hour,
		MaxQuota:    1200, // 1200 requests per hour for authenticated users
	}

	// Use a shorter cleanup interval in production
	cleanupInterval := 5 * time.Minute
	expirationTime := 1 * time.Hour

	arl := &AdvancedRateLimit{
		ipLimiters:      make(map[string]*userLimiter),
		authLimiters:    make(map[int64]*userLimiter),
		anonConfig:      anonConfig,
		authConfig:      authConfig,
		cleanupInterval: cleanupInterval,
		expirationTime:  expirationTime,
		tokenMaker:      tokenMaker,
		cleanupTicker:   time.NewTicker(cleanupInterval),
		stopCleanup:     make(chan struct{}),
	}

	// Start cleanup goroutine
	go arl.cleanup()

	return arl
}

// Stop terminates the cleanup goroutine
func (arl *AdvancedRateLimit) Stop() {
	arl.cleanupTicker.Stop()
	arl.stopCleanup <- struct{}{}
}

// cleanup periodically removes old entries from the limiters maps
func (arl *AdvancedRateLimit) cleanup() {
	for {
		select {
		case <-arl.cleanupTicker.C:
			now := time.Now()

			// Clean up IP-based limiters
			arl.mu.Lock()
			for ip, limiter := range arl.ipLimiters {
				if now.Sub(limiter.lastSeen) > arl.expirationTime {
					delete(arl.ipLimiters, ip)
					logger.Debug("Removed IP limiter for %s due to inactivity", ip)
				}
			}

			// Clean up auth limiters
			for userID, limiter := range arl.authLimiters {
				if now.Sub(limiter.lastSeen) > arl.expirationTime {
					delete(arl.authLimiters, userID)
					logger.Debug("Removed auth limiter for user %d due to inactivity", userID)
				}
			}
			arl.mu.Unlock()

		case <-arl.stopCleanup:
			logger.Debug("Advanced rate limiter cleanup stopped")
			return
		}
	}
}

// getOrCreateLimiter gets or creates limiters for a specific key and type
func (arl *AdvancedRateLimit) getOrCreateLimiter(_ string, userType string) *userLimiter {
	var config ThrottleConfig
	if userType == userTypeAuth {
		config = arl.authConfig
	} else {
		config = arl.anonConfig
	}

	// Create new limiter
	rateLim := rate.NewLimiter(rate.Limit(config.Rate), config.Burst)

	// Initialize with a fresh quota
	quotaRate := rate.Limit(float64(config.MaxQuota) / config.QuotaPeriod.Seconds())
	quotaLim := rate.NewLimiter(quotaRate, config.MaxQuota)

	now := time.Now()
	return &userLimiter{
		rateLimiter:    rateLim,
		quotaLimiter:   quotaLim,
		lastSeen:       now,
		requestCount:   0,
		quotaResetTime: now.Add(config.QuotaPeriod),
	}
}

// Middleware returns a Gin middleware that implements advanced rate limiting
func (arl *AdvancedRateLimit) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Try to get user ID from the authorization payload
		var userID int64 = 0
		var isAuthenticated bool

		// Extract auth payload if present
		if payload, exists := c.Get("authorization_payload"); exists {
			if auth, ok := payload.(*token.Payload); ok {
				// Convert from int32 to int64 to match our type
				userID = int64(auth.ID)
				isAuthenticated = true
			}
		}

		var limiter *userLimiter
		var exists bool
		now := time.Now()

		if isAuthenticated && userID > 0 {
			// Handle authenticated user
			arl.mu.RLock()
			limiter, exists = arl.authLimiters[userID]
			arl.mu.RUnlock()

			if !exists {
				limiter = arl.getOrCreateLimiter(fmt.Sprint(userID), userTypeAuth)
				arl.mu.Lock()
				arl.authLimiters[userID] = limiter
				arl.mu.Unlock()
			} else {
				// Reset quota if period expired
				if now.After(limiter.quotaResetTime) {
					quotaRate := rate.Limit(float64(arl.authConfig.MaxQuota) / arl.authConfig.QuotaPeriod.Seconds())
					limiter.quotaLimiter = rate.NewLimiter(quotaRate, arl.authConfig.MaxQuota)
					limiter.quotaResetTime = now.Add(arl.authConfig.QuotaPeriod)
					limiter.requestCount = 0
				}
			}
		} else {
			// Handle unauthenticated user by IP
			clientIP := c.ClientIP()

			arl.mu.RLock()
			limiter, exists := arl.ipLimiters[clientIP]
			arl.mu.RUnlock()

			if !exists {
				limiter = arl.getOrCreateLimiter(clientIP, userTypeAnonymous)
				arl.mu.Lock()
				arl.ipLimiters[clientIP] = limiter
				arl.mu.Unlock()
			}
			if limiter != nil {
				// Reset quota if period expired
				if now.After(limiter.quotaResetTime) {
					quotaRate := rate.Limit(float64(arl.anonConfig.MaxQuota) / arl.anonConfig.QuotaPeriod.Seconds())
					limiter.quotaLimiter = rate.NewLimiter(quotaRate, arl.anonConfig.MaxQuota)
					limiter.quotaResetTime = now.Add(arl.anonConfig.QuotaPeriod)
					limiter.requestCount = 0
				}
			}
		}

		// Verify limiter is not nil before proceeding
		if limiter == nil {
			// This shouldn't happen with our current code logic, but handle it gracefully
			logger.Error("Rate limiter unexpectedly nil - creating a default limiter")
			// Create a default limiter for this case to avoid nil dereference
			limiter = arl.getOrCreateLimiter("default", userTypeAnonymous)
		}

		// Now update last seen with nil check in place
		arl.mu.Lock()
		limiter.lastSeen = now
		limiter.requestCount++
		arl.mu.Unlock()

		// Get the quota limit based on user type
		var quota int
		if isAuthenticated {
			quota = arl.authConfig.MaxQuota
		} else {
			quota = arl.anonConfig.MaxQuota
		}

		// Check short-term rate limit
		if !limiter.rateLimiter.Allow() {
			// Short-term rate limit exceeded - use standardized response
			SendRateLimitExceededResponse(
				c,
				quota,
				quota-limiter.requestCount,
				limiter.quotaResetTime,
				true, // short term limit
			)
			return
		}

		// Check long-term quota
		if !limiter.quotaLimiter.Allow() {
			// Long-term quota exceeded - use standardized response
			SendRateLimitExceededResponse(
				c,
				quota,
				quota-limiter.requestCount,
				limiter.quotaResetTime,
				false, // long term limit
			)
			return
		}

		// Add standardized rate limit headers
		c.Header("X-RateLimit-Limit", strconv.Itoa(quota))
		c.Header("X-RateLimit-Remaining", strconv.Itoa(quota-limiter.requestCount))
		c.Header("X-RateLimit-Reset", strconv.FormatInt(limiter.quotaResetTime.Unix(), 10))

		// Continue processing the request
		c.Next()
	}
}
