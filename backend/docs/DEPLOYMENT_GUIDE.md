# 🚀 TOEIC App Backend - Deployment Guide

## 📋 Overview

This comprehensive deployment guide covers all aspects of deploying the TOEIC App Backend from development to production environments. It includes automated deployment scripts, monitoring setup, and best practices for high-availability deployments.

## 🎯 Deployment Environments

### 1. **Development Environment**
- **Purpose**: Local development and testing
- **Requirements**: Docker, Docker Compose
- **Database**: Local PostgreSQL container
- **Cache**: Local Redis container
- **SSL**: Not required

### 2. **Staging Environment**
- **Purpose**: Pre-production testing
- **Requirements**: Docker, SSL certificates
- **Database**: Managed PostgreSQL or container
- **Cache**: Redis cluster
- **SSL**: Required (Let's Encrypt or custom)

### 3. **Production Environment**
- **Purpose**: Live application serving users
- **Requirements**: High availability, monitoring, backups
- **Database**: Managed PostgreSQL with backups
- **Cache**: Redis cluster with persistence
- **SSL**: Required with proper certificates

## 🛠️ Prerequisites

### System Requirements

#### Minimum Requirements (Development)
- **CPU**: 2 cores
- **RAM**: 4GB
- **Storage**: 20GB
- **OS**: Windows 10/11, Linux, macOS

#### Recommended Requirements (Production)
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Storage**: 100GB+ SSD
- **OS**: Ubuntu 20.04+ or Windows Server 2019+

### Software Dependencies

#### Required Software
```powershell
# Windows (PowerShell)
# Docker Desktop
winget install Docker.DockerDesktop

# Git
winget install Git.Git

# Go (for building from source)
winget install GoLang.Go
```

```bash
# Linux (Ubuntu/Debian)
# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Docker Compose
sudo apt-get install docker-compose-plugin

# Git
sudo apt-get install git

# Go
sudo apt-get install golang-go
```

#### Optional Tools
- **PostgreSQL Client**: For database management
- **Redis CLI**: For cache management
- **Nginx**: For production proxy setup

## 🚀 Quick Start Deployment

### Development Environment

#### 1. Clone and Setup
```powershell
# Clone repository
git clone https://github.com/your-org/toeic-app.git
cd toeic-app/backend

# Copy environment configuration
copy .env.example .env

# Start development environment
docker-compose up -d
```

#### 2. Initialize Database
```powershell
# Run database migrations
docker-compose exec app migrate -path db/migrations -database "postgresql://root:password@postgres:5432/toeic_db?sslmode=disable" up

# Optional: Import sample data
docker-compose exec app go run cmd/seed/main.go
```

#### 3. Verify Deployment
```powershell
# Check application health
curl http://localhost:8000/health

# Access API documentation
# Open browser: http://localhost:8000/swagger/index.html
```

### Production Environment

#### 1. Prepare Environment
```powershell
# Create production directory
mkdir C:\toeic-production
cd C:\toeic-production

# Clone repository
git clone https://github.com/your-org/toeic-app.git .

# Setup production configuration
copy backend\.env.production backend\.env
```

#### 2. Configure Environment Variables
Edit `backend\.env` with production values:
```env
# Server Configuration
SERVER_ADDRESS=0.0.0.0:8000
GIN_MODE=release
TRUSTED_PROXIES=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16

# Database Configuration (Use managed database in production)
DB_HOST=your-postgres-host.com
DB_PORT=5432
DB_USER=toeic_user
DB_PASSWORD=your-secure-password
DB_NAME=toeic_production

# Redis Configuration (Use managed Redis in production)
REDIS_ADDR=your-redis-host.com:6379
REDIS_PASSWORD=your-redis-password

# JWT Configuration
TOKEN_SYMMETRIC_KEY=your-256-bit-secret-key
ACCESS_TOKEN_DURATION=15m
REFRESH_TOKEN_DURATION=168h

# Security Configuration
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
CSRF_KEY=your-32-character-csrf-key

# Performance Configuration
CACHE_ENABLED=true
CACHE_TYPE=redis
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
```

#### 3. Deploy with Automated Script
```powershell
# Run production deployment
.\backend\deploy.ps1 deploy-full
```

## 🔧 Automated Deployment Scripts

### PowerShell Deployment Script (Windows)

The `deploy.ps1` script provides comprehensive deployment automation:

```powershell
# Full deployment with all services
.\deploy.ps1 deploy-full

# Deploy only the application
.\deploy.ps1 deploy

# Deploy with Redis cache
.\deploy.ps1 deploy-redis

# Deploy with Nginx proxy
.\deploy.ps1 deploy-nginx

# Check deployment status
.\deploy.ps1 status

# View application logs
.\deploy.ps1 logs

# Create database backup
.\deploy.ps1 backup

# Restore from backup
.\deploy.ps1 restore backup-file.sql

# Stop all services
.\deploy.ps1 stop

# Restart all services
.\deploy.ps1 restart
```

### Enhanced Deployment Features

#### Performance Optimization Deployment
```powershell
# Deploy with Week 3 performance optimizations
.\deploy_performance_week3.ps1

# Force deployment (skip confirmations)
.\deploy_performance_week3.ps1 -Force

# Skip backup during deployment
.\deploy_performance_week3.ps1 -SkipBackup
```

#### Zero-Downtime Deployment
```powershell
# Blue-green deployment script
.\deploy-zero-downtime.ps1

# Canary deployment (gradual rollout)
.\deploy-canary.ps1 -Percentage 10
```

## 🐳 Docker Deployment

### Development Deployment

#### docker-compose.yml
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - GIN_MODE=debug
    volumes:
      - .:/app
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: root
      POSTGRES_PASSWORD: password
      POSTGRES_DB: toeic_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes

volumes:
  postgres_data:
```

### Production Deployment

#### docker-compose.prod.yml
```yaml
version: '3.8'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app

  app:
    image: toeic-backend:latest
    environment:
      - GIN_MODE=release
    env_file:
      - .env
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 1G

volumes:
  postgres_data:
  redis_data:
```

## 🌐 Nginx Configuration

### Production Nginx Setup

#### nginx.conf
```nginx
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server app:8000;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

    server {
        listen 80;
        server_name yourdomain.com www.yourdomain.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name yourdomain.com www.yourdomain.com;

        # SSL Configuration
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;

        # Security Headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options DENY always;
        add_header X-Content-Type-Options nosniff always;

        # Gzip Compression
        gzip on;
        gzip_types text/plain application/json application/javascript text/css;

        location / {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check endpoint (no rate limiting)
        location /health {
            proxy_pass http://backend;
            access_log off;
        }
    }
}
```

## 📊 Monitoring Setup

### Application Monitoring

#### Health Check Endpoint
```go
// Integrated health check with detailed status
GET /health
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2025-06-15T12:00:00Z",
  "services": {
    "database": "healthy",
    "redis": "healthy",
    "cache": "healthy"
  },
  "performance": {
    "uptime": 3600,
    "memory_usage": 67.8,
    "goroutines": 150
  }
}
```

#### Metrics Collection
```go
// Prometheus-compatible metrics endpoint
GET /metrics
# HELP toeic_requests_total Total number of requests
# TYPE toeic_requests_total counter
toeic_requests_total{method="GET",endpoint="/api/v1/users"} 1000

