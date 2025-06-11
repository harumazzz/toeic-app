package api

import (
	"context"
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
