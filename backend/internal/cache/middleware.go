package cache

import (
	"bytes"
	"context"
	"crypto/md5"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
)

// HTTPCacheMiddleware provides HTTP response caching
type HTTPCacheMiddleware struct {
	cache  Cache
	config HTTPCacheConfig
}

// HTTPCacheConfig holds HTTP cache configuration
type HTTPCacheConfig struct {
	DefaultTTL time.Duration

	// Cache control
	CacheableStatusCodes []int
	CacheableMethods     []string
	IgnoreHeaders        []string

	// Cache key generation
	IncludeHeaders     []string
	IncludeQueryParams []string
	IgnoreQueryParams  []string

	// Skip caching for certain paths/conditions
	SkipPaths      []string
	SkipUserAgents []string

	// Vary header support
	VaryHeaders []string
}

// DefaultHTTPCacheConfig returns default HTTP cache configuration
func DefaultHTTPCacheConfig() HTTPCacheConfig {
	return HTTPCacheConfig{
		DefaultTTL: 15 * time.Minute,
		CacheableStatusCodes: []int{
			http.StatusOK,
			http.StatusNotModified,
			http.StatusPartialContent,
		},
		CacheableMethods: []string{
			http.MethodGet,
			http.MethodHead,
		},
		IgnoreHeaders: []string{
			"Authorization",
			"Cookie",
			"Set-Cookie",
			"X-Csrf-Token",
		},
		SkipPaths: []string{
			"/api/v1/auth",
			"/api/v1/admin",
			"/api/v1/users/me",
		},
		VaryHeaders: []string{
			"Accept",
			"Accept-Encoding",
			"Accept-Language",
		},
	}
}

// NewHTTPCacheMiddleware creates a new HTTP cache middleware
func NewHTTPCacheMiddleware(cache Cache, config HTTPCacheConfig) *HTTPCacheMiddleware {
	return &HTTPCacheMiddleware{
		cache:  cache,
		config: config,
	}
}

// responseWriter wraps gin.ResponseWriter to capture response
type responseWriter struct {
	gin.ResponseWriter
	body   *bytes.Buffer
	status int
}

func (w *responseWriter) Write(data []byte) (int, error) {
	w.body.Write(data)
	return w.ResponseWriter.Write(data)
}

func (w *responseWriter) WriteHeader(statusCode int) {
	w.status = statusCode
	w.ResponseWriter.WriteHeader(statusCode)
}

// Middleware returns the cache middleware function
func (h *HTTPCacheMiddleware) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Skip if method is not cacheable
		if !h.isMethodCacheable(c.Request.Method) {
			c.Next()
			return
		}

		// Skip if path should be ignored
		if h.shouldSkipPath(c.Request.URL.Path) {
			c.Next()
			return
		}

		// Skip if user agent should be ignored
		if h.shouldSkipUserAgent(c.GetHeader("User-Agent")) {
			c.Next()
			return
		}

		// Generate cache key
		cacheKey := h.generateCacheKey(c)

		// Try to get from cache
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		if cachedData, err := h.cache.Get(ctx, cacheKey); err == nil {
			var cachedResponse CachedResponse
			if json.Unmarshal(cachedData, &cachedResponse) == nil {
				// Set cached headers
				for key, value := range cachedResponse.Headers {
					c.Header(key, value)
				}

				// Add cache headers
				c.Header("X-Cache", "HIT")
				c.Header("X-Cache-Key", cacheKey)

				// Return cached response
				c.Data(cachedResponse.StatusCode, cachedResponse.ContentType, cachedResponse.Body)
				c.Abort()
				return
			}
		}

		// Wrap response writer
		w := &responseWriter{
			ResponseWriter: c.Writer,
			body:           &bytes.Buffer{},
			status:         http.StatusOK,
		}
		c.Writer = w

		// Process request
		c.Next()

		// Check if response should be cached
		if h.shouldCacheResponse(w.status, c) {
			// Create cached response
			cachedResp := CachedResponse{
				StatusCode:  w.status,
				ContentType: c.GetHeader("Content-Type"),
				Body:        w.body.Bytes(),
				Headers:     make(map[string]string),
				CachedAt:    time.Now(),
			}

			// Copy cacheable headers
			for key, values := range c.Writer.Header() {
				if !h.shouldIgnoreHeader(key) && len(values) > 0 {
					cachedResp.Headers[key] = values[0]
				}
			}

			// Add cache control headers
			cachedResp.Headers["X-Cache"] = "MISS"
			cachedResp.Headers["X-Cache-Key"] = cacheKey

			// Store in cache
			if data, err := json.Marshal(cachedResp); err == nil {
				go func() {
					ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
					defer cancel()

					if err := h.cache.Set(ctx, cacheKey, data, h.config.DefaultTTL); err != nil {
						logger.Warn("Failed to cache response: %v", err)
					}
				}()
			}
		}
	}
}

