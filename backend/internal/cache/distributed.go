package cache

import (
	"context"
	"crypto/md5"
	"fmt"
	"hash/crc32"
	"sync"
	"time"

	"github.com/toeic-app/internal/logger"
)

// DistributedCache manages multiple Redis instances for horizontal scaling
type DistributedCache struct {
	shards        []*RedisCache
	shardCount    int
	config        DistributedCacheConfig
	healthCheck   *time.Ticker
	healthStatus  map[int]bool
	healthMutex   sync.RWMutex
	fallbackCache Cache // Fallback to memory cache if all Redis shards fail
}

// DistributedCacheConfig holds configuration for distributed cache
type DistributedCacheConfig struct {
	ShardConfigs        []CacheConfig
	HealthCheckInterval time.Duration
	FallbackEnabled     bool
	ConsistentHashing   bool
	ReplicationFactor   int // How many shards to replicate data to
}

// NewDistributedCache creates a new distributed cache with multiple Redis shards
func NewDistributedCache(config DistributedCacheConfig) (*DistributedCache, error) {
	if len(config.ShardConfigs) == 0 {
		return nil, fmt.Errorf("at least one shard configuration is required")
	}

	shards := make([]*RedisCache, len(config.ShardConfigs))
	healthStatus := make(map[int]bool)

	// Initialize each shard
	for i, shardConfig := range config.ShardConfigs {
		shard, err := NewRedisCache(shardConfig)
		if err != nil {
			logger.Warn("Failed to initialize shard %d: %v", i, err)
			healthStatus[i] = false
			continue
		}
		shards[i] = shard
		healthStatus[i] = true
	}

	// Initialize fallback cache if enabled
	var fallbackCache Cache
	if config.FallbackEnabled {
		fallbackConfig := CacheConfig{
			Type:            TypeMemory,
			MaxEntries:      10000,
			DefaultTTL:      30 * time.Minute,
			CleanupInterval: 10 * time.Minute,
			KeyPrefix:       "fallback:",
		}
		fallbackCache = NewMemoryCache(fallbackConfig)
	}

	dc := &DistributedCache{
		shards:        shards,
		shardCount:    len(config.ShardConfigs),
		config:        config,
		healthStatus:  healthStatus,
		fallbackCache: fallbackCache,
	}

	// Start health checking
	if config.HealthCheckInterval > 0 {
		dc.startHealthCheck()
	}

	logger.Info("Distributed cache initialized with %d shards", len(config.ShardConfigs))
	return dc, nil
}

// getShard returns the appropriate shard for a key
func (dc *DistributedCache) getShard(key string) *RedisCache {
	var shardIndex int

	if dc.config.ConsistentHashing {
		// Use consistent hashing for better distribution
		hash := crc32.ChecksumIEEE([]byte(key))
		shardIndex = int(hash) % dc.shardCount
	} else {
		// Simple hash-based distribution
		hash := md5.Sum([]byte(key))
		shardIndex = int(hash[0]) % dc.shardCount
	}

	// Check if shard is healthy
	dc.healthMutex.RLock()
	healthy := dc.healthStatus[shardIndex]
	dc.healthMutex.RUnlock()

	if !healthy {
		// Find a healthy shard
		for i := 0; i < dc.shardCount; i++ {
			nextIndex := (shardIndex + i) % dc.shardCount
			dc.healthMutex.RLock()
			isHealthy := dc.healthStatus[nextIndex]
			dc.healthMutex.RUnlock()

			if isHealthy && dc.shards[nextIndex] != nil {
				return dc.shards[nextIndex]
			}
		}
		// All shards unhealthy, return nil to use fallback
		return nil
	}

	return dc.shards[shardIndex]
}

// Get retrieves a value from the distributed cache
func (dc *DistributedCache) Get(ctx context.Context, key string) ([]byte, error) {
	shard := dc.getShard(key)
	if shard == nil {
		if dc.fallbackCache != nil {
			logger.Debug("Using fallback cache for Get: %s", key)
			return dc.fallbackCache.Get(ctx, key)
		}
		return nil, fmt.Errorf("no healthy shards available")
	}

	return shard.Get(ctx, key)
}