# HELP toeic_request_duration_seconds Request duration
# TYPE toeic_request_duration_seconds histogram
toeic_request_duration_seconds_bucket{le="0.1"} 900
```

### External Monitoring

#### Docker Health Checks
```dockerfile
FROM golang:1.21-alpine AS builder
# ... build steps ...

FROM alpine:latest
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1
```

#### Production Monitoring Stack
```yaml
# monitoring/docker-compose.monitoring.yml
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana

  alertmanager:
    image: prom/alertmanager
    ports:
      - "9093:9093"
```

## 🔐 Security Deployment

### SSL/TLS Certificate Setup

#### Let's Encrypt (Free SSL)
```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Auto-renewal setup
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

#### Manual Certificate Installation
```powershell
# Windows - Copy certificates to ssl directory
mkdir ssl
copy your-certificate.crt ssl\cert.pem
copy your-private-key.key ssl\key.pem
```

### Environment Security

#### Secrets Management
```powershell
# Use environment variables for secrets
[Environment]::SetEnvironmentVariable("DB_PASSWORD", "your-secure-password", "Machine")
[Environment]::SetEnvironmentVariable("JWT_SECRET", "your-jwt-secret", "Machine")
```

#### Firewall Configuration
```powershell
# Windows Firewall
New-NetFirewallRule -DisplayName "TOEIC App HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "TOEIC App HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

# Block direct access to application port
New-NetFirewallRule -DisplayName "Block Direct App Access" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Block
```

