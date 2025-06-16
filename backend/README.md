# TOEIC App Backend

This is a backend service for a TOEIC application using Go, PostgreSQL, and sqlc, designed for high-performance and scalability to support 1M+ users.

## 🚀 Performance & Scalability Features

### Advanced Caching System
- **Multi-Layer Caching**: HTTP response caching, service layer caching, and distributed Redis caching
- **Horizontal Scaling**: Support for multiple Redis shards with consistent hashing
- **Cache Warming**: Preloads frequently accessed data for optimal performance  
- **Cache Compression**: Automatic compression for large cached values
- **Tag-Based Invalidation**: Advanced cache invalidation strategies

### High-Performance Architecture
- **Connection Pooling**: Auto-scaling database connection pools with circuit breakers
- **Concurrency Management**: Advanced worker pools for DB, HTTP, and cache operations
- **Background Processing**: Async task processing with configurable worker pools
- **Rate Limiting**: DDoS protection with burst support and per-user limits

### Monitoring & Observability
- **Performance Metrics**: Real-time monitoring of cache hit rates, latency, and throughput
- **Health Checks**: Comprehensive health monitoring for all system components
- **Admin Dashboard**: Advanced cache and performance management endpoints
- **Alerting**: Configurable thresholds for proactive monitoring

## Features

- RESTful API with Gin framework
- PostgreSQL database with SQLC for type-safe SQL queries
- JWT authentication with access and refresh tokens
- Swagger API documentation
- Password hashing with bcrypt
- Input validation using custom validators
- CORS support
- Health and metrics endpoints for monitoring
- Database backup and restore functionality
- **Multi-language support (i18n)** with dynamic language switching
- **Real-time upgrade notifications** via WebSocket
- **Advanced security middleware** with enhanced headers and protection

## Prerequisites

- Docker and Docker Compose
- Go 1.21 or higher
- Make (optional, for running commands from the Makefile)
- **Kubernetes cluster** (for production deployment)
- **kubectl** (for Kubernetes management)

## Setup

### Install Required Go Tools

```bash
go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest
go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
```

Or use the Makefile command:

```bash
make install-tools
```

### Start PostgreSQL

```bash
docker compose up -d
```

Or use the Makefile command:

```bash
make postgres
```

### Run Migrations

```bash
migrate -path db/migrations -database "postgresql://root:password@localhost:5432/toeic_db?sslmode=disable" -verbose up
```

Or use the Makefile command:

```bash
make migrateup
```

### Generate sqlc Code

```bash
sqlc generate
```

Or use the Makefile command:

```bash
make sqlc
```

### Generate API Documentation

```bash
swag init -g main.go -o ./docs
```

Or use the Makefile command:

```bash
make swagger
```

### Run the Application

```bash
go run main.go
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - Login with email and password
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/logout` - Logout and invalidate tokens
- `POST /api/auth/refresh-token` - Refresh access token using refresh token

### Users
- `POST /api/v1/users` - Create a new user
- `GET /api/v1/users/me` - Get current user profile (authenticated)
- `GET /api/v1/users/:id` - Get user by ID (authenticated)
- `GET /api/v1/users` - List all users (authenticated)
- `PUT /api/v1/users/:id` - Update a user (authenticated)
- `DELETE /api/v1/users/:id` - Delete a user (authenticated)

### System
- `GET /health` - Health check endpoint
- `GET /metrics` - System metrics endpoint
- `GET /swagger/*any` - Swagger API documentation

## Database Access

- PostgreSQL is available at `localhost:5432`
- Username: `root`
- Password: `password`
- Database: `toeic_db`
- Adminer (database management tool) is available at `http://localhost:8080`

## Database Backup and Restore

### Via API (Admin only)

The application provides a REST API for database backup and restore operations:

- `POST /api/v1/admin/backups` - Create a new backup
- `GET /api/v1/admin/backups` - List all backups
- `GET /api/v1/admin/backups/download/{filename}` - Download a backup
- `DELETE /api/v1/admin/backups/{filename}` - Delete a backup
- `POST /api/v1/admin/backups/restore` - Restore from a backup
- `POST /api/v1/admin/backups/upload` - Upload a backup file

