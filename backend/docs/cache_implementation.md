# Cache Implementation in TOEIC App

This document explains the comprehensive caching system implemented in the TOEIC application backend.

## Overview

The caching system provides multiple layers of caching to improve application performance:

1. **HTTP Response Caching**: Caches HTTP responses to reduce server load
2. **Service Layer Caching**: Caches database query results and computed data
3. **Flexible Storage**: Supports both in-memory and Redis storage backends

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP Cache    │    │  Service Cache  │    │  Storage Layer  │
│   Middleware    │────│     Helper      │────│ Memory / Redis  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Configuration

### Environment Variables

```bash
# Enable/disable caching
CACHE_ENABLED=true

# Cache storage type: "memory" or "redis"
CACHE_TYPE=memory

# Default TTL for cache entries (seconds)
CACHE_DEFAULT_TTL=1800

# Memory cache specific settings
CACHE_MAX_ENTRIES=10000
CACHE_CLEANUP_INT=600

# Redis specific settings (when CACHE_TYPE=redis)
REDIS_ADDR=localhost:6379
REDIS_PASSWORD=
REDIS_DB=0
REDIS_POOL_SIZE=10

# HTTP cache settings
HTTP_CACHE_ENABLED=true
HTTP_CACHE_TTL=900
```

### Memory Cache Configuration

The memory cache is suitable for single-instance deployments:

- **Max Entries**: Limits memory usage by capping the number of cached items
- **Cleanup Interval**: Automatically removes expired entries
- **LRU Eviction**: Removes oldest entries when max capacity is reached

### Redis Cache Configuration

Redis cache is recommended for production and multi-instance deployments:

- **Distributed**: Shared cache across multiple application instances
- **Persistence**: Optional data persistence across restarts
- **Scalability**: Better performance under high load

## HTTP Cache Middleware

### Features

- **Automatic Caching**: Caches GET and HEAD responses automatically
- **Conditional Caching**: Respects cache-control headers
- **Cache Headers**: Adds X-Cache and X-Cache-Key headers
- **Flexible Configuration**: Configurable cache patterns and exclusions

### Configuration

```go
httpCacheConfig := cache.DefaultHTTPCacheConfig()
httpCacheConfig.DefaultTTL = 15 * time.Minute
httpCacheConfig.SkipPaths = []string{
    "/api/v1/auth",
    "/api/v1/admin", 
    "/api/v1/users/me",
}
```

### Cache Key Generation

Cache keys are generated using:
- HTTP method
- Request path
- Query parameters (configurable)
- Selected headers (configurable)

## Service Layer Caching

### Basic Usage

```go
// Get from cache or fetch from database
var word db.Word
err := server.serviceCache.GetOrSet(
    ctx,
    "word:123",
    30*time.Minute,
    func() (interface{}, error) {
        return server.store.GetWord(ctx, 123)
    },
    &word,
)
```

### Cache Key Patterns

The system uses consistent key patterns:

```go
// User-related keys
"user:profile:123"
"user:words:123"
"user:progress:123:vocabulary"

// Content-related keys
"word:123"
"grammar:456"
"exam:789"

// Search results
"search:english:vocabulary"
"content:list:words:1:10"
```

### Cache Invalidation

Cache entries are automatically invalidated when data changes:

```go
// Update operation
word, err := server.store.UpdateWord(ctx, params)
if err == nil {
    // Clear cache for updated word
    server.serviceCache.Delete(ctx, "word:123")
}
```

## Implementation Examples

### Adding Cache to a Handler

```go
func (server *Server) getWord(ctx *gin.Context) {
    var req getWordRequest
    if err := ctx.ShouldBindUri(&req); err != nil {
        ErrorResponse(ctx, http.StatusBadRequest, "Invalid word ID", err)
        return
    }

    // Try cache first
    if server.config.CacheEnabled && server.serviceCache != nil {
        cacheKey := server.serviceCache.GenerateKey("word", req.ID)
        
        var cachedWord db.Word
        if err := server.serviceCache.Get(ctx, cacheKey, &cachedWord); err == nil {
            logger.Debug("Word %d retrieved from cache", req.ID)
            wordResponse := NewWordResponse(cachedWord)
            SuccessResponse(ctx, http.StatusOK, "Word retrieved successfully", wordResponse)
            return
        }
    }

    // Fetch from database
    word, err := server.store.GetWord(ctx, req.ID)
    if err != nil {
        ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get word", err)
        return
    }

    // Cache the result
    if server.config.CacheEnabled && server.serviceCache != nil {
        cacheKey := server.serviceCache.GenerateKey("word", req.ID)
        go func() {
            bgCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
            defer cancel()
            
            if err := server.serviceCache.Set(bgCtx, cacheKey, word, server.config.CacheDefaultTTL); err != nil {
                logger.Warn("Failed to cache word %d: %v", req.ID, err)
            }
        }()
    }

    wordResponse := NewWordResponse(word)
    SuccessResponse(ctx, http.StatusOK, "Word retrieved successfully", wordResponse)
}
```

