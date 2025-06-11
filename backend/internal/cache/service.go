package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"reflect"
	"time"

	"github.com/toeic-app/internal/logger"
)

// ServiceCache provides high-level caching for service layer
type ServiceCache struct {
	cache Cache
}

// NewServiceCache creates a new service cache
func NewServiceCache(cache Cache) *ServiceCache {
	return &ServiceCache{
		cache: cache,
	}
}

// GetOrSet retrieves data from cache or executes function and caches result
func (s *ServiceCache) GetOrSet(ctx context.Context, key string, ttl time.Duration, fetchFunc func() (interface{}, error), result interface{}) error {
	// Try to get from cache first
	if data, err := s.cache.Get(ctx, key); err == nil {
		if err := json.Unmarshal(data, result); err == nil {
			logger.Debug("Cache HIT for key: %s", key)
			return nil
		}
		logger.Warn("Failed to unmarshal cached data for key %s: %v", key, err)
	}

	logger.Debug("Cache MISS for key: %s", key)

	// Cache miss, fetch data
	data, err := fetchFunc()
	if err != nil {
		return err
	}

	// Cache the result
	if jsonData, err := json.Marshal(data); err == nil {
		go func() {
			if err := s.cache.Set(context.Background(), key, jsonData, ttl); err != nil {
				logger.Warn("Failed to cache data for key %s: %v", key, err)
			}
		}()
	}

	// Set result using reflection
	if err := s.setResult(data, result); err != nil {
		return err
	}

	return nil
}

// Get retrieves and unmarshals data from cache
func (s *ServiceCache) Get(ctx context.Context, key string, result interface{}) error {
	data, err := s.cache.Get(ctx, key)
	if err != nil {
		return err
	}

	return json.Unmarshal(data, result)
}

// Set marshals and stores data in cache
func (s *ServiceCache) Set(ctx context.Context, key string, data interface{}, ttl time.Duration) error {
	jsonData, err := json.Marshal(data)
	if err != nil {
		return err
	}

	return s.cache.Set(ctx, key, jsonData, ttl)
}

// Delete removes a key from cache
func (s *ServiceCache) Delete(ctx context.Context, key string) error {
	return s.cache.Delete(ctx, key)
}

// DeletePattern removes keys matching a pattern (simplified implementation)
func (s *ServiceCache) DeletePattern(ctx context.Context, pattern string) error {
	// This is a simplified implementation
	// In production with Redis, you'd use SCAN to find matching keys
	return s.cache.Clear(ctx)
}

// GenerateKey creates a cache key from components
func (s *ServiceCache) GenerateKey(prefix string, components ...interface{}) string {
	keyParts := []string{prefix}

	for _, component := range components {
		keyParts = append(keyParts, fmt.Sprintf("%v", component))
	}

	return fmt.Sprintf("%s", keyParts[0]) + ":" + fmt.Sprintf("%v", keyParts[1:])
}

// setResult sets the result using reflection
func (s *ServiceCache) setResult(data interface{}, result interface{}) error {
	resultValue := reflect.ValueOf(result)
	if resultValue.Kind() != reflect.Ptr {
		return fmt.Errorf("result must be a pointer")
	}

	dataValue := reflect.ValueOf(data)
	resultElem := resultValue.Elem()

	if !dataValue.Type().AssignableTo(resultElem.Type()) {
		// Try JSON marshal/unmarshal as fallback
		jsonData, err := json.Marshal(data)
		if err != nil {
			return err
		}
		return json.Unmarshal(jsonData, result)
	}

	resultElem.Set(dataValue)
	return nil
}

// Common cache key patterns
const (
	KeyUserProfile       = "user:profile:%d"
	KeyUserWords         = "user:words:%d"
	KeyWordDefinition    = "word:definition:%d"
	KeyExamQuestions     = "exam:questions:%d"
	KeyGrammarRules      = "grammar:rules:%d"
	KeyUserProgress      = "user:progress:%d:%s"
	KeyLeaderboard       = "leaderboard:%s"
	KeyStatistics        = "stats:%s:%s"
	KeyContentList       = "content:list:%s:%d:%d"
	KeySearchResults     = "search:%s:%s"
	KeyVocabularyByLevel = "vocab:level:%s"
)

// CacheKeyBuilder helps build consistent cache keys
type CacheKeyBuilder struct {
	prefix string
}

// NewCacheKeyBuilder creates a new cache key builder
func NewCacheKeyBuilder(prefix string) *CacheKeyBuilder {
	return &CacheKeyBuilder{prefix: prefix}
}

// User returns user-related cache keys
func (c *CacheKeyBuilder) User(userID int64) *UserCacheKeys {
	return &UserCacheKeys{
		builder: c,
		userID:  userID,
	}
}

// Content returns content-related cache keys
func (c *CacheKeyBuilder) Content() *ContentCacheKeys {
	return &ContentCacheKeys{builder: c}
}

// UserCacheKeys provides user-specific cache key methods
type UserCacheKeys struct {
	builder *CacheKeyBuilder
	userID  int64
}

// Profile returns user profile cache key
func (u *UserCacheKeys) Profile() string {
	return fmt.Sprintf("%s:user:profile:%d", u.builder.prefix, u.userID)
}

// Words returns user words cache key
func (u *UserCacheKeys) Words() string {
	return fmt.Sprintf("%s:user:words:%d", u.builder.prefix, u.userID)
}

// Progress returns user progress cache key
func (u *UserCacheKeys) Progress(contentType string) string {
	return fmt.Sprintf("%s:user:progress:%d:%s", u.builder.prefix, u.userID, contentType)
}

// Statistics returns user statistics cache key
func (u *UserCacheKeys) Statistics(period string) string {
	return fmt.Sprintf("%s:user:stats:%d:%s", u.builder.prefix, u.userID, period)
}

// ContentCacheKeys provides content-related cache key methods
type ContentCacheKeys struct {
	builder *CacheKeyBuilder
}

// List returns content list cache key
func (c *ContentCacheKeys) List(contentType string, page, limit int) string {
	return fmt.Sprintf("%s:content:list:%s:%d:%d", c.builder.prefix, contentType, page, limit)
}

// Search returns search results cache key
func (c *ContentCacheKeys) Search(query, contentType string) string {
	return fmt.Sprintf("%s:search:%s:%s", c.builder.prefix, query, contentType)
}

// VocabularyByLevel returns vocabulary by level cache key
func (c *ContentCacheKeys) VocabularyByLevel(level string) string {
	return fmt.Sprintf("%s:vocab:level:%s", c.builder.prefix, level)
}

// Leaderboard returns leaderboard cache key
func (c *ContentCacheKeys) Leaderboard(leaderboardType string) string {
	return fmt.Sprintf("%s:leaderboard:%s", c.builder.prefix, leaderboardType)
}
