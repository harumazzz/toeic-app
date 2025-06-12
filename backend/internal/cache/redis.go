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
	prefixedKey := r.keyWithPrefix(key)

	// Use a pipeline for atomic operations
	pipe := r.client.Pipeline()
	incrCmd := pipe.IncrBy(ctx, prefixedKey, delta)
	expireCmd := pipe.Expire(ctx, prefixedKey, r.config.DefaultTTL)

	_, err := pipe.Exec(ctx)
	if err != nil {
		return 0, err
	}

	result, err := incrCmd.Result()
	if err != nil {
		return 0, err
	}

	// Check if expire command succeeded, if not, try again
	if expireResult, expireErr := expireCmd.Result(); expireErr != nil || !expireResult {
		// Fallback: set TTL separately if pipeline expire failed
		go func() {
			r.client.Expire(context.Background(), prefixedKey, r.config.DefaultTTL)
		}()
	}

	return result, nil
}

// Close closes the Redis connection
func (r *RedisCache) Close() error {
	if r == nil || r.client == nil {
		return nil // Nothing to close
	}
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

// Pipeline provides access to Redis pipeline for batch operations
func (r *RedisCache) Pipeline() redis.Pipeliner {
	return r.client.Pipeline()
}

// ExecPipeline executes a Redis pipeline
func (r *RedisCache) ExecPipeline(ctx context.Context, pipe redis.Pipeliner) ([]redis.Cmder, error) {
	return pipe.Exec(ctx)
}

// GetKeysWithPattern retrieves keys matching a pattern using SCAN for better performance
func (r *RedisCache) GetKeysWithPattern(ctx context.Context, pattern string) ([]string, error) {
	var keys []string
	var cursor uint64
	var err error

	// Use SCAN instead of KEYS for better performance
	for {
		var scanKeys []string
		scanKeys, cursor, err = r.client.Scan(ctx, cursor, r.keyWithPrefix(pattern), 100).Result()
		if err != nil {
			return nil, err
		}
		keys = append(keys, scanKeys...)

		if cursor == 0 {
			break
		}
	}

	return keys, nil
}

// DeleteByPattern deletes keys matching a pattern efficiently
func (r *RedisCache) DeleteByPattern(ctx context.Context, pattern string) error {
	keys, err := r.GetKeysWithPattern(ctx, pattern)
	if err != nil {
		return err
	}

	if len(keys) == 0 {
		return nil
	}

	// Delete in batches for better performance
	batchSize := 100
	for i := 0; i < len(keys); i += batchSize {
		end := i + batchSize
		if end > len(keys) {
			end = len(keys)
		}

		batch := keys[i:end]
		if err := r.client.Del(ctx, batch...).Err(); err != nil {
			return err
		}
	}

	return nil
}

// IncrementWithExpiry atomically increments and sets expiry using Lua script
func (r *RedisCache) IncrementWithExpiry(ctx context.Context, key string, delta int64, expiry time.Duration) (int64, error) {
	luaScript := `
		local key = KEYS[1]
		local delta = tonumber(ARGV[1])
		local expiry = tonumber(ARGV[2])
		
		local current = redis.call('INCRBY', key, delta)
		redis.call('EXPIRE', key, expiry)
		
		return current
	`

	script := redis.NewScript(luaScript)
	result, err := script.Run(ctx, r.client, []string{r.keyWithPrefix(key)}, delta, int64(expiry.Seconds())).Result()
	if err != nil {
		return 0, err
	}

	return result.(int64), nil
}

// SetWithTags sets a key with tags for advanced cache invalidation
func (r *RedisCache) SetWithTags(ctx context.Context, key string, value []byte, expiration time.Duration, tags []string) error {
	pipe := r.client.Pipeline()

	// Set the main key
	prefixedKey := r.keyWithPrefix(key)
	pipe.Set(ctx, prefixedKey, value, expiration)

	// Add key to tag sets for invalidation
	for _, tag := range tags {
		tagKey := r.keyWithPrefix("tag:" + tag)
		pipe.SAdd(ctx, tagKey, prefixedKey)
		pipe.Expire(ctx, tagKey, expiration+time.Hour) // Tags expire slightly later
	}

	_, err := pipe.Exec(ctx)
	return err
}

// InvalidateByTag invalidates all keys associated with a tag
func (r *RedisCache) InvalidateByTag(ctx context.Context, tag string) error {
	tagKey := r.keyWithPrefix("tag:" + tag)

	// Get all keys for this tag
	keys, err := r.client.SMembers(ctx, tagKey).Result()
	if err != nil {
		return err
	}

	if len(keys) == 0 {
		return nil
	}

	// Delete all keys and the tag set
	allKeys := append(keys, tagKey)
	return r.client.Del(ctx, allKeys...).Err()
}

// WarmCache preloads frequently accessed data
func (r *RedisCache) WarmCache(ctx context.Context, warmupData map[string][]byte, defaultTTL time.Duration) error {
	pipe := r.client.Pipeline()

	for key, value := range warmupData {
		pipe.Set(ctx, r.keyWithPrefix(key), value, defaultTTL)
	}

	_, err := pipe.Exec(ctx)
	return err
}

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
