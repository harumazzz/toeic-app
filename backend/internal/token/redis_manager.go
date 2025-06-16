package token

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/toeic-app/internal/cache"
	"github.com/toeic-app/internal/logger"
)

// RedisTokenManager handles distributed token management using Redis
type RedisTokenManager struct {
	cache         cache.Cache
	enabled       bool
	defaultExpiry time.Duration
}

// TokenMetadata stores information about active tokens
type TokenMetadata struct {
	UserID    int64     `json:"user_id"`
	TokenID   string    `json:"token_id"`
	IssuedAt  time.Time `json:"issued_at"`
	ExpiresAt time.Time `json:"expires_at"`
	TokenType string    `json:"token_type"` // "access" or "refresh"
	DeviceID  string    `json:"device_id"`
	UserAgent string    `json:"user_agent"`
	IPAddress string    `json:"ip_address"`
}

// SessionInfo represents an active user session
type SessionInfo struct {
	SessionID string    `json:"session_id"`
	UserID    int64     `json:"user_id"`
	DeviceID  string    `json:"device_id"`
	UserAgent string    `json:"user_agent"`
	IPAddress string    `json:"ip_address"`
	CreatedAt time.Time `json:"created_at"`
	LastSeen  time.Time `json:"last_seen"`
	IsActive  bool      `json:"is_active"`
}

// NewRedisTokenManager creates a new Redis-based token manager
func NewRedisTokenManager(cache cache.Cache, enabled bool) *RedisTokenManager {
	return &RedisTokenManager{
		cache:         cache,
		enabled:       enabled,
		defaultExpiry: 24 * time.Hour, // Default 24 hours
	}
}

// BlacklistToken adds a token to the blacklist
func (r *RedisTokenManager) BlacklistToken(ctx context.Context, tokenID string, expiresAt time.Time) error {
	if !r.enabled || r.cache == nil {
		return nil // Gracefully handle when Redis is not available
	}

	key := r.getBlacklistKey(tokenID)
	ttl := time.Until(expiresAt)
	if ttl <= 0 {
		ttl = time.Minute // Minimum TTL
	}

	logger.DebugWithFields(logger.Fields{
		"component": "token_manager",
		"operation": "blacklist",
		"token_id":  tokenID,
		"ttl":       ttl.String(),
	}, "Blacklisting token in Redis")

	return r.cache.Set(ctx, key, []byte("blacklisted"), ttl)
}

// IsTokenBlacklisted checks if a token is blacklisted
func (r *RedisTokenManager) IsTokenBlacklisted(ctx context.Context, tokenID string) (bool, error) {
	if !r.enabled || r.cache == nil {
		return false, nil // Gracefully handle when Redis is not available
	}

	key := r.getBlacklistKey(tokenID)
	exists, err := r.cache.Exists(ctx, key)
	if err != nil {
		logger.WarnWithFields(logger.Fields{
			"component": "token_manager",
			"operation": "check_blacklist",
			"token_id":  tokenID,
			"error":     err.Error(),
		}, "Error checking token blacklist")
		return false, err
	}

	return exists, nil
}

// StoreTokenMetadata stores metadata about an active token
func (r *RedisTokenManager) StoreTokenMetadata(ctx context.Context, tokenID string, metadata TokenMetadata) error {
	if !r.enabled || r.cache == nil {
		return nil
	}

	key := r.getTokenMetadataKey(tokenID)
	data, err := json.Marshal(metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal token metadata: %w", err)
	}

	ttl := time.Until(metadata.ExpiresAt)
	if ttl <= 0 {
		ttl = r.defaultExpiry
	}

	logger.DebugWithFields(logger.Fields{
		"component":  "token_manager",
		"operation":  "store_metadata",
		"token_id":   tokenID,
		"user_id":    metadata.UserID,
		"token_type": metadata.TokenType,
	}, "Storing token metadata in Redis")

	return r.cache.Set(ctx, key, data, ttl)
}

// GetTokenMetadata retrieves metadata for a token
func (r *RedisTokenManager) GetTokenMetadata(ctx context.Context, tokenID string) (*TokenMetadata, error) {
	if !r.enabled || r.cache == nil {
		return nil, nil
	}

	key := r.getTokenMetadataKey(tokenID)
	data, err := r.cache.Get(ctx, key)
	if err != nil {
		return nil, err
	}

	var metadata TokenMetadata
	if err := json.Unmarshal(data, &metadata); err != nil {
		return nil, fmt.Errorf("failed to unmarshal token metadata: %w", err)
	}

	return &metadata, nil
}

