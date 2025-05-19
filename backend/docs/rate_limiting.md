# Rate Limiting in TOEIC App

This document explains the rate limiting configuration in the TOEIC application backend.

## Overview

Rate limiting protects the application from abuse, denial-of-service attacks, and ensures fair resource allocation. TOEIC app implements a multi-tier rate limiting system with different configurations for authenticated and anonymous users.

## Configuration

Rate limiting is configured through environment variables in the backend:

```env
# Enable/disable rate limiting (true/false)
RATE_LIMIT_ENABLED=true

# General API rate limiting (requests per second)
RATE_LIMIT_REQUESTS=10
RATE_LIMIT_BURST=20

# How long to keep user's rate limit data in memory (seconds)
RATE_LIMIT_EXPIRES_IN=3600

# Auth endpoints rate limiting (more restrictive)
AUTH_RATE_LIMIT_ENABLED=true
AUTH_RATE_LIMIT_REQUESTS=3
AUTH_RATE_LIMIT_BURST=5
```

## How It Works

### Rate Limiting Tiers

1. **Short-term Rate Limiting**
   - Controls request rate per second
   - Configurable via `RATE_LIMIT_REQUESTS` and `RATE_LIMIT_BURST`
   - Example: 10 req/sec with bursts up to 20 requests

2. **Long-term Quota**
   - Restricts total requests over a period (e.g., 1 hour)
   - Default quotas:
     - Anonymous users: 600 requests/hour
     - Authenticated users: 1200 requests/hour

3. **Authentication Endpoints**
   - Stricter limits for login/register endpoints
   - Configurable via `AUTH_RATE_LIMIT_*` variables
   - Default: 3 req/sec with bursts up to 5

### Client Identification

- **Anonymous users**: Rate limited by IP address
- **Authenticated users**: Rate limited by user ID from JWT token

## API Response Headers

Rate limited responses include the following headers:

```
X-RateLimit-Limit: 600           # Request quota for the period
X-RateLimit-Remaining: 598       # Remaining requests in the period
X-RateLimit-Reset: 1621728000    # Unix timestamp when quota resets
Retry-After: 120                 # Seconds to wait before retrying
```

## Response Format for Rate Limited Requests

```json
{
  "status": "error",
  "message": "Rate limit exceeded",
  "error": "Too many requests in a short period of time. Please slow down.",
  "rate_limit": {
    "limit": 600,
    "remaining": 0,
    "reset_timestamp": 1621728000,
    "retry_after_seconds": 120
  }
}
```

## Implementation Details

The rate limiting system uses:
- Token bucket algorithm via Go's `x/time/rate` package
- In-memory storage with periodic cleanup
- Different limiters for auth vs. standard endpoints
- Auto-expiring client data to prevent memory leaks

## Recommendations

1. Adjust limits based on actual application usage patterns
2. Consider implementing more sophisticated rate limiting strategies for production:
   - Redis-based distributed rate limiting
   - Different limits based on user roles or subscription levels
   - Graduated throttling (slowing down vs. complete blocking)

## Troubleshooting

If legitimate users report being rate limited:

1. Check the server logs for excess requests from their IP
2. Consider increasing limits or providing higher quotas for authenticated users
3. Implement exemption mechanisms for trusted clients

---

For additional questions, contact the developer team.
