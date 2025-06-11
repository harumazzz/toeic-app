package cache

import (
	"context"
	"time"
)

// Cache represents a generic cache interface
type Cache interface {
	// Get retrieves a value from cache
	Get(ctx context.Context, key string) ([]byte, error)

	// Set stores a value in cache with expiration
	Set(ctx context.Context, key string, value []byte, expiration time.Duration) error

	// Delete removes a key from cache
	Delete(ctx context.Context, key string) error

	// Exists checks if a key exists in cache
	Exists(ctx context.Context, key string) (bool, error)

	// Clear removes all keys from cache
	Clear(ctx context.Context) error

	// GetTTL returns the time-to-live for a key
	GetTTL(ctx context.Context, key string) (time.Duration, error)

	// SetNX sets a key only if it doesn't exist (atomic operation)
	SetNX(ctx context.Context, key string, value []byte, expiration time.Duration) (bool, error)

	// Increment atomically increments a counter
	Increment(ctx context.Context, key string, delta int64) (int64, error)

	// Close closes the cache connection
	Close() error
}

// CacheConfig holds cache configuration
type CacheConfig struct {
	// Cache type: "memory" or "redis"
	Type string

	// Memory cache settings
	MaxEntries      int
	DefaultTTL      time.Duration
	CleanupInterval time.Duration

	// Redis settings
	RedisAddr     string
	RedisPassword string
	RedisDB       int
	RedisPoolSize int

	// General settings
	KeyPrefix string
}

// CacheType constants
const (
	TypeMemory = "memory"
	TypeRedis  = "redis"
)

// DefaultConfig returns default cache configuration
func DefaultConfig() CacheConfig {
	return CacheConfig{
		Type:            TypeMemory,
		MaxEntries:      10000,
		DefaultTTL:      30 * time.Minute,
		CleanupInterval: 10 * time.Minute,
		RedisAddr:       "localhost:6379",
		RedisPassword:   "",
		RedisDB:         0,
		RedisPoolSize:   10,
		KeyPrefix:       "toeic:",
	}
}

// NewCache creates a new cache instance based on config
func NewCache(config CacheConfig) (Cache, error) {
	switch config.Type {
	case TypeMemory:
		return NewMemoryCache(config), nil
	case TypeRedis:
		return NewRedisCache(config)
	default:
		return NewMemoryCache(config), nil
	}
}
