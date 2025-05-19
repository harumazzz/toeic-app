package token

import (
	"sync"
	"time"
)

// TokenBlacklist maintains a list of revoked tokens
type TokenBlacklist struct {
	blacklistedTokens map[string]time.Time // Maps token IDs to expiration time
	mu                sync.RWMutex
	cleanupInterval   time.Duration
	stopCleanup       chan struct{}
}

// NewTokenBlacklist creates a new token blacklist
func NewTokenBlacklist(cleanupInterval time.Duration) *TokenBlacklist {
	blacklist := &TokenBlacklist{
		blacklistedTokens: make(map[string]time.Time),
		cleanupInterval:   cleanupInterval,
		stopCleanup:       make(chan struct{}),
	}

	// Start cleanup routine
	go blacklist.cleanup()

	return blacklist
}

// Add adds a token to the blacklist
func (tb *TokenBlacklist) Add(token string, expiry time.Time) {
	tb.mu.Lock()
	defer tb.mu.Unlock()
	tb.blacklistedTokens[token] = expiry
}

// IsBlacklisted checks if a token is blacklisted
func (tb *TokenBlacklist) IsBlacklisted(token string) bool {
	tb.mu.RLock()
	defer tb.mu.RUnlock()
	_, found := tb.blacklistedTokens[token]
	return found
}

// cleanup periodically removes expired tokens from the blacklist
func (tb *TokenBlacklist) cleanup() {
	ticker := time.NewTicker(tb.cleanupInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			tb.removeExpiredTokens()
		case <-tb.stopCleanup:
			return
		}
	}
}

// removeExpiredTokens removes tokens that have expired from the blacklist
func (tb *TokenBlacklist) removeExpiredTokens() {
	now := time.Now()

	tb.mu.Lock()
	defer tb.mu.Unlock()

	for token, expiry := range tb.blacklistedTokens {
		if now.After(expiry) {
			delete(tb.blacklistedTokens, token)
		}
	}
}

// Stop stops the cleanup goroutine
func (tb *TokenBlacklist) Stop() {
	tb.stopCleanup <- struct{}{}
}
