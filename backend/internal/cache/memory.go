package cache

import (
	"context"
	"errors"
	"sync"
	"time"
)

// MemoryCache implements Cache interface using in-memory storage
type MemoryCache struct {
	mu      sync.RWMutex
	data    map[string]*cacheEntry
	config  CacheConfig
	cleanup *time.Ticker
	done    chan struct{}
}

type cacheEntry struct {
	value     []byte
	expiresAt time.Time
}

// NewMemoryCache creates a new in-memory cache
func NewMemoryCache(config CacheConfig) *MemoryCache {
	cache := &MemoryCache{
		data:   make(map[string]*cacheEntry),
		config: config,
		done:   make(chan struct{}),
	}

	// Start cleanup goroutine
	if config.CleanupInterval > 0 {
		cache.cleanup = time.NewTicker(config.CleanupInterval)
		go cache.startCleanup()
	}

	return cache
}

// Get retrieves a value from cache
func (c *MemoryCache) Get(ctx context.Context, key string) ([]byte, error) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	entry, exists := c.data[c.keyWithPrefix(key)]
	if !exists {
		return nil, ErrKeyNotFound
	}

	// Check if expired
	if time.Now().After(entry.expiresAt) {
		// Remove expired entry
		go func() {
			c.mu.Lock()
			delete(c.data, c.keyWithPrefix(key))
			c.mu.Unlock()
		}()
		return nil, ErrKeyNotFound
	}

	return entry.value, nil
}

// Set stores a value in cache with expiration
func (c *MemoryCache) Set(ctx context.Context, key string, value []byte, expiration time.Duration) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if expiration <= 0 {
		expiration = c.config.DefaultTTL
	}

	// Check if we need to evict entries
	if len(c.data) >= c.config.MaxEntries {
		c.evictOldest()
	}

	c.data[c.keyWithPrefix(key)] = &cacheEntry{
		value:     value,
		expiresAt: time.Now().Add(expiration),
	}

	return nil
}

// Delete removes a key from cache
func (c *MemoryCache) Delete(ctx context.Context, key string) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	delete(c.data, c.keyWithPrefix(key))
	return nil
}

// Exists checks if a key exists in cache
func (c *MemoryCache) Exists(ctx context.Context, key string) (bool, error) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	entry, exists := c.data[c.keyWithPrefix(key)]
	if !exists {
		return false, nil
	}

	// Check if expired
	if time.Now().After(entry.expiresAt) {
		return false, nil
	}

	return true, nil
}

// Clear removes all keys from cache
func (c *MemoryCache) Clear(ctx context.Context) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.data = make(map[string]*cacheEntry)
	return nil
}

// GetTTL returns the time-to-live for a key
func (c *MemoryCache) GetTTL(ctx context.Context, key string) (time.Duration, error) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	entry, exists := c.data[c.keyWithPrefix(key)]
	if !exists {
		return 0, ErrKeyNotFound
	}

	ttl := time.Until(entry.expiresAt)
	if ttl <= 0 {
		return 0, ErrKeyNotFound
	}

	return ttl, nil
}

// SetNX sets a key only if it doesn't exist
func (c *MemoryCache) SetNX(ctx context.Context, key string, value []byte, expiration time.Duration) (bool, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	prefixedKey := c.keyWithPrefix(key)
	entry, exists := c.data[prefixedKey]

	// Check if key exists and is not expired
	if exists && time.Now().Before(entry.expiresAt) {
		return false, nil
	}

	if expiration <= 0 {
		expiration = c.config.DefaultTTL
	}

	c.data[prefixedKey] = &cacheEntry{
		value:     value,
		expiresAt: time.Now().Add(expiration),
	}

	return true, nil
}

// Increment atomically increments a counter
func (c *MemoryCache) Increment(ctx context.Context, key string, delta int64) (int64, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	prefixedKey := c.keyWithPrefix(key)
	entry, exists := c.data[prefixedKey]

	var currentValue int64 = 0
	if exists && time.Now().Before(entry.expiresAt) {
		// Try to parse existing value as int64
		if len(entry.value) == 8 {
			currentValue = int64(entry.value[0])<<56 |
				int64(entry.value[1])<<48 |
				int64(entry.value[2])<<40 |
				int64(entry.value[3])<<32 |
				int64(entry.value[4])<<24 |
				int64(entry.value[5])<<16 |
				int64(entry.value[6])<<8 |
				int64(entry.value[7])
		}
	}

	newValue := currentValue + delta

	// Convert int64 to bytes
	valueBytes := make([]byte, 8)
	valueBytes[0] = byte(newValue >> 56)
	valueBytes[1] = byte(newValue >> 48)
	valueBytes[2] = byte(newValue >> 40)
	valueBytes[3] = byte(newValue >> 32)
	valueBytes[4] = byte(newValue >> 24)
	valueBytes[5] = byte(newValue >> 16)
	valueBytes[6] = byte(newValue >> 8)
	valueBytes[7] = byte(newValue)

	c.data[prefixedKey] = &cacheEntry{
		value:     valueBytes,
		expiresAt: time.Now().Add(c.config.DefaultTTL),
	}

	return newValue, nil
}

// Close closes the cache
func (c *MemoryCache) Close() error {
	if c == nil {
		return nil // Nothing to close
	}

	if c.cleanup != nil {
		c.cleanup.Stop()
	}

	if c.done != nil {
		close(c.done)
	}

	c.mu.Lock()
	c.data = nil
	c.mu.Unlock()

	return nil
}

// keyWithPrefix adds prefix to key
func (c *MemoryCache) keyWithPrefix(key string) string {
	if c.config.KeyPrefix == "" {
		return key
	}
	return c.config.KeyPrefix + key
}

// evictOldest removes the oldest entry (simple LRU approximation)
func (c *MemoryCache) evictOldest() {
	var oldestKey string
	var oldestTime time.Time

	for key, entry := range c.data {
		if oldestKey == "" || entry.expiresAt.Before(oldestTime) {
			oldestKey = key
			oldestTime = entry.expiresAt
		}
	}

	if oldestKey != "" {
		delete(c.data, oldestKey)
	}
}

// startCleanup runs the cleanup goroutine
func (c *MemoryCache) startCleanup() {
	for {
		select {
		case <-c.cleanup.C:
			c.cleanupExpired()
		case <-c.done:
			return
		}
	}
}

// cleanupExpired removes expired entries
func (c *MemoryCache) cleanupExpired() {
	c.mu.Lock()
	defer c.mu.Unlock()

	now := time.Now()
	for key, entry := range c.data {
		if now.After(entry.expiresAt) {
			delete(c.data, key)
		}
	}
}

// Common cache errors
var (
	ErrKeyNotFound = errors.New("key not found")
	ErrKeyExists   = errors.New("key already exists")
)
