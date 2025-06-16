# TOEIC Backend Security Implementation Guide

## Overview

This document provides a comprehensive guide to the security features implemented in the TOEIC backend application. The security implementation follows industry best practices and addresses common vulnerabilities identified in the OWASP Top 10.

## Security Architecture

### Defense in Depth

The security implementation uses a multi-layered approach:

1. **Network Layer**: Nginx reverse proxy with rate limiting and request filtering
2. **Transport Layer**: TLS/SSL encryption with secure cipher suites
3. **Application Layer**: Multiple security middleware components
4. **Data Layer**: Database encryption and secure connections
5. **Infrastructure Layer**: Secure container configuration

### Security Components

#### 1. TLS/SSL Configuration (`middleware/security_headers.go`)

**Features:**
- Enforces TLS 1.2+ only
- Secure cipher suite selection
- HSTS headers for HTTPS enforcement
- Automatic HTTP to HTTPS redirection

**Configuration:**
```env
TLS_ENABLED=true
TLS_CERT_FILE=/path/to/cert.pem
TLS_KEY_FILE=/path/to/key.pem
```

#### 2. Security Headers Middleware

**Implemented Headers:**
- `Strict-Transport-Security`: Enforces HTTPS
- `Content-Security-Policy`: Prevents XSS attacks
- `X-Frame-Options`: Prevents clickjacking
- `X-Content-Type-Options`: Prevents MIME sniffing
- `X-XSS-Protection`: Browser XSS protection
- `Referrer-Policy`: Controls referrer information
- `Permissions-Policy`: Controls browser features

#### 3. Advanced Input Validation (`middleware/input_validation.go`)

**Features:**
- JSON structure validation with depth limits
- XSS payload detection
- SQL injection pattern detection
- Content type validation
- Request size limits
- Unicode normalization

**Configuration:**
```env
INPUT_VALIDATION_ENABLED=true
MAX_JSON_DEPTH=10
MAX_ARRAY_LENGTH=1000
MAX_STRING_LENGTH=10000
```

#### 4. Enhanced Rate Limiting (`middleware/advanced_rate_limiter.go`)

**Features:**
- IP-based rate limiting for anonymous users
- User-based rate limiting for authenticated users
- Different limits for authentication endpoints
- Automatic cleanup of old entries
- Configurable burst limits and quotas

**Configuration:**
```env
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=10
RATE_LIMIT_BURST=20
AUTH_RATE_LIMIT_REQUESTS=3
AUTH_RATE_LIMIT_BURST=5
```

#### 5. Advanced Security Middleware (`middleware/advanced_security.go`)

**Features:**
- HMAC signature validation
- Browser fingerprinting
- Timestamp validation (replay protection)
- Origin validation
- WASM/WebWorker support
- Multi-factor request validation

#### 6. Database Security (`config/database_security.go`)

**Features:**
- SSL/TLS database connections
- Connection pool security
- Audit logging for database operations
- Parameterized queries (via sqlc)

**Configuration:**
```env
DB_SSL_MODE=require
DB_SSL_CERT=/path/to/client-cert.pem
DB_SSL_KEY=/path/to/client-key.pem
DB_AUDIT_LOG_ENABLED=true
```

#### 7. Secrets Management (`security/secrets.go`)

**Features:**
- AES-256-GCM encryption for secrets
- PBKDF2 key derivation
- Automatic secret rotation (configurable)
- Secure environment variable handling

**Configuration:**
```env
MASTER_ENCRYPTION_KEY=your_32_byte_hex_key
ENCRYPTION_SALT=your_32_byte_hex_salt
SECRETS_ROTATION_ENABLED=false
```

#### 8. Security Monitoring (`security/monitoring.go`)

**Features:**
- Real-time security event logging
- Configurable alert thresholds
- Event aggregation and analysis
- Automatic incident response triggers

**Configuration:**
```env
SECURITY_MONITORING_ENABLED=true
SECURITY_ALERTS_ENABLED=true
SECURITY_LOG_LEVEL=info
```

## Security Testing

### Automated Security Tests

Run the security test suite:

```bash
chmod +x scripts/security_test.sh
./scripts/security_test.sh
```

**Tests Include:**
- Security headers validation
- Rate limiting functionality
- Input validation (XSS, SQL injection)
- Authentication controls
- HTTPS enforcement
- Information disclosure checks
- CORS configuration
- Content type validation

### Manual Security Testing

#### 1. Authentication Testing

```bash
# Test protected endpoint without authentication
curl -X GET http://localhost:8000/api/v1/users

# Should return 401 Unauthorized
```

#### 2. Rate Limiting Testing

```bash
# Test rate limiting with rapid requests
for i in {1..30}; do
  curl -X GET http://localhost:8000/api/auth/login &
done
wait

# Should receive 429 Too Many Requests
```