### Cache Invalidation on Updates

```go
func (server *Server) updateWord(ctx *gin.Context) {
    // ... update logic ...
    
    word, err := server.store.UpdateWord(ctx, arg)
    if err != nil {
        // ... error handling ...
        return
    }

    // Clear cache for updated word
    if server.config.CacheEnabled && server.serviceCache != nil {
        cacheKey := server.serviceCache.GenerateKey("word", req.ID)
        go func() {
            bgCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
            defer cancel()
            
            if err := server.serviceCache.Delete(bgCtx, cacheKey); err != nil {
                logger.Warn("Failed to clear cache for updated word %d: %v", req.ID, err)
            }
        }()
    }

    // ... response ...
}
```

## Admin Cache Management

### Available Endpoints

```
GET    /api/v1/admin/cache/stats           - Get cache statistics
DELETE /api/v1/admin/cache/clear           - Clear all cache
DELETE /api/v1/admin/cache/clear/{pattern} - Clear cache by pattern
```

### Cache Statistics

The stats endpoint provides information about:
- Cache configuration
- Memory usage (for memory cache)
- Redis statistics (for Redis cache)
- Hit/miss ratios
- Key counts

## Performance Considerations

### Memory Cache

**Pros:**
- Zero network latency
- Simple deployment
- No external dependencies

**Cons:**
- Limited by available RAM
- Not shared across instances
- Lost on restart

### Redis Cache

**Pros:**
- Shared across instances
- Persistent (optional)
- Better for high-traffic applications
- Advanced features (pub/sub, etc.)

**Cons:**
- Network latency
- Additional infrastructure
- More complex deployment

## Monitoring and Debugging

### Cache Headers

HTTP responses include cache information:

```
X-Cache: HIT               # Cache hit/miss status
X-Cache-Key: http:abc123   # Cache key used
```

### Logging

Cache operations are logged at appropriate levels:

```
DEBUG: Cache HIT for key: word:123
DEBUG: Cache MISS for key: word:123
WARN:  Failed to cache data for key word:123: connection timeout
```

### Admin Dashboard

Use the admin endpoints to monitor cache performance:

```bash
# Get cache statistics
curl -H "Authorization: Bearer <token>" \
     http://localhost:8000/api/v1/admin/cache/stats

# Clear specific cache patterns
curl -X DELETE \
     -H "Authorization: Bearer <token>" \
     http://localhost:8000/api/v1/admin/cache/clear/word:*
```

## Best Practices

### Cache Key Design

1. **Use Consistent Patterns**: Follow the established key patterns
2. **Include Version Info**: For schema changes, include version in keys
3. **Avoid User-Specific Data**: In HTTP cache for public endpoints

### TTL Settings

1. **User Data**: Shorter TTL (5-15 minutes)
2. **Static Content**: Longer TTL (1-24 hours)
3. **Search Results**: Medium TTL (15-30 minutes)

### Cache Invalidation

1. **Immediate Invalidation**: For critical data updates
2. **Batch Invalidation**: For bulk operations
3. **Pattern-Based**: Use patterns for related data

### Error Handling

1. **Graceful Degradation**: Application should work without cache
2. **Background Operations**: Cache updates shouldn't block responses
3. **Timeout Handling**: Set appropriate timeouts for cache operations

## Troubleshooting

### Common Issues

1. **Cache Miss Rate Too High**
   - Check TTL settings
   - Verify cache key generation
   - Monitor cache eviction

2. **Memory Usage Growing**
   - Adjust max entries for memory cache
   - Check cleanup interval
   - Monitor for memory leaks

3. **Redis Connection Issues**
   - Verify Redis server availability
   - Check network connectivity
   - Review connection pool settings

### Debug Commands

```bash
# Check cache configuration
grep CACHE .env

# Monitor Redis (if using Redis)
redis-cli monitor

# Check application logs
tail -f logs/app-$(date +%Y-%m-%d).log | grep -i cache
```

## Future Enhancements

1. **Cache Warming**: Preload frequently accessed data
2. **Cache Tagging**: Tag-based invalidation for complex relationships
3. **Analytics**: Detailed cache performance metrics
4. **Distributed Locking**: For cache stampede prevention
5. **Compression**: Compress large cached values

---

For additional questions or issues, contact the development team.