// CreateSession creates a new user session
func (r *RedisTokenManager) CreateSession(ctx context.Context, sessionID string, userID int64, deviceInfo SessionInfo) error {
	if !r.enabled || r.cache == nil {
		return nil
	}

	// Store session info
	sessionKey := r.getSessionKey(sessionID)
	sessionData, err := json.Marshal(deviceInfo)
	if err != nil {
		return fmt.Errorf("failed to marshal session info: %w", err)
	}

	if err := r.cache.Set(ctx, sessionKey, sessionData, 30*24*time.Hour); err != nil {
		return fmt.Errorf("failed to store session: %w", err)
	}

	// Add session to user's active sessions
	userSessionsKey := r.getUserSessionsKey(userID)
	if err := r.addToSet(ctx, userSessionsKey, sessionID); err != nil {
		return fmt.Errorf("failed to add session to user sessions: %w", err)
	}

	logger.InfoWithFields(logger.Fields{
		"component":  "token_manager",
		"operation":  "create_session",
		"session_id": sessionID,
		"user_id":    userID,
		"device_id":  deviceInfo.DeviceID,
	}, "Created new user session")

	return nil
}

// GetUserSessions retrieves all active sessions for a user
func (r *RedisTokenManager) GetUserSessions(ctx context.Context, userID int64) ([]SessionInfo, error) {
	if !r.enabled || r.cache == nil {
		return nil, nil
	}

	userSessionsKey := r.getUserSessionsKey(userID)
	sessionIDs, err := r.getSetMembers(ctx, userSessionsKey)
	if err != nil {
		return nil, err
	}

	var sessions []SessionInfo
	for _, sessionID := range sessionIDs {
		sessionKey := r.getSessionKey(sessionID)
		data, err := r.cache.Get(ctx, sessionKey)
		if err != nil {
			continue // Skip invalid sessions
		}

		var session SessionInfo
		if err := json.Unmarshal(data, &session); err != nil {
			continue // Skip corrupted sessions
		}

		sessions = append(sessions, session)
	}

	return sessions, nil
}

// RevokeUserSessions revokes all sessions for a user (logout from all devices)
func (r *RedisTokenManager) RevokeUserSessions(ctx context.Context, userID int64) error {
	if !r.enabled || r.cache == nil {
		return nil
	}

	userSessionsKey := r.getUserSessionsKey(userID)
	sessionIDs, err := r.getSetMembers(ctx, userSessionsKey)
	if err != nil {
		return err
	}

	// Remove all session data
	for _, sessionID := range sessionIDs {
		sessionKey := r.getSessionKey(sessionID)
		if err := r.cache.Delete(ctx, sessionKey); err != nil {
			logger.WarnWithFields(logger.Fields{
				"component":  "token_manager",
				"operation":  "revoke_session",
				"session_id": sessionID,
				"error":      err.Error(),
			}, "Failed to delete session")
		}
	}

	// Clear user's session list
	if err := r.cache.Delete(ctx, userSessionsKey); err != nil {
		logger.WarnWithFields(logger.Fields{
			"component": "token_manager",
			"operation": "revoke_sessions",
			"user_id":   userID,
			"error":     err.Error(),
		}, "Failed to clear user sessions list")
	}

	logger.InfoWithFields(logger.Fields{
		"component":     "token_manager",
		"operation":     "revoke_all_sessions",
		"user_id":       userID,
		"session_count": len(sessionIDs),
	}, "Revoked all user sessions")

	return nil
}

// RevokeSession revokes a specific session
func (r *RedisTokenManager) RevokeSession(ctx context.Context, sessionID string, userID int64) error {
	if !r.enabled || r.cache == nil {
		return nil
	}

	// Remove session data
	sessionKey := r.getSessionKey(sessionID)
	if err := r.cache.Delete(ctx, sessionKey); err != nil {
		logger.WarnWithFields(logger.Fields{
			"component":  "token_manager",
			"operation":  "revoke_session",
			"session_id": sessionID,
			"error":      err.Error(),
		}, "Failed to delete session")
	}

	// Remove from user's session list
	userSessionsKey := r.getUserSessionsKey(userID)
	if err := r.removeFromSet(ctx, userSessionsKey, sessionID); err != nil {
		logger.WarnWithFields(logger.Fields{
			"component":  "token_manager",
			"operation":  "remove_session",
			"session_id": sessionID,
			"error":      err.Error(),
		}, "Failed to remove session from user list")
	}

	logger.InfoWithFields(logger.Fields{
		"component":  "token_manager",
		"operation":  "revoke_session",
		"session_id": sessionID,
		"user_id":    userID,
	}, "Revoked user session")

	return nil
}

