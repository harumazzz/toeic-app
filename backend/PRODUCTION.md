# Production Deployment Guide

This guide will help you deploy your TOEIC app backend to production and solve the IP/port configuration issues.

## 🎯 Quick Solutions to Your Problems

### 1. **IP/Port Configuration Issue - SOLVED!**

Instead of manually changing IP addresses, the backend now supports:

- **Environment Variable `PORT`**: Automatically binds to `0.0.0.0:$PORT`
- **Environment Variable `SERVER_ADDRESS`**: Custom address if needed
- **Cloud Platform Support**: Works with Heroku, Railway, DigitalOcean, etc.

```bash
# For cloud platforms (automatically binds to all interfaces)
PORT=8000

# For custom configuration
SERVER_ADDRESS=0.0.0.0:8000

# For local development
SERVER_ADDRESS=127.0.0.1:8000
```

### 2. **Production-Ready Setup**

The backend now includes:
- ✅ Docker containerization
- ✅ Environment-based configuration
- ✅ Health checks and monitoring
- ✅ Nginx reverse proxy
- ✅ Redis caching (optional)
- ✅ Database backups
- ✅ Graceful shutdown
- ✅ Security hardening

## 🚀 Quick Start

### 1. Setup Environment

```powershell
# Copy environment template
Copy-Item .env.example .env

# Edit the .env file with your production values
notepad .env
```

### 2. Deploy to Production

```powershell
# Check environment setup
.\deploy.ps1 check

# Deploy basic setup (app + database)
.\deploy.ps1 deploy

# Deploy with Redis cache
.\deploy.ps1 deploy-redis

# Deploy everything (app + database + redis + nginx)
.\deploy.ps1 deploy-full
```

### 3. Monitor and Manage

```powershell
# Check status
.\deploy.ps1 status

# View logs
.\deploy.ps1 logs

# Create backup
.\deploy.ps1 backup

# Restart services
.\deploy.ps1 restart
```

## 📋 Environment Variables

### Required Variables

```env
# JWT Security (CRITICAL - Generate a secure 32-character key)
TOKEN_SYMMETRIC_KEY=your_32_character_secret_key_here

# File Upload (Cloudinary)
CLOUDINARY_URL=cloudinary://api_key:api_secret@cloud_name

# Database Security
DB_PASSWORD=your_secure_database_password
```

### Server Configuration

```env
# Port binding (choose one method)
PORT=8000                           # Recommended for cloud platforms
SERVER_ADDRESS=0.0.0.0:8000        # Alternative custom binding

# Environment mode
GIN_MODE=release                    # Use 'release' for production
```

### CORS Configuration

```env
# Add your production domains
CORS_ALLOWED_ORIGINS=https://your-app.com,https://www.your-app.com,https://your-admin-panel.com
```

## 🐳 Docker Deployment Options

### Option 1: Basic Deployment

```powershell
# App + PostgreSQL database
.\deploy.ps1 deploy
```

**Includes:**
- Go backend application
- PostgreSQL database
- Health checks
- Automatic backups

### Option 2: With Redis Cache

```powershell
# App + Database + Redis
.\deploy.ps1 deploy-redis
```

**Additional features:**
- Redis caching for better performance
- Reduced database load
- Faster API responses

### Option 3: Full Production Setup

```powershell
# App + Database + Redis + Nginx
.\deploy.ps1 deploy-full
```

**Production features:**
- Nginx reverse proxy
- SSL termination ready
- Rate limiting
- Static file serving
- Load balancing ready

## 🌐 Cloud Platform Deployment

### Heroku

```bash
# Set environment variables
heroku config:set PORT=8000
heroku config:set GIN_MODE=release
heroku config:set TOKEN_SYMMETRIC_KEY=your_secret_key

# Deploy
git push heroku main
```

### Railway

```bash
# Railway automatically uses PORT environment variable
railway deploy
```

### DigitalOcean App Platform

```yaml
# app.yaml
name: toeic-backend
services:
- name: api
  source_dir: /backend
  github:
    repo: your-username/toeic-app
    branch: main
  run_command: ./main
  environment_slug: go
  instance_count: 1
  instance_size_slug: basic-xxs
  envs:
  - key: PORT
    value: "8080"
  - key: GIN_MODE
    value: "release"
```

