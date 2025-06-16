# 🏗️ TOEIC App Backend - System Architecture Documentation

## 🎯 Overview

The TOEIC App Backend is designed as a high-performance, scalable microservice architecture capable of supporting 1M+ concurrent users. This document outlines the system architecture, design patterns, and technical decisions.

## 🏛️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Load Balancer (Nginx)                    │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                    API Gateway Layer                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │
│  │   Auth      │ │ Rate Limit  │ │  Security   │              │
│  │ Middleware  │ │ Middleware  │ │ Middleware  │              │
│  └─────────────┘ └─────────────┘ └─────────────┘              │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                  Application Layer                              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │
│  │    Auth     │ │    Users    │ │   Admin     │              │
│  │  Service    │ │   Service   │ │  Service    │              │
│  └─────────────┘ └─────────────┘ └─────────────┘              │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                    Data Layer                                   │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │
│  │ PostgreSQL  │ │    Redis    │ │  File Store │              │
│  │ (Primary)   │ │   (Cache)   │ │ (Backups)   │              │
│  └─────────────┘ └─────────────┘ └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

## 🏗️ Layer Architecture

### 1. **Load Balancer Layer**
- **Technology**: Nginx
- **Purpose**: Traffic distribution and SSL termination
- **Features**:
  - HTTP/2 support
  - Gzip compression
  - SSL/TLS termination
  - Rate limiting
  - Static file serving

### 2. **API Gateway Layer**
- **Framework**: Gin (Go)
- **Middleware Stack**:
  - CORS handling
  - Request logging
  - Authentication verification
  - Rate limiting
  - Security headers
  - Request/Response compression

### 3. **Application Layer**
- **Architecture**: Clean Architecture with Domain-Driven Design
- **Components**:
  - **Controllers**: HTTP request handling
  - **Services**: Business logic implementation
  - **Repositories**: Data access abstraction
  - **Models**: Domain entities and DTOs

### 4. **Data Layer**
- **Primary Database**: PostgreSQL with connection pooling
- **Cache**: Redis for session and application caching
- **File Storage**: Local filesystem for backups

## 📁 Project Structure

```
backend/
├── cmd/                    # Application entry points
│   └── server/
├── internal/               # Private application code
│   ├── auth/              # Authentication logic
│   ├── config/            # Configuration management
│   ├── database/          # Database connection and migrations
│   ├── handlers/          # HTTP request handlers
│   ├── middleware/        # HTTP middleware
│   ├── models/            # Data models and DTOs
│   ├── repositories/      # Data access layer
│   ├── services/          # Business logic layer
│   ├── token/             # JWT token management
│   ├── utils/             # Utility functions
│   └── validators/        # Input validation
├── db/                    # Database files
│   ├── migrations/        # SQL migration files
│   └── queries/           # SQLC query files
├── docs/                  # API documentation
├── logs/                  # Application logs
└── backups/              # Database backups
```

## 🔄 Data Flow

### 1. **Request Flow**
```
Client Request → Nginx → Gin Router → Middleware → Controller → Service → Repository → Database
```

### 2. **Authentication Flow**
```
Login Request → Auth Controller → User Service → JWT Generation → Redis Session Storage → Response
```

### 3. **Caching Flow**
```
Request → Check Redis Cache → Cache Hit: Return Data
                           → Cache Miss: Query Database → Store in Cache → Return Data
```

## 🗄️ Database Design

### **PostgreSQL Schema**

