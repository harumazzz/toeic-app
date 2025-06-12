package token

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/toeic-app/internal/logger"
)

// RedisTokenBlacklist implements token blacklist using Redis
type RedisTokenBlacklist struct {
	client    *redis.Client
	keyPrefix string
}

// NewRedisTokenBlacklist creates a new Redis-based token blacklist
func NewRedisTokenBlacklist(client *redis.Client, keyPrefix string) *RedisTokenBlacklist {
	return &RedisTokenBlacklist{
		client:    client,
		keyPrefix: keyPrefix,
	}
}

// Add adds a token to the blacklist with expiration
func (rtb *RedisTokenBlacklist) Add(token string, expiry time.Time) {
	ctx := context.Background()
	key := rtb.keyPrefix + "blacklist:" + token

	// Set the token with TTL until expiry
	ttl := time.Until(expiry)
	if ttl > 0 {
		err := rtb.client.Set(ctx, key, "1", ttl).Err()
		if err != nil {
			logger.Error("Failed to blacklist token in Redis: %v", err)
		} else {
			logger.Debug("Token blacklisted in Redis with TTL: %v", ttl)
		}
	}
}

// IsBlacklisted checks if a token is blacklisted
func (rtb *RedisTokenBlacklist) IsBlacklisted(token string) bool {
	ctx := context.Background()
	key := rtb.keyPrefix + "blacklist:" + token

	exists, err := rtb.client.Exists(ctx, key).Result()
	if err != nil {
		logger.Error("Failed to check token blacklist in Redis: %v", err)
		return false
	}

	return exists > 0
}

// Count returns the number of blacklisted tokens
func (rtb *RedisTokenBlacklist) Count() int {
	ctx := context.Background()
	pattern := rtb.keyPrefix + "blacklist:*"

	keys, err := rtb.client.Keys(ctx, pattern).Result()
	if err != nil {
		logger.Error("Failed to count blacklisted tokens in Redis: %v", err)
		return 0
	}

	return len(keys)
}

// Stop is a no-op for Redis implementation (Redis handles cleanup automatically)
func (rtb *RedisTokenBlacklist) Stop() {
	// Redis automatically handles TTL expiration, no cleanup needed
	logger.Info("Redis token blacklist stopped")
}

// RefreshTokenManager manages refresh tokens in Redis
type RefreshTokenManager struct {
	client    *redis.Client
	keyPrefix string
}

// NewRefreshTokenManager creates a new refresh token manager
func NewRefreshTokenManager(client *redis.Client, keyPrefix string) *RefreshTokenManager {
	return &RefreshTokenManager{
		client:    client,
		keyPrefix: keyPrefix,
	}
}

// StoreRefreshToken stores a refresh token with user association
func (rtm *RefreshTokenManager) StoreRefreshToken(userID int32, tokenID string, expiry time.Time) error {
	ctx := context.Background()

	// Store token with user association
	userKey := rtm.keyPrefix + "refresh_tokens:user:" + strconv.Itoa(int(userID))
	tokenKey := rtm.keyPrefix + "refresh_tokens:token:" + tokenID

	ttl := time.Until(expiry)
	if ttl <= 0 {
		return fmt.Errorf("token already expired")
	}

	pipe := rtm.client.Pipeline()

	// Store user -> tokens mapping
	pipe.SAdd(ctx, userKey, tokenID)
	pipe.Expire(ctx, userKey, ttl)

	// Store token metadata
	pipe.HMSet(ctx, tokenKey, map[string]interface{}{
		"user_id":    userID,
		"created_at": time.Now().Unix(),
		"expires_at": expiry.Unix(),
	})
	pipe.Expire(ctx, tokenKey, ttl)

	_, err := pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("failed to store refresh token: %w", err)
	}

	logger.Debug("Refresh token stored in Redis for user %d", userID)
	return nil
}

// ValidateRefreshToken validates a refresh token
func (rtm *RefreshTokenManager) ValidateRefreshToken(tokenID string) (int32, error) {
	ctx := context.Background()
	tokenKey := rtm.keyPrefix + "refresh_tokens:token:" + tokenID

	// Check if token exists and get user ID
	result, err := rtm.client.HGet(ctx, tokenKey, "user_id").Result()
	if err == redis.Nil {
		return 0, fmt.Errorf("refresh token not found")
	}
	if err != nil {
		return 0, fmt.Errorf("failed to validate refresh token: %w", err)
	}

	userID, err := strconv.Atoi(result)
	if err != nil {
		return 0, fmt.Errorf("invalid user ID in token: %w", err)
	}

	return int32(userID), nil
}

// RevokeRefreshToken removes a refresh token
func (rtm *RefreshTokenManager) RevokeRefreshToken(userID int32, tokenID string) error {
	ctx := context.Background()

	userKey := rtm.keyPrefix + "refresh_tokens:user:" + strconv.Itoa(int(userID))
	tokenKey := rtm.keyPrefix + "refresh_tokens:token:" + tokenID

	pipe := rtm.client.Pipeline()
	pipe.SRem(ctx, userKey, tokenID)
	pipe.Del(ctx, tokenKey)

	_, err := pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("failed to revoke refresh token: %w", err)
	}

	logger.Debug("Refresh token revoked for user %d", userID)
	return nil
}

// RevokeAllUserTokens revokes all refresh tokens for a user
func (rtm *RefreshTokenManager) RevokeAllUserTokens(userID int32) error {
	ctx := context.Background()
	userKey := rtm.keyPrefix + "refresh_tokens:user:" + strconv.Itoa(int(userID))

	// Get all tokens for user
	tokens, err := rtm.client.SMembers(ctx, userKey).Result()
	if err != nil {
		return fmt.Errorf("failed to get user tokens: %w", err)
	}

	if len(tokens) == 0 {
		return nil
	}

	pipe := rtm.client.Pipeline()

	// Delete all token keys
	for _, tokenID := range tokens {
		tokenKey := rtm.keyPrefix + "refresh_tokens:token:" + tokenID
		pipe.Del(ctx, tokenKey)
	}

	// Delete user key
	pipe.Del(ctx, userKey)

	_, err = pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("failed to revoke all user tokens: %w", err)
	}

	logger.Info("Revoked %d refresh tokens for user %d", len(tokens), userID)
	return nil
}
