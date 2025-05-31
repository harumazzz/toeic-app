# Logout API

## Overview

The logout endpoint invalidates both the JWT access token and refresh token by adding them to a token blacklist. This helps improve security by ensuring that even if the tokens haven't yet expired, they can't be used after logout.

## Endpoint

```
POST /api/auth/logout
```

## Request Format

```json
{
  "refresh_token": "your-refresh-token"
}
```

The endpoint also attempts to extract and blacklist the access token from the Authorization header if it's present.

## Response Format

### Success (HTTP 200 OK)

```json
{
  "status": "success",
  "message": "Logged out successfully",
  "data": null
}
```

### Error (HTTP 400 Bad Request)

```json
{
  "status": "error",
  "message": "Invalid refresh token",
  "error": "Error details"
}
```

## Implementation Details

1. The server maintains a token blacklist to track invalidated tokens
2. When a token is blacklisted, it remains in the blacklist until its expiration time
3. A background process periodically removes expired tokens from the blacklist
4. The token verification process checks if a token is blacklisted before accepting it

## Best Practices

- Always call the logout endpoint when the user explicitly logs out
- On the client side, clear all stored tokens after logout
- Handle token invalidation errors gracefully

## Metrics

You can check the number of blacklisted tokens via the metrics endpoint:
```
GET /metrics
```

The response includes a `blacklisted_tokens` field showing the current count of blacklisted tokens.