#### Users Table
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Sessions Table (Redis Alternative)
```sql
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    refresh_token VARCHAR(500) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### **Redis Schema**

#### Cache Keys Structure
```
user:profile:{user_id}          # User profile cache
auth:blacklist:{token_hash}     # Blacklisted tokens
session:{session_id}            # User sessions
cache:query:{hash}              # Query result cache
stats:daily:{date}              # Daily statistics
```

## 🛡️ Security Architecture

### **Authentication & Authorization**
- **JWT Tokens**: Access (15 min) + Refresh (7 days)
- **Role-Based Access Control (RBAC)**
- **Token Blacklisting**: Redis-based invalidation
- **Session Management**: Multi-device support

### **Security Middleware**
```go
// Security middleware stack
router.Use(middleware.CORS())
router.Use(middleware.SecurityHeaders())
router.Use(middleware.RateLimiter())
router.Use(middleware.RequestLogger())
router.Use(middleware.Recovery())
```

### **Input Validation**
- **Custom Validators**: Email, password strength, role validation
- **SQL Injection Protection**: Parameterized queries via SQLC
- **XSS Protection**: Input sanitization
- **CSRF Protection**: Token-based validation

## 🚀 Performance Optimizations

### **Caching Strategy**
```
L1 Cache (Application Memory) → L2 Cache (Redis) → L3 Cache (Database Query Cache)
```

### **Database Optimizations**
- **Connection Pooling**: 25-50 concurrent connections
- **Query Optimization**: Indexed columns and query analysis
- **Read Replicas**: For scaling read operations
- **Prepared Statements**: Via SQLC code generation

### **Concurrency Management**
```go
// Worker pools for different operations
type WorkerPools struct {
    DatabasePool    *WorkerPool
    CachePool      *WorkerPool
    BackgroundPool *WorkerPool
}
```

## 📊 Monitoring & Observability

### **Health Checks**
- **Database**: Connection and query performance
- **Redis**: Connection and memory usage
- **Application**: Memory, CPU, and goroutine count
- **External Services**: API dependency health

### **Metrics Collection**
```go
type SystemMetrics struct {
    TotalRequests     int64
    ActiveUsers       int64
    CacheHitRate     float64
    AverageLatency   time.Duration
    ErrorRate        float64
}
```

### **Logging Strategy**
- **Structured Logging**: JSON format with correlation IDs
- **Log Levels**: DEBUG, INFO, WARN, ERROR, FATAL
- **Log Rotation**: Size and time-based rotation
- **Centralized Logging**: ELK stack ready

## 🔧 Configuration Management

### **Environment Configuration**
```go
type Config struct {
    Server   ServerConfig
    Database DatabaseConfig
    Redis    RedisConfig
    JWT      JWTConfig
    Cache    CacheConfig
}
```

### **Environment Files**
- `.env.development` - Development settings
- `.env.staging` - Staging environment
- `.env.production` - Production settings
- `.env.performance` - Performance optimization settings

## 🧪 Testing Strategy

### **Test Levels**
1. **Unit Tests**: Individual function testing
2. **Integration Tests**: Service interaction testing
3. **API Tests**: End-to-end HTTP testing
4. **Load Tests**: Performance and scalability testing

### **Test Structure**
```
tests/
├── unit/           # Unit tests
├── integration/    # Integration tests
├── api/           # API endpoint tests
└── load/          # Load testing scripts
```

## 🔄 Deployment Architecture

### **Development Environment**
```yaml
# docker-compose.yml
services:
  app:
    build: .
    ports:
      - "8000:8000"
  postgres:
    image: postgres:15
  redis:
    image: redis:7-alpine
```

### **Production Environment**
```yaml
# docker-compose.prod.yml
services:
  nginx:
    image: nginx:alpine
  app:
    image: toeic-backend:latest
    deploy:
      replicas: 3
  postgres:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
```

## 📈 Scalability Considerations

### **Horizontal Scaling**
- **Stateless Design**: No server-side session storage
- **Load Balancing**: Multiple application instances
- **Database Sharding**: For user data partitioning
- **Cache Clustering**: Redis cluster for distributed caching

### **Vertical Scaling**
- **Connection Pool Tuning**: Based on hardware capacity
- **Memory Optimization**: Efficient data structures
- **CPU Optimization**: Concurrent processing patterns

## 🔮 Future Enhancements

### **Microservices Migration**
```
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│    Auth     │ │    User     │ │   Content   │
│  Service    │ │  Service    │ │  Service    │
└─────────────┘ └─────────────┘ └─────────────┘
```

### **Event-Driven Architecture**
- **Message Queue**: RabbitMQ or Apache Kafka
- **Event Sourcing**: For audit trails
- **CQRS Pattern**: Separate read/write models

### **Advanced Caching**
- **CDN Integration**: CloudFlare or AWS CloudFront
- **Edge Caching**: Geographic distribution
- **Smart Cache Invalidation**: Event-based cache clearing

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Language** | Go 1.21+ | High-performance backend |
| **Framework** | Gin | HTTP router and middleware |
| **Database** | PostgreSQL 15 | Primary data storage |
| **Cache** | Redis 7 | Session and data caching |
| **ORM** | SQLC | Type-safe SQL queries |
| **Authentication** | JWT | Stateless authentication |
| **Documentation** | Swagger | API documentation |
| **Deployment** | Docker | Containerization |
| **Proxy** | Nginx | Load balancing and SSL |
| **Monitoring** | Prometheus | Metrics collection |

## 📖 Best Practices

### **Code Organization**
- **Clean Architecture**: Separation of concerns
- **Dependency Injection**: Testable and maintainable code
- **Interface Abstraction**: Decoupled components
- **Error Handling**: Consistent error responses

### **Performance**
- **Database Indexing**: Query optimization
- **Lazy Loading**: On-demand data fetching
- **Batch Operations**: Bulk database operations
- **Connection Reuse**: HTTP client connection pooling

### **Security**
- **Principle of Least Privilege**: Minimal access rights
- **Defense in Depth**: Multiple security layers
- **Regular Updates**: Security patch management
- **Audit Logging**: Security event tracking

---

This architecture supports the current requirements while providing a foundation for future growth and scalability to 1M+ users.