#### 3. Input Validation Testing

```bash
# Test XSS payload
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"<script>alert('xss')</script>","password":"test"}'

# Should return 400 Bad Request
```

## Deployment Security

### Container Security

Use the secure Dockerfile:

```dockerfile
# Copy Dockerfile.secure to Dockerfile for production
cp Dockerfile.secure Dockerfile
```

**Security Features:**
- Non-root user execution
- Distroless base image
- Minimal attack surface
- Security scanning integration

### Nginx Security

Use the enhanced Nginx configuration:

```bash
# Use the secure Nginx configuration
cp nginx.secure.conf nginx.conf
```

**Security Features:**
- Enhanced security headers
- Request filtering
- Rate limiting at proxy level
- SSL/TLS configuration
- Attack pattern detection

### Environment Security

1. **Copy security environment template:**
```bash
cp .env.security.example .env.security
```

2. **Generate encryption keys:**
```bash
# Generate master encryption key
openssl rand -hex 32

# Generate encryption salt
openssl rand -hex 32
```

3. **Configure SSL certificates:**
```bash
# Generate self-signed certificate for development
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

## Security Monitoring and Incident Response

### Log Analysis

Security events are logged in structured format:

```json
{
  "timestamp": "2024-12-15T10:30:00Z",
  "component": "security_monitor",
  "event_type": "auth_failure",
  "severity": "medium",
  "user_id": 12345,
  "ip_address": "192.168.1.100",
  "path": "/api/auth/login",
  "description": "Failed login attempt"
}
```

### Alert Configuration

Configure alert thresholds in `security/monitoring.go`:

```go
alertThresholds: map[SecurityEventType]AlertThreshold{
    EventTypeAuthFailure: {
        Count:        5,
        TimeWindow:   5 * time.Minute,
        Severity:     SeverityMedium,
    },
}
```

### Incident Response

1. **Immediate Response (Critical Events):**
   - Automatic user account lockout
   - IP blocking for suspicious activity
   - Administrative notifications

2. **Investigation:**
   - Detailed event logging
   - Request/response correlation
   - User behavior analysis

3. **Recovery:**
   - Automated recovery for benign events
   - Manual intervention for critical incidents
   - Post-incident analysis and reporting

## Security Compliance

### OWASP Top 10 Coverage

| OWASP Risk | Implementation | Status |
|------------|----------------|--------|
| A01 - Injection | Input validation, parameterized queries | ✅ |
| A02 - Broken Authentication | JWT, rate limiting, MFA | ✅ |
| A03 - Sensitive Data Exposure | TLS, encryption, secure headers | ✅ |
| A04 - XML External Entities | XML bomb protection, input validation | ✅ |
| A05 - Broken Access Control | RBAC, JWT validation | ✅ |
| A06 - Security Misconfiguration | Secure defaults, hardening | ✅ |
| A07 - XSS | Input validation, CSP headers | ✅ |
| A08 - Insecure Deserialization | JSON validation, size limits | ✅ |
| A09 - Known Vulnerabilities | Dependency scanning, updates | ⚠️ |
| A10 - Insufficient Logging | Security monitoring, audit logs | ✅ |

### Data Protection (GDPR)

- **Data encryption**: AES-256 for sensitive data
- **Access logging**: All data access logged
- **Data retention**: Configurable retention policies
- **Right to erasure**: User data deletion capabilities

## Maintenance and Updates

### Regular Security Tasks

1. **Weekly:**
   - Review security logs
   - Update dependencies
   - Check for security advisories

2. **Monthly:**
   - Rotate secrets (if enabled)
   - Security configuration review
   - Penetration testing

3. **Quarterly:**
   - Security architecture review
   - Compliance audit
   - Team security training

### Security Metrics

Monitor these key security metrics:

- Failed authentication attempts
- Rate limit violations
- Input validation failures
- Suspicious activity patterns
- Security alert response times

## Troubleshooting

### Common Issues

1. **High Rate Limit False Positives:**
   - Adjust rate limits in configuration
   - Whitelist trusted IPs
   - Implement user-based limits

2. **Input Validation Blocking Legitimate Requests:**
   - Review validation patterns
   - Adjust string length limits
   - Check JSON depth limits

3. **SSL/TLS Certificate Issues:**
   - Verify certificate validity
   - Check certificate chain
   - Validate SSL configuration

### Debug Mode

For development, you can enable debug mode:

```env
DEBUG_MODE=true
SECURITY_LOG_LEVEL=debug
```

**Warning:** Never enable debug mode in production.

## Security Contacts

- **Security Team**: security@your-domain.com
- **Incident Response**: incident@your-domain.com
- **Emergency**: +1-XXX-XXX-XXXX

---

*Last Updated: December 15, 2024*
*Version: 1.0*