// CachedResponse represents a cached HTTP response
type CachedResponse struct {
	StatusCode  int               `json:"status_code"`
	ContentType string            `json:"content_type"`
	Headers     map[string]string `json:"headers"`
	Body        []byte            `json:"body"`
	CachedAt    time.Time         `json:"cached_at"`
}

// generateCacheKey creates a unique cache key for the request
func (h *HTTPCacheMiddleware) generateCacheKey(c *gin.Context) string {
	components := []string{
		"http_cache",
		c.Request.Method,
		c.Request.URL.Path,
	}

	// Add query parameters
	if len(h.config.IncludeQueryParams) > 0 {
		for _, param := range h.config.IncludeQueryParams {
			if value := c.Query(param); value != "" {
				components = append(components, fmt.Sprintf("%s=%s", param, value))
			}
		}
	} else {
		// Include all query params except ignored ones
		for key, values := range c.Request.URL.Query() {
			if !h.shouldIgnoreQueryParam(key) && len(values) > 0 {
				components = append(components, fmt.Sprintf("%s=%s", key, values[0]))
			}
		}
	}

	// Add headers if specified
	for _, header := range h.config.IncludeHeaders {
		if value := c.GetHeader(header); value != "" {
			components = append(components, fmt.Sprintf("h_%s=%s", header, value))
		}
	}

	// Create hash of components
	key := strings.Join(components, "|")
	hash := md5.Sum([]byte(key))
	return fmt.Sprintf("http:%x", hash)
}

// isMethodCacheable checks if HTTP method is cacheable
func (h *HTTPCacheMiddleware) isMethodCacheable(method string) bool {
	for _, m := range h.config.CacheableMethods {
		if m == method {
			return true
		}
	}
	return false
}

// shouldSkipPath checks if path should be skipped
func (h *HTTPCacheMiddleware) shouldSkipPath(path string) bool {
	for _, skipPath := range h.config.SkipPaths {
		if strings.HasPrefix(path, skipPath) {
			return true
		}
	}
	return false
}

// shouldSkipUserAgent checks if user agent should be skipped
func (h *HTTPCacheMiddleware) shouldSkipUserAgent(userAgent string) bool {
	for _, skipUA := range h.config.SkipUserAgents {
		if strings.Contains(userAgent, skipUA) {
			return true
		}
	}
	return false
}

// shouldCacheResponse checks if response should be cached
func (h *HTTPCacheMiddleware) shouldCacheResponse(statusCode int, c *gin.Context) bool {
	// Check status code
	statusCacheable := false
	for _, code := range h.config.CacheableStatusCodes {
		if code == statusCode {
			statusCacheable = true
			break
		}
	}

	if !statusCacheable {
		return false
	}

	// Check for no-cache headers
	cacheControl := c.GetHeader("Cache-Control")
	if strings.Contains(cacheControl, "no-cache") || strings.Contains(cacheControl, "no-store") {
		return false
	}

	return true
}

// shouldIgnoreHeader checks if header should be ignored
func (h *HTTPCacheMiddleware) shouldIgnoreHeader(header string) bool {
	header = strings.ToLower(header)
	for _, ignore := range h.config.IgnoreHeaders {
		if strings.ToLower(ignore) == header {
			return true
		}
	}
	return false
}

// shouldIgnoreQueryParam checks if query parameter should be ignored
func (h *HTTPCacheMiddleware) shouldIgnoreQueryParam(param string) bool {
	for _, ignore := range h.config.IgnoreQueryParams {
		if ignore == param {
			return true
		}
	}
	return false
}

// ClearByPattern clears cache entries matching a pattern
func (h *HTTPCacheMiddleware) ClearByPattern(ctx context.Context, pattern string) error {
	// This is a simplified implementation
	// In production, you might want to use Redis SCAN for better performance
	return h.cache.Clear(ctx)
}

// ClearByTags clears cache entries by tags (if supported)
func (h *HTTPCacheMiddleware) ClearByTags(ctx context.Context, tags []string) error {
	// This would require tag-based caching implementation
	// For now, just clear all cache
	return h.cache.Clear(ctx)
}

// GetCacheStats returns cache statistics
func (h *HTTPCacheMiddleware) GetCacheStats(ctx context.Context) map[string]interface{} {
	stats := make(map[string]interface{})

	// If Redis cache, get Redis-specific stats
	if redisCache, ok := h.cache.(*RedisCache); ok {
		if redisStats, err := redisCache.GetStats(ctx); err == nil {
			stats["redis"] = redisStats
		}
	}

	stats["config"] = h.config
	return stats
}