// Set stores a value in the distributed cache with replication
func (dc *DistributedCache) Set(ctx context.Context, key string, value []byte, expiration time.Duration) error {
	primaryShard := dc.getShard(key)
	if primaryShard == nil {
		if dc.fallbackCache != nil {
			logger.Debug("Using fallback cache for Set: %s", key)
			return dc.fallbackCache.Set(ctx, key, value, expiration)
		}
		return fmt.Errorf("no healthy shards available")
	}

	// Set on primary shard
	err := primaryShard.Set(ctx, key, value, expiration)
	if err != nil {
		return err
	}

	// Replicate to additional shards if replication is enabled
	if dc.config.ReplicationFactor > 1 {
		go dc.replicateData(ctx, key, value, expiration)
	}

	return nil
}

// replicateData replicates data to additional shards for fault tolerance
func (dc *DistributedCache) replicateData(ctx context.Context, key string, value []byte, expiration time.Duration) {
	replicationKey := "replica:" + key
	replicaCount := 0

	for i := 0; i < dc.shardCount && replicaCount < dc.config.ReplicationFactor-1; i++ {
		if dc.shards[i] != nil {
			dc.healthMutex.RLock()
			healthy := dc.healthStatus[i]
			dc.healthMutex.RUnlock()

			if healthy {
				if err := dc.shards[i].Set(ctx, replicationKey, value, expiration); err != nil {
					logger.Warn("Failed to replicate to shard %d: %v", i, err)
				} else {
					replicaCount++
				}
			}
		}
	}
}

// Delete removes a key from all shards
func (dc *DistributedCache) Delete(ctx context.Context, key string) error {
	var lastErr error
	deleted := false

	// Delete from all shards to ensure consistency
	for i, shard := range dc.shards {
		if shard == nil {
			continue
		}

		dc.healthMutex.RLock()
		healthy := dc.healthStatus[i]
		dc.healthMutex.RUnlock()

		if healthy {
			if err := shard.Delete(ctx, key); err != nil {
				lastErr = err
				logger.Warn("Failed to delete from shard %d: %v", i, err)
			} else {
				deleted = true
			}

			// Also delete replica
			shard.Delete(ctx, "replica:"+key)
		}
	}

	// Try fallback cache as well
	if dc.fallbackCache != nil {
		if err := dc.fallbackCache.Delete(ctx, key); err == nil {
			deleted = true
		}
	}

	if !deleted && lastErr != nil {
		return lastErr
	}

	return nil
}

// Exists checks if a key exists in any shard
func (dc *DistributedCache) Exists(ctx context.Context, key string) (bool, error) {
	shard := dc.getShard(key)
	if shard == nil {
		if dc.fallbackCache != nil {
			return dc.fallbackCache.Exists(ctx, key)
		}
		return false, fmt.Errorf("no healthy shards available")
	}

	return shard.Exists(ctx, key)
}

// Clear removes all keys from all shards
func (dc *DistributedCache) Clear(ctx context.Context) error {
	var lastErr error

	for i, shard := range dc.shards {
		if shard == nil {
			continue
		}

		dc.healthMutex.RLock()
		healthy := dc.healthStatus[i]
		dc.healthMutex.RUnlock()

		if healthy {
			if err := shard.Clear(ctx); err != nil {
				lastErr = err
				logger.Warn("Failed to clear shard %d: %v", i, err)
			}
		}
	}

	if dc.fallbackCache != nil {
		dc.fallbackCache.Clear(ctx)
	}

	return lastErr
}

// GetTTL returns the TTL for a key
func (dc *DistributedCache) GetTTL(ctx context.Context, key string) (time.Duration, error) {
	shard := dc.getShard(key)
	if shard == nil {
		if dc.fallbackCache != nil {
			return dc.fallbackCache.GetTTL(ctx, key)
		}
		return 0, fmt.Errorf("no healthy shards available")
	}

	return shard.GetTTL(ctx, key)
}