## 🔧 Advanced Configuration

### Custom Domain with SSL

1. **Update Nginx configuration:**

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    # ... rest of configuration
}
```

2. **Deploy with SSL:**

```powershell
# Place SSL certificates in ./ssl/ directory
.\deploy.ps1 deploy-nginx
```

### Performance Tuning

```env
# Database connections
MAX_CONCURRENT_DB_OPS=100
WORKER_POOL_SIZE_DB=20

# HTTP handling
MAX_CONCURRENT_HTTP_OPS=200
WORKER_POOL_SIZE_HTTP=30

# Caching
CACHE_ENABLED=true
CACHE_TYPE=redis
CACHE_DEFAULT_TTL=1800
```

### Security Hardening

```env
# Rate limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=10
RATE_LIMIT_BURST=20

# Auth rate limiting
AUTH_RATE_LIMIT_ENABLED=true
AUTH_RATE_LIMIT_REQUESTS=3
AUTH_RATE_LIMIT_BURST=5
```

## 📊 Monitoring and Maintenance

### Health Checks

```powershell
# Check application health
Invoke-WebRequest http://localhost:8000/health

# Check metrics
Invoke-WebRequest http://localhost:8000/metrics
```

### Backup Management

```powershell
# Create manual backup
.\deploy.ps1 backup

# Restore from backup
.\deploy.ps1 restore backups/prod_backup_20250611_120000.sql

# Automatic backups are enabled by default (every 6 hours)
```

### Log Management

```powershell
# View real-time logs
.\deploy.ps1 logs

# View specific service logs
docker-compose -f docker-compose.prod.yml logs app
docker-compose -f docker-compose.prod.yml logs postgres
docker-compose -f docker-compose.prod.yml logs redis
```

## 🚨 Troubleshooting

### Common Issues

**1. Port already in use:**
```powershell
# Change port in .env file
PORT=8001
.\deploy.ps1 restart
```

**2. Database connection failed:**
```powershell
# Check database status
docker-compose -f docker-compose.prod.yml ps postgres

# View database logs
docker-compose -f docker-compose.prod.yml logs postgres
```

**3. SSL certificate issues:**
```powershell
# Generate self-signed certificate for testing
mkdir ssl
openssl req -x509 -newkey rsa:4096 -keyout ssl/key.pem -out ssl/cert.pem -days 365 -nodes
```

### Performance Issues

**1. High memory usage:**
```env
# Reduce worker pools
WORKER_POOL_SIZE_DB=10
WORKER_POOL_SIZE_HTTP=15
```

**2. Slow database queries:**
```powershell
# Enable query logging
docker-compose -f docker-compose.prod.yml exec postgres psql -U root -d toeic_db -c "ALTER SYSTEM SET log_statement = 'all';"
```

## 🔄 Updates and Migrations

### Updating the Application

```powershell
# Pull latest changes
git pull origin main

# Redeploy
.\deploy.ps1 deploy

# Run database migrations if needed
docker-compose -f docker-compose.prod.yml exec app ./main migrate
```

### Database Migrations

```powershell
# Create backup before migration
.\deploy.ps1 backup

# Run migrations
make migrateup

# If migration fails, restore backup
.\deploy.ps1 restore backups/your_backup_file.sql
```

## 📞 Support

- **Health Check Endpoint:** `GET /health`
- **Metrics Endpoint:** `GET /metrics`
- **API Documentation:** `GET /swagger/index.html`

## 🔐 Security Checklist

- [ ] Strong `TOKEN_SYMMETRIC_KEY` (32+ characters)
- [ ] Secure database password
- [ ] CORS origins configured for production domains only
- [ ] Rate limiting enabled
- [ ] SSL certificates configured
- [ ] Environment variables secured
- [ ] Regular backups scheduled
- [ ] Monitoring and alerting set up

---

**Your IP/port issue is now solved!** The backend automatically detects cloud platforms and binds to the correct interface. No more manual IP changes needed! 🎉