## 🔄 Backup and Recovery

### Automated Backup System

#### Database Backup Strategy
```powershell
# Automated daily backups
$backupScript = @"
# Create timestamped backup
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "backups/auto_backup_$timestamp.sql"

# Create backup using pg_dump
docker-compose exec -T postgres pg_dump -U root -d toeic_db > $backupFile

# Compress backup
gzip $backupFile

# Remove backups older than 30 days
Get-ChildItem backups/ -Name "auto_backup_*.sql.gz" | 
Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | 
Remove-Item
"@

# Schedule backup task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-Command $backupScript"
$trigger = New-ScheduledTaskTrigger -Daily -At "2:00AM"
Register-ScheduledTask -TaskName "TOEIC-Daily-Backup" -Action $action -Trigger $trigger
```

#### Recovery Procedures
```powershell
# Restore from backup
.\deploy.ps1 restore backups/backup_20250615_120000.sql

# Point-in-time recovery
.\scripts\restore-point-in-time.ps1 -Date "2025-06-15 12:00:00"
```

## 🚦 Deployment Verification

### Post-Deployment Checks

#### 1. Service Health Verification
```powershell
# Check all services are running
docker-compose ps

# Verify application health
curl http://localhost:8000/health

# Test database connectivity
curl http://localhost:8000/api/v1/users/me -H "Authorization: Bearer test-token"
```

#### 2. Performance Verification
```powershell
# Load testing with curl
for ($i = 1; $i -le 100; $i++) {
    curl http://localhost:8000/health
}

# Check response times
Measure-Command { curl http://localhost:8000/api/v1/users }
```

#### 3. Security Verification
```powershell
# SSL certificate check
curl -I https://yourdomain.com

# Security headers check
curl -I https://yourdomain.com | findstr "Strict-Transport-Security"
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Application Won't Start
```powershell
# Check logs
docker-compose logs app

# Common fixes
# - Verify environment variables
# - Check database connectivity
# - Ensure Redis is accessible
# - Verify file permissions
```

#### 2. Database Connection Issues
```powershell
# Test database connection
docker-compose exec postgres psql -U root -d toeic_db

# Common fixes
# - Check connection string format
# - Verify credentials
# - Ensure PostgreSQL is running
# - Check network connectivity
```

#### 3. Performance Issues
```powershell
# Check resource usage
docker stats

# Monitor cache performance
curl http://localhost:8000/api/v1/admin/cache/stats

# Common fixes
# - Increase memory limits
# - Enable Redis caching
# - Check database indexes
# - Review slow query logs
```

### Rollback Procedures

#### Quick Rollback
```powershell
# Rollback to previous version
git checkout HEAD~1
.\deploy.ps1 deploy-full

# Restore database if needed
.\deploy.ps1 restore backups/pre-deployment-backup.sql
```

#### Blue-Green Rollback
```powershell
# Switch traffic back to previous version
.\deploy-blue-green.ps1 -Action switchback
```

## 📈 Performance Tuning

### Production Optimization

#### Docker Resource Limits
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
```

#### Database Performance
```sql
-- Production PostgreSQL settings
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
SELECT pg_reload_conf();
```

#### Cache Optimization
```env
# Redis performance settings
REDIS_MAX_MEMORY=1gb
REDIS_MAX_MEMORY_POLICY=allkeys-lru
REDIS_SAVE_FREQUENCY=900
```

## 📚 Additional Resources

### Documentation Links
- [API Documentation](./API_DOCUMENTATION.md)
- [Architecture Guide](./ARCHITECTURE.md)
- [Security Guide](./SECURITY_GUIDE.md)
- [Performance Assessment](./PERFORMANCE_ASSESSMENT.md)

### External Resources
- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Nginx Documentation](https://nginx.org/en/docs/)

### Support
- **Issue Tracking**: GitHub Issues
- **Documentation**: Wiki pages
- **Community**: Discord/Slack channel
- **Emergency Contact**: ops@yourdomain.com

---

This deployment guide ensures reliable, secure, and scalable deployment of the TOEIC App Backend across all environments.