// SetNX sets a key only if it doesn't exist
func (dc *DistributedCache) SetNX(ctx context.Context, key string, value []byte, expiration time.Duration) (bool, error) {
	shard := dc.getShard(key)
	if shard == nil {
		if dc.fallbackCache != nil {
			return dc.fallbackCache.SetNX(ctx, key, value, expiration)
		}
		return false, fmt.Errorf("no healthy shards available")
	}

	return shard.SetNX(ctx, key, value, expiration)
}

// Increment atomically increments a counter
func (dc *DistributedCache) Increment(ctx context.Context, key string, delta int64) (int64, error) {
	shard := dc.getShard(key)
	if shard == nil {
		if dc.fallbackCache != nil {
			return dc.fallbackCache.Increment(ctx, key, delta)
		}
		return 0, fmt.Errorf("no healthy shards available")
	}

	return shard.Increment(ctx, key, delta)
}

// Close closes all connections
func (dc *DistributedCache) Close() error {
	if dc.healthCheck != nil {
		dc.healthCheck.Stop()
	}

	for _, shard := range dc.shards {
		if shard != nil {
			shard.Close()
		}
	}

	if dc.fallbackCache != nil {
		dc.fallbackCache.Close()
	}

	return nil
}

// startHealthCheck starts monitoring shard health
func (dc *DistributedCache) startHealthCheck() {
	dc.healthCheck = time.NewTicker(dc.config.HealthCheckInterval)

	go func() {
		for range dc.healthCheck.C {
			dc.checkShardHealth()
		}
	}()
}

// checkShardHealth checks the health of all shards
func (dc *DistributedCache) checkShardHealth() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	for i, shard := range dc.shards {
		if shard == nil {
			dc.healthMutex.Lock()
			dc.healthStatus[i] = false
			dc.healthMutex.Unlock()
			continue
		}

		// Try a simple ping
		_, err := shard.client.Ping(ctx).Result()

		dc.healthMutex.Lock()
		previousStatus := dc.healthStatus[i]
		dc.healthStatus[i] = err == nil
		dc.healthMutex.Unlock()

		// Log status changes
		if previousStatus != dc.healthStatus[i] {
			if dc.healthStatus[i] {
				logger.Info("Shard %d is now healthy", i)
			} else {
				logger.Warn("Shard %d is now unhealthy: %v", i, err)
			}
		}
	}
}

// GetHealthStatus returns the health status of all shards
func (dc *DistributedCache) GetHealthStatus() map[int]bool {
	dc.healthMutex.RLock()
	defer dc.healthMutex.RUnlock()

	status := make(map[int]bool)
	for i, healthy := range dc.healthStatus {
		status[i] = healthy
	}
	return status
}

// GetStats returns statistics for all shards
func (dc *DistributedCache) GetStats(ctx context.Context) map[string]interface{} {
	stats := make(map[string]interface{})
	stats["shard_count"] = dc.shardCount
	stats["replication_factor"] = dc.config.ReplicationFactor
	stats["consistent_hashing"] = dc.config.ConsistentHashing
	stats["fallback_enabled"] = dc.config.FallbackEnabled

	shardStats := make(map[string]interface{})
	healthyShards := 0

	for i, shard := range dc.shards {
		dc.healthMutex.RLock()
		healthy := dc.healthStatus[i]
		dc.healthMutex.RUnlock()

		if healthy && shard != nil {
			healthyShards++
			if shardInfo, err := shard.GetStats(ctx); err == nil {
				shardStats[fmt.Sprintf("shard_%d", i)] = shardInfo
			}
		} else {
			shardStats[fmt.Sprintf("shard_%d", i)] = map[string]interface{}{
				"status": "unhealthy",
			}
		}
	}

	stats["healthy_shards"] = healthyShards
	stats["shard_details"] = shardStats
	return stats
}
