# 📚 TOEIC App Backend - Complete API Documentation

## 🚀 Overview

This document provides comprehensive API documentation for the TOEIC App Backend, including all endpoints, authentication methods, request/response formats, and usage examples.

## 🔐 Authentication

### JWT Token System
The API uses JWT (JSON Web Token) based authentication with access and refresh tokens.

- **Access Token**: Short-lived (15 minutes), used for API requests
- **Refresh Token**: Long-lived (7 days), used to obtain new access tokens

### Token Usage
Include the access token in the `Authorization` header:
```
Authorization: Bearer <access_token>
```

## 📋 API Endpoints

### 🔑 Authentication Endpoints

#### POST /api/auth/register
Register a new user account.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securePassword123"
}
```

**Response (201):**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "created_at": "2025-06-15T10:00:00Z"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

#### POST /api/auth/login
Authenticate user and receive tokens.

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "securePassword123"
}
```

**Response (200):**
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

#### POST /api/auth/refresh-token
Refresh access token using refresh token.

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

#### POST /api/auth/logout
Logout user and invalidate tokens.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "logout_all_devices": false
}
```

**Response (200):**
```json
{
  "message": "Logout successful"
}
```

### 👥 User Management Endpoints

#### GET /api/v1/users/me
Get current user profile.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "role": "user",
  "created_at": "2025-06-15T10:00:00Z",
  "updated_at": "2025-06-15T10:00:00Z"
}
```

#### GET /api/v1/users/:id
Get user by ID (Admin only).

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

**Response (200):**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "role": "user",
  "created_at": "2025-06-15T10:00:00Z",
  "updated_at": "2025-06-15T10:00:00Z"
}
```

#### GET /api/v1/users
List all users with pagination (Admin only).

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

**Query Parameters:**
- `page` (int): Page number (default: 1)
- `limit` (int): Items per page (default: 10, max: 100)
- `search` (string): Search by name or email

**Response (200):**
```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "created_at": "2025-06-15T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 1,
    "total_pages": 1
  }
}
```

#### PUT /api/v1/users/:id
Update user information.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "name": "John Updated",
  "email": "john.updated@example.com"
}
```

**Response (200):**
```json
{
  "message": "User updated successfully",
  "user": {
    "id": 1,
    "name": "John Updated",
    "email": "john.updated@example.com",
    "role": "user",
    "updated_at": "2025-06-15T11:00:00Z"
  }
}
```

#### DELETE /api/v1/users/:id
Delete user account (Admin only or own account).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "message": "User deleted successfully"
}
```

### 🛠️ Administrative Endpoints

#### GET /api/v1/admin/backups
List all database backups (Admin only).

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

**Response (200):**
```json
{
  "backups": [
    {
      "filename": "auto_backup_20250615_120000.sql",
      "size": 1048576,
      "created_at": "2025-06-15T12:00:00Z",
      "type": "auto"
    }
  ]
}
```

#### POST /api/v1/admin/backups
Create a new database backup (Admin only).

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

**Response (201):**
```json
{
  "message": "Backup created successfully",
  "filename": "manual_backup_20250615_120000.sql",
  "size": 1048576
}
```

#### GET /api/v1/admin/cache/stats
Get cache performance statistics (Admin only).

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

**Response (200):**
```json
{
  "cache_enabled": true,
  "cache_type": "redis",
  "hit_rate": 95.2,
  "total_requests": 10000,
  "cache_hits": 9520,
  "cache_misses": 480,
  "memory_usage": 536870912,
  "memory_limit": 1073741824,
  "evictions": 0,
  "connections": 50
}
```

### 🏥 System Health Endpoints

#### GET /health
System health check (No authentication required).

**Response (200):**
```json
{
  "status": "healthy",
  "timestamp": "2025-06-15T12:00:00Z",
  "version": "1.0.0",
  "services": {
    "database": "healthy",
    "cache": "healthy",
    "redis": "healthy"
  },
  "uptime": 3600
}
```

#### GET /metrics
System metrics (No authentication required).

**Response (200):**
```json
{
  "system": {
    "cpu_usage": 25.5,
    "memory_usage": 67.8,
    "disk_usage": 45.2,
    "goroutines": 150
  },
  "application": {
    "total_requests": 10000,
    "active_users": 500,
    "cache_hit_rate": 95.2,
    "avg_response_time": 85
  },
  "database": {
    "total_connections": 25,
    "active_connections": 15,
    "max_connections": 50
  }
}
```

## 🌐 Internationalization (i18n)

### GET /api/v1/i18n/languages
Get available languages.

**Response (200):**
```json
{
  "languages": [
    {
      "code": "en",
      "name": "English",
      "native_name": "English"
    },
    {
      "code": "vi",
      "name": "Vietnamese", 
      "native_name": "Tiếng Việt"
    }
  ]
}
```

### POST /api/v1/users/language
Set user preferred language.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "language": "vi"
}
```

