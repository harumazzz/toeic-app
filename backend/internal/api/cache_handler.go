package api

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/cache"
	"github.com/toeic-app/internal/logger"
)

// @Summary Get cache statistics
// @Description Get cache statistics and information
// @Tags Admin
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{} "Cache statistics"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Internal Server Error"
// @Router /api/v1/admin/cache/stats [get]
func (server *Server) getCacheStats(ctx *gin.Context) {
	if !server.config.CacheEnabled {
		ErrorResponse(ctx, http.StatusBadRequest, "Cache is not enabled", nil)
		return
	}

	stats := make(map[string]interface{})

	// Basic cache info
	stats["enabled"] = server.config.CacheEnabled
	stats["type"] = server.config.CacheType
	stats["default_ttl"] = server.config.CacheDefaultTTL.String()
	stats["http_cache_enabled"] = server.config.HTTPCacheEnabled
	stats["http_cache_ttl"] = server.config.HTTPCacheTTL.String()

	// Get HTTP cache stats if available
	if server.httpCache != nil {
		httpStats := server.httpCache.GetCacheStats(context.Background())
		stats["http_cache"] = httpStats
	}

	// Memory cache specific stats
	if server.config.CacheType == "memory" {
		stats["max_entries"] = server.config.CacheMaxEntries
		stats["cleanup_interval"] = server.config.CacheCleanupInt.String()
	}

	// Redis cache specific stats
	if server.config.CacheType == "redis" {
		stats["redis_addr"] = server.config.RedisAddr
		stats["redis_db"] = server.config.RedisDB
		stats["redis_pool_size"] = server.config.RedisPoolSize
	}
	logger.Info("Cache statistics requested by admin")
	SuccessResponse(ctx, http.StatusOK, "Cache statistics retrieved successfully", stats)
}

// @Summary Clear all cache
// @Description Clear all cached data
// @Tags Admin
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} Response "Cache cleared successfully"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Internal Server Error"
// @Router /api/v1/admin/cache/clear [delete]
func (server *Server) clearCache(ctx *gin.Context) {
	if !server.config.CacheEnabled || server.cache == nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Cache is not enabled", nil)
		return
	}

	bgCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.cache.Clear(bgCtx); err != nil {
		logger.Error("Failed to clear cache: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to clear cache", err)
		return
	}
	logger.Info("Cache cleared by admin")
	SuccessResponse(ctx, http.StatusOK, "Cache cleared successfully", nil)
}

// @Summary Clear cache by pattern
// @Description Clear cached data matching a specific pattern
// @Tags Admin
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param pattern path string true "Cache key pattern to clear"
// @Success 200 {object} Response "Cache pattern cleared successfully"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 400 {object} Response "Bad Request"
// @Failure 500 {object} Response "Internal Server Error"
// @Router /api/v1/admin/cache/clear/{pattern} [delete]
func (server *Server) clearCacheByPattern(ctx *gin.Context) {
	if !server.config.CacheEnabled || server.cache == nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Cache is not enabled", nil)
		return
	}

	pattern := ctx.Param("pattern")
	if pattern == "" {
		ErrorResponse(ctx, http.StatusBadRequest, "Pattern parameter is required", nil)
		return
	}

	bgCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// For now, this is a simplified implementation
	// In production with Redis, you would use SCAN to find and delete matching keys
	if server.httpCache != nil {
		if err := server.httpCache.ClearByPattern(bgCtx, pattern); err != nil {
			logger.Error("Failed to clear cache by pattern %s: %v", pattern, err)
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to clear cache by pattern", err)
			return
		}
	} else {
		// For basic cache, clear all (simplified)
		if err := server.cache.Clear(bgCtx); err != nil {
			logger.Error("Failed to clear cache: %v", err)
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to clear cache", err)
			return
		}
	}
	logger.Info("Cache pattern '%s' cleared by admin", pattern)
	SuccessResponse(ctx, http.StatusOK, "Cache pattern cleared successfully", gin.H{"pattern": pattern})
}

// GetServiceCache returns the service cache instance
func (server *Server) GetServiceCache() *cache.ServiceCache {
	return server.serviceCache
}