// UpdateSessionActivity updates the last seen time for a session
func (r *RedisTokenManager) UpdateSessionActivity(ctx context.Context, sessionID string) error {
	if !r.enabled || r.cache == nil {
		return nil
	}

	sessionKey := r.getSessionKey(sessionID)
	data, err := r.cache.Get(ctx, sessionKey)
	if err != nil {
		return err
	}

	var session SessionInfo
	if err := json.Unmarshal(data, &session); err != nil {
		return err
	}

	session.LastSeen = time.Now()
	updatedData, err := json.Marshal(session)
	if err != nil {
		return err
	}

	return r.cache.Set(ctx, sessionKey, updatedData, 30*24*time.Hour)
}

// GetActiveSessionsCount returns the number of active sessions
func (r *RedisTokenManager) GetActiveSessionsCount(ctx context.Context) (int64, error) {
	if !r.enabled || r.cache == nil {
		return 0, nil
	}

	// This is a simplified implementation
	// In a real scenario, you might want to maintain a global counter
	return 0, nil
}

// Cleanup removes expired tokens and sessions
func (r *RedisTokenManager) Cleanup(ctx context.Context) error {
	if !r.enabled || r.cache == nil {
		return nil
	}

	// Redis handles TTL automatically, but we can add custom cleanup logic here
	logger.Debug("Redis token manager cleanup completed")
	return nil
}

// Key generation helpers
func (r *RedisTokenManager) getBlacklistKey(tokenID string) string {
	return fmt.Sprintf("token:blacklist:%s", tokenID)
}

func (r *RedisTokenManager) getTokenMetadataKey(tokenID string) string {
	return fmt.Sprintf("token:metadata:%s", tokenID)
}

func (r *RedisTokenManager) getSessionKey(sessionID string) string {
	return fmt.Sprintf("session:%s", sessionID)
}

func (r *RedisTokenManager) getUserSessionsKey(userID int64) string {
	return fmt.Sprintf("user:sessions:%d", userID)
}

// Set operations helpers (simplified - in production you'd use Redis sets)
func (r *RedisTokenManager) addToSet(ctx context.Context, key, value string) error {
	// Simplified implementation using JSON array
	// In production, use Redis sets for better performance
	existing, err := r.cache.Get(ctx, key)
	if err != nil {
		// Create new set
		data, _ := json.Marshal([]string{value})
		return r.cache.Set(ctx, key, data, 30*24*time.Hour)
	}

	var members []string
	if err := json.Unmarshal(existing, &members); err != nil {
		members = []string{}
	}

	// Add if not exists
	for _, member := range members {
		if member == value {
			return nil // Already exists
		}
	}

	members = append(members, value)
	data, _ := json.Marshal(members)
	return r.cache.Set(ctx, key, data, 30*24*time.Hour)
}

func (r *RedisTokenManager) removeFromSet(ctx context.Context, key, value string) error {
	existing, err := r.cache.Get(ctx, key)
	if err != nil {
		return nil // Set doesn't exist
	}

	var members []string
	if err := json.Unmarshal(existing, &members); err != nil {
		return nil
	}

	// Remove value
	var newMembers []string
	for _, member := range members {
		if member != value {
			newMembers = append(newMembers, member)
		}
	}

	if len(newMembers) == 0 {
		return r.cache.Delete(ctx, key)
	}

	data, _ := json.Marshal(newMembers)
	return r.cache.Set(ctx, key, data, 30*24*time.Hour)
}

func (r *RedisTokenManager) getSetMembers(ctx context.Context, key string) ([]string, error) {
	data, err := r.cache.Get(ctx, key)
	if err != nil {
		return nil, err
	}

	var members []string
	if err := json.Unmarshal(data, &members); err != nil {
		return nil, err
	}

	return members, nil
}