## 🔔 WebSocket Endpoints

### WS /ws/upgrades
Real-time upgrade notifications.

**Connection Headers:**
```
Authorization: Bearer <access_token>
```

**Message Format:**
```json
{
  "type": "upgrade_available",
  "version": "1.1.0",
  "title": "New Features Available",
  "description": "Performance improvements and bug fixes",
  "mandatory": false,
  "download_url": "https://example.com/download"
}
```

## ❌ Error Responses

### Standard Error Format
```json
{
  "error": "error_code",
  "message": "Human readable error message",
  "details": {
    "field": "Additional error context"
  }
}
```

### Common HTTP Status Codes

| Status | Description |
|--------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Invalid or missing token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource doesn't exist |
| 409 | Conflict - Resource already exists |
| 422 | Unprocessable Entity - Validation failed |
| 429 | Too Many Requests - Rate limit exceeded |
| 500 | Internal Server Error |

### Example Error Responses

**400 Bad Request:**
```json
{
  "error": "validation_failed",
  "message": "Input validation failed",
  "details": {
    "email": "Invalid email format",
    "password": "Password must be at least 8 characters"
  }
}
```

**401 Unauthorized:**
```json
{
  "error": "unauthorized",
  "message": "Invalid or expired token"
}
```

**429 Rate Limited:**
```json
{
  "error": "rate_limit_exceeded",
  "message": "Too many requests. Try again later.",
  "details": {
    "retry_after": 60
  }
}
```

## 📊 Rate Limiting

- **Default**: 50 requests per minute per IP
- **Authenticated users**: 100 requests per minute
- **Admin users**: 500 requests per minute

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 50
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1623456789
```

## 🔒 Security Features

- **HTTPS Only**: All production endpoints require HTTPS
- **CORS**: Configured for allowed origins
- **Security Headers**: HSTS, CSP, X-Frame-Options, etc.
- **Input Validation**: All inputs are validated and sanitized
- **SQL Injection Protection**: Using parameterized queries
- **JWT Security**: Tokens are signed and include expiration

## 📱 Client SDKs

### JavaScript/TypeScript
```typescript
import { ToeicAPI } from '@toeic-app/api-client';

const api = new ToeicAPI({
  baseURL: 'https://api.toeic-app.com',
  timeout: 10000
});

// Login
const { user, tokens } = await api.auth.login({
  email: 'user@example.com',
  password: 'password'
});

// Set token for future requests
api.setAccessToken(tokens.access_token);

// Get user profile
const profile = await api.users.getMe();
```

### cURL Examples

**Register:**
```bash
curl -X POST https://api.toeic-app.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","password":"password123"}'
```

**Login:**
```bash
curl -X POST https://api.toeic-app.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"password123"}'
```

**Get Profile:**
```bash
curl -X GET https://api.toeic-app.com/api/v1/users/me \
  -H "Authorization: Bearer <access_token>"
```

## 📈 Performance Optimization

### Caching Strategy
- **HTTP Caching**: Response caching with ETags
- **Redis Caching**: Distributed cache for data
- **Query Optimization**: Database query caching

### Best Practices
1. Use pagination for list endpoints
2. Include only necessary fields in responses
3. Implement proper error handling
4. Use appropriate HTTP methods and status codes
5. Follow REST conventions

## 🔄 API Versioning

- Current Version: `v1`
- Base URL: `/api/v1/`
- Deprecation policy: 6 months notice for breaking changes
- Backwards compatibility maintained within major versions

---

For more information, visit the [Swagger Documentation](http://localhost:8000/swagger/index.html) when the server is running.