// ClearUserCache clears cache entries related to a specific user
func (server *Server) ClearUserCache(userID int64) error {
	if !server.config.CacheEnabled || server.serviceCache == nil {
		return nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Clear user-specific cache keys
	userKeys := []string{
		server.serviceCache.GenerateKey("user:profile", userID),
		server.serviceCache.GenerateKey("user:words", userID),
		server.serviceCache.GenerateKey("user:progress", userID),
		server.serviceCache.GenerateKey("user:stats", userID),
	}

	for _, key := range userKeys {
		if err := server.serviceCache.Delete(ctx, key); err != nil {
			logger.Warn("Failed to clear user cache key %s: %v", key, err)
		}
	}

	logger.Debug("Cleared cache for user %d", userID)
	return nil
}

// ClearContentCache clears cache entries related to content
func (server *Server) ClearContentCache(contentType string) error {
	if !server.config.CacheEnabled || server.serviceCache == nil {
		return nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// This is a simplified implementation
	// In production, you might want to maintain a list of cache keys by type
	if err := server.serviceCache.DeletePattern(ctx, "content:*"); err != nil {
		logger.Warn("Failed to clear content cache: %v", err)
		return err
	}

	logger.Debug("Cleared content cache for type: %s", contentType)
	return nil
}

// @Summary Get advanced cache statistics
// @Description Get comprehensive cache statistics including distributed cache, warming, and metrics
// @Tags Admin
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{} "Advanced cache statistics"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Internal Server Error"
// @Router /api/v1/admin/cache/advanced-stats [get]
func (server *Server) getAdvancedCacheStats(ctx *gin.Context) {
	if !server.config.CacheEnabled {
		ErrorResponse(ctx, http.StatusBadRequest, "Cache is not enabled", nil)
		return
	}

	stats := make(map[string]interface{})

	// Get basic cache stats
	basicStats := server.getCacheStatsData()
	for k, v := range basicStats {
		stats[k] = v
	}

	// Get cache manager stats if available
	if server.cacheManager != nil {
		managerStats := server.cacheManager.GetStats(context.Background())
		stats["cache_manager"] = managerStats
	}

	// Get distributed cache stats if available
	if server.distributedCache != nil {
		distributedStats := server.distributedCache.GetStats(context.Background())
		stats["distributed_cache"] = distributedStats
	}

	// Get cache warmer stats if available
	if server.cacheWarmer != nil {
		warmerStats := server.cacheWarmer.GetStats()
		stats["cache_warmer"] = warmerStats
	}

	logger.Info("Advanced cache statistics requested by admin")
	SuccessResponse(ctx, http.StatusOK, "Advanced cache statistics retrieved successfully", stats)
}

// @Summary Get cache health status
// @Description Get health status of all cache components
// @Tags Admin
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{} "Cache health status"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 500 {object} Response "Internal Server Error"
// @Router /api/v1/admin/cache/health [get]
func (server *Server) getCacheHealth(ctx *gin.Context) {
	if !server.config.CacheEnabled {
		ErrorResponse(ctx, http.StatusBadRequest, "Cache is not enabled", nil)
		return
	}

	health := make(map[string]interface{})

	if server.cacheManager != nil {
		managerHealth := server.cacheManager.GetHealthStatus(context.Background())
		health = managerHealth
	} else {
		// Basic health check for primary cache
		testKey := "health_check_" + fmt.Sprintf("%d", time.Now().Unix())
		testValue := []byte("health_check")

		bgCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		if err := server.cache.Set(bgCtx, testKey, testValue, time.Minute); err != nil {
			health["primary_cache"] = "unhealthy: " + err.Error()
		} else {
			if _, err := server.cache.Get(bgCtx, testKey); err != nil {
				health["primary_cache"] = "unhealthy: read failed"
			} else {
				health["primary_cache"] = "healthy"
				server.cache.Delete(bgCtx, testKey) // Cleanup
			}
		}
	}

	SuccessResponse(ctx, http.StatusOK, "Cache health status retrieved successfully", health)
}

// @Summary Trigger manual cache warming
// @Description Manually trigger cache warming for frequently accessed data
// @Tags Admin
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} Response "Cache warming initiated successfully"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 400 {object} Response "Cache warming not available"
// @Failure 500 {object} Response "Internal Server Error"
// @Router /api/v1/admin/cache/warm [post]
func (server *Server) triggerCacheWarming(ctx *gin.Context) {
	if !server.config.CacheEnabled {
		ErrorResponse(ctx, http.StatusBadRequest, "Cache is not enabled", nil)
		return
	}

	if server.cacheManager == nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Cache manager not available", nil)
		return
	}

	bgCtx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	if err := server.cacheManager.WarmCache(bgCtx); err != nil {
		logger.Error("Failed to trigger cache warming: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to trigger cache warming", err)
		return
	}

	logger.Info("Manual cache warming triggered by admin")
	SuccessResponse(ctx, http.StatusOK, "Cache warming initiated successfully", nil)
}