These endpoints are accessible only to admin users and require authentication.

### Via Makefile

For convenience, you can use the following Makefile commands:

```bash
# Create a backup
make backup

# List all backups
make backup-list

# Restore from a backup
make restore file=backups/your_backup.sql
```

### Requirements

The backup/restore functionality requires PostgreSQL client tools (`pg_dump` and `psql`) to be installed on the server:

- For Windows: Install PostgreSQL and make sure the bin directory is in your PATH
- For Linux: `apt-get install postgresql-client`
- For macOS: `brew install postgresql`

## Docker command
- ` docker exec -it toeic_postgres psql -U root -d toeic_db`

## 📈 Scalability Configuration

### Environment Setup for 1M+ Users

Copy the scalability configuration template:

```bash
cp .env.scalability.example .env
```

### Key Configuration for High Scale

```env
# Distributed Redis Cache
CACHE_TYPE=redis
CACHE_SHARD_COUNT=5
CACHE_REPLICATION=3
CACHE_WARMING_ENABLED=true
CACHE_COMPRESSION_ENABLED=true

# High-Performance Settings
MAX_CONCURRENT_DB_OPS=200
WORKER_POOL_SIZE_DB=50
BACKGROUND_WORKER_COUNT=30
CACHE_MAX_MEMORY_USAGE=1073741824  # 1GB

# Production Deployment
SERVER_ADDRESS=0.0.0.0:8000
GIN_MODE=release
```

### Performance Targets

| Metric | Target | Configuration |
|--------|---------|---------------|
| **Concurrent Users** | 1M+ | Distributed cache + worker pools |
| **Response Time** | <100ms | Cache warming + compression |
| **Cache Hit Rate** | >95% | Multi-layer caching strategy |
| **Throughput** | 10K+ req/s | Optimized concurrency management |

### Quick Deployment

```bash
# Basic deployment (single instance)
docker-compose up -d

# High-scale deployment (with Redis cluster)
docker-compose -f docker-compose.prod.yml --profile with-redis up -d

# Full production (with Nginx + Redis)
docker-compose -f docker-compose.prod.yml --profile with-nginx up -d
```

## 🔧 Advanced Cache Management

### Admin Cache Endpoints

```bash
# Get cache statistics
GET /api/v1/admin/cache/stats

# Advanced cache metrics
GET /api/v1/admin/cache/advanced-stats

# Cache health status
GET /api/v1/admin/cache/health

# Trigger manual cache warming
POST /api/v1/admin/cache/warm

# Invalidate cache by tag
POST /api/v1/admin/cache/invalidate/tag/{tag}
```

### Cache Performance Monitoring

The system provides comprehensive cache metrics:
- Hit/miss ratios
- Memory usage and limits
- Latency statistics
- Shard distribution (distributed cache)
- Warming cycle performance

## Deployment Options

### 🚀 Kubernetes Deployment (Recommended for Production)

For production environments, deploy to Kubernetes with full monitoring, auto-scaling, and high availability:

```powershell
# Windows PowerShell
.\deploy-k8s.ps1 deploy

# Or using bash (Linux/Mac/WSL)
./deploy-k8s.sh deploy
```

**Features included:**
- ✅ Auto-scaling (3-10 replicas)
- ✅ Database persistence with backups
- ✅ Redis caching layer
- ✅ Prometheus + Grafana monitoring
- ✅ Health checks and rolling updates
- ✅ Automated daily backups
- ✅ RBAC security

**Access after deployment:**
- Backend API: `http://<node-ip>:30080`
- Prometheus: `http://<node-ip>:30090`
- Grafana: `http://<node-ip>:30030` (admin/admin123)

📖 **[Complete Kubernetes Setup Guide](k8s/README.md)**

### 🐳 Docker Compose (Development)

For local development and testing:

```bash
docker compose up -d
```

### 🏃 Local Development

For development with live reload:

## Setup