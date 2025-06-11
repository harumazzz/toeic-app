package cache

import (
	"context"
	"strconv"
	"time"

	"github.com/redis/go-redis/v9"
)

// RedisCache implements Cache interface using Redis
type RedisCache struct {
	client *redis.Client
	config CacheConfig
}

// NewRedisCache creates a new Redis cache
func NewRedisCache(config CacheConfig) (*RedisCache, error) {
	client := redis.NewClient(&redis.Options{
		Addr:     config.RedisAddr,
		Password: config.RedisPassword,
		DB:       config.RedisDB,
		PoolSize: config.RedisPoolSize,
	})

	// Test connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, err
	}

	return &RedisCache{
		client: client,
		config: config,
	}, nil
}

// Get retrieves a value from cache
func (r *RedisCache) Get(ctx context.Context, key string) ([]byte, error) {
	result, err := r.client.Get(ctx, r.keyWithPrefix(key)).Bytes()
	if err != nil {
		if err == redis.Nil {
			return nil, ErrKeyNotFound
		}
		return nil, err
	}
	return result, nil
}

// Set stores a value in cache with expiration
func (r *RedisCache) Set(ctx context.Context, key string, value []byte, expiration time.Duration) error {
	if expiration <= 0 {
		expiration = r.config.DefaultTTL
	}

	return r.client.Set(ctx, r.keyWithPrefix(key), value, expiration).Err()
}

// Delete removes a key from cache
func (r *RedisCache) Delete(ctx context.Context, key string) error {
	return r.client.Del(ctx, r.keyWithPrefix(key)).Err()
}

// Exists checks if a key exists in cache
func (r *RedisCache) Exists(ctx context.Context, key string) (bool, error) {
	result, err := r.client.Exists(ctx, r.keyWithPrefix(key)).Result()
	if err != nil {
		return false, err
	}
	return result > 0, nil
}

// Clear removes all keys from cache (with prefix)
func (r *RedisCache) Clear(ctx context.Context) error {
	if r.config.KeyPrefix == "" {
		return r.client.FlushDB(ctx).Err()
	}

	// Delete keys with prefix
	pattern := r.config.KeyPrefix + "*"
	keys, err := r.client.Keys(ctx, pattern).Result()
	if err != nil {
		return err
	}

	if len(keys) > 0 {
		return r.client.Del(ctx, keys...).Err()
	}

	return nil
}

// GetTTL returns the time-to-live for a key
func (r *RedisCache) GetTTL(ctx context.Context, key string) (time.Duration, error) {
	ttl, err := r.client.TTL(ctx, r.keyWithPrefix(key)).Result()
	if err != nil {
		return 0, err
	}

	if ttl < 0 {
		return 0, ErrKeyNotFound
	}

	return ttl, nil
}

// SetNX sets a key only if it doesn't exist
func (r *RedisCache) SetNX(ctx context.Context, key string, value []byte, expiration time.Duration) (bool, error) {
	if expiration <= 0 {
		expiration = r.config.DefaultTTL
	}

	result, err := r.client.SetNX(ctx, r.keyWithPrefix(key), value, expiration).Result()
	return result, err
}

// Increment atomically increments a counter
func (r *RedisCache) Increment(ctx context.Context, key string, delta int64) (int64, error) {
	result, err := r.client.IncrBy(ctx, r.keyWithPrefix(key), delta).Result()
	if err != nil {
		return 0, err
	}

	// Set expiration if this is a new key
	r.client.Expire(ctx, r.keyWithPrefix(key), r.config.DefaultTTL)

	return result, nil
}

// Close closes the Redis connection
func (r *RedisCache) Close() error {
	return r.client.Close()
}

// keyWithPrefix adds prefix to key
func (r *RedisCache) keyWithPrefix(key string) string {
	if r.config.KeyPrefix == "" {
		return key
	}
	return r.config.KeyPrefix + key
}

// Additional Redis-specific methods

// GetMultiple retrieves multiple values at once
func (r *RedisCache) GetMultiple(ctx context.Context, keys []string) (map[string][]byte, error) {
	if len(keys) == 0 {
		return make(map[string][]byte), nil
	}

	prefixedKeys := make([]string, len(keys))
	for i, key := range keys {
		prefixedKeys[i] = r.keyWithPrefix(key)
	}

	values, err := r.client.MGet(ctx, prefixedKeys...).Result()
	if err != nil {
		return nil, err
	}

	result := make(map[string][]byte)
	for i, value := range values {
		if value != nil {
			if str, ok := value.(string); ok {
				result[keys[i]] = []byte(str)
			}
		}
	}

	return result, nil
}

// SetMultiple stores multiple key-value pairs
func (r *RedisCache) SetMultiple(ctx context.Context, items map[string][]byte, expiration time.Duration) error {
	if len(items) == 0 {
		return nil
	}

	if expiration <= 0 {
		expiration = r.config.DefaultTTL
	}

	pipe := r.client.Pipeline()

	for key, value := range items {
		pipe.Set(ctx, r.keyWithPrefix(key), value, expiration)
	}

	_, err := pipe.Exec(ctx)
	return err
}

// GetStats returns Redis statistics
func (r *RedisCache) GetStats(ctx context.Context) (map[string]string, error) {
	info, err := r.client.Info(ctx, "memory", "stats").Result()
	if err != nil {
		return nil, err
	}

	stats := make(map[string]string)
	stats["info"] = info

	// Get key count with prefix
	if r.config.KeyPrefix != "" {
		pattern := r.config.KeyPrefix + "*"
		keys, err := r.client.Keys(ctx, pattern).Result()
		if err == nil {
			stats["key_count"] = strconv.Itoa(len(keys))
		}
	}

	return stats, nil
}