// @Summary Invalidate cache by tag
// @Description Invalidate all cache entries associated with a specific tag
// @Tags Admin
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param tag path string true "Tag to invalidate"
// @Success 200 {object} Response "Cache invalidated successfully"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 400 {object} Response "Bad Request"
// @Failure 500 {object} Response "Internal Server Error"
// @Router /api/v1/admin/cache/invalidate/tag/{tag} [delete]
func (server *Server) invalidateCacheByTag(ctx *gin.Context) {
	if !server.config.CacheEnabled {
		ErrorResponse(ctx, http.StatusBadRequest, "Cache is not enabled", nil)
		return
	}

	tag := ctx.Param("tag")
	if tag == "" {
		ErrorResponse(ctx, http.StatusBadRequest, "Tag parameter is required", nil)
		return
	}

	bgCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if server.cacheManager != nil {
		if err := server.cacheManager.InvalidateByTag(bgCtx, tag); err != nil {
			logger.Error("Failed to invalidate cache by tag %s: %v", tag, err)
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to invalidate cache by tag", err)
			return
		}
	} else {
		// Fallback to clearing all cache if no advanced invalidation
		if err := server.cache.Clear(bgCtx); err != nil {
			logger.Error("Failed to clear cache: %v", err)
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to clear cache", err)
			return
		}
	}

	logger.Info("Cache invalidated by tag '%s' by admin", tag)
	SuccessResponse(ctx, http.StatusOK, "Cache invalidated successfully", gin.H{"tag": tag})
}

// getCacheStatsData returns basic cache statistics as a map
func (server *Server) getCacheStatsData() map[string]interface{} {
	stats := make(map[string]interface{})

	// Basic cache info
	stats["enabled"] = server.config.CacheEnabled
	stats["type"] = server.config.CacheType
	stats["default_ttl"] = server.config.CacheDefaultTTL.String()
	stats["http_cache_enabled"] = server.config.HTTPCacheEnabled
	stats["http_cache_ttl"] = server.config.HTTPCacheTTL.String()

	// Advanced cache features
	stats["shard_count"] = server.config.CacheShardCount
	stats["replication_factor"] = server.config.CacheReplication
	stats["warming_enabled"] = server.config.CacheWarmingEnabled
	stats["compression_enabled"] = server.config.CacheCompressionEnabled
	stats["metrics_enabled"] = server.config.CacheMetricsEnabled
	stats["max_memory_usage"] = server.config.CacheMaxMemoryUsage
	stats["eviction_policy"] = server.config.CacheEvictionPolicy

	// Get HTTP cache stats if available
	if server.httpCache != nil {
		httpStats := server.httpCache.GetCacheStats(context.Background())
		stats["http_cache"] = httpStats
	}

	// Memory cache specific stats
	if server.config.CacheType == "memory" {
		stats["max_entries"] = server.config.CacheMaxEntries
		stats["cleanup_interval"] = server.config.CacheCleanupInt.String()
	}

	// Redis cache specific stats
	if server.config.CacheType == "redis" {
		stats["redis_addr"] = server.config.RedisAddr
		stats["redis_db"] = server.config.RedisDB
		stats["redis_pool_size"] = server.config.RedisPoolSize
	}

	return stats
}
