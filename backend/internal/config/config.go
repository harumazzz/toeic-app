package config

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

// Config stores all configuration of the application.
// The values are read from environment variables or .env file.
type Config struct {
	// Database configuration
	DBDriver             string        `mapstructure:"DB_DRIVER"`
	DBSource             string        `mapstructure:"DB_SOURCE"`
	DBHost               string        `mapstructure:"DB_HOST"`
	DBPort               string        `mapstructure:"DB_PORT"`
	DBUser               string        `mapstructure:"DB_USER"`
	DBPassword           string        `mapstructure:"DB_PASSWORD"`
	DBName               string        `mapstructure:"DB_NAME"`
	ServerAddress        string        `mapstructure:"SERVER_ADDRESS"`
	TokenSymmetricKey    string        `mapstructure:"TOKEN_SYMMETRIC_KEY"`
	AccessTokenDuration  time.Duration `mapstructure:"ACCESS_TOKEN_DURATION"`
	RefreshTokenDuration int64         `mapstructure:"REFRESH_TOKEN_DURATION"`
	CloudinaryURL        string        `mapstructure:"CLOUDINARY_URL"`

	// Google AI configuration
	GoogleAIAPIKey string `mapstructure:"GOOGLE_AI_API_KEY"`

	// Rate limiting configuration
	RateLimitEnabled   bool          `mapstructure:"RATE_LIMIT_ENABLED"`
	RateLimitRequests  int           `mapstructure:"RATE_LIMIT_REQUESTS"`   // Requests per second
	RateLimitBurst     int           `mapstructure:"RATE_LIMIT_BURST"`      // Maximum burst size
	RateLimitExpiresIn time.Duration `mapstructure:"RATE_LIMIT_EXPIRES_IN"` // Expiration time for visitor entries
	// Auth rate limiting configuration (for login/register endpoints)
	AuthRateLimitEnabled  bool `mapstructure:"AUTH_RATE_LIMIT_ENABLED"`
	AuthRateLimitRequests int  `mapstructure:"AUTH_RATE_LIMIT_REQUESTS"` // Requests per second
	AuthRateLimitBurst    int  `mapstructure:"AUTH_RATE_LIMIT_BURST"`    // Maximum burst size
	// CORS configuration
	CORSAllowedOrigins string `mapstructure:"CORS_ALLOWED_ORIGINS"` // Comma-separated list of allowed origins

	// Cache configuration
	CacheEnabled    bool          `mapstructure:"CACHE_ENABLED"`
	CacheType       string        `mapstructure:"CACHE_TYPE"`        // "memory" or "redis"
	CacheDefaultTTL time.Duration `mapstructure:"CACHE_DEFAULT_TTL"` // Default TTL for cache entries
	CacheMaxEntries int           `mapstructure:"CACHE_MAX_ENTRIES"` // Max entries for memory cache
	CacheCleanupInt time.Duration `mapstructure:"CACHE_CLEANUP_INT"` // Cleanup interval for memory cache

	// Redis cache configuration
	RedisAddr     string `mapstructure:"REDIS_ADDR"`
	RedisPassword string `mapstructure:"REDIS_PASSWORD"`
	RedisDB       int    `mapstructure:"REDIS_DB"`
	RedisPoolSize int    `mapstructure:"REDIS_POOL_SIZE"`
	// HTTP cache configuration
	HTTPCacheEnabled bool          `mapstructure:"HTTP_CACHE_ENABLED"`
	HTTPCacheTTL     time.Duration `mapstructure:"HTTP_CACHE_TTL"`

	// Advanced cache configuration for 1M users scalability
	CacheShardCount         int  `mapstructure:"CACHE_SHARD_COUNT"`         // Number of Redis shards
	CacheReplication        int  `mapstructure:"CACHE_REPLICATION"`         // Replication factor
	CacheWarmingEnabled     bool `mapstructure:"CACHE_WARMING_ENABLED"`     // Enable cache warming
	CacheCompressionEnabled bool `mapstructure:"CACHE_COMPRESSION_ENABLED"` // Enable compression

	// Cache performance settings
	CacheMaxMemoryUsage int64  `mapstructure:"CACHE_MAX_MEMORY_USAGE"` // Max memory usage in bytes
	CacheEvictionPolicy string `mapstructure:"CACHE_EVICTION_POLICY"`  // "lru", "lfu", "ttl"
	CacheMetricsEnabled bool   `mapstructure:"CACHE_METRICS_ENABLED"`  // Enable metrics collection

	// Concurrency management configuration
	ConcurrencyEnabled      bool `mapstructure:"CONCURRENCY_ENABLED"`
	MaxConcurrentDBOps      int  `mapstructure:"MAX_CONCURRENT_DB_OPS"`     // Max concurrent database operations
	MaxConcurrentHTTPOps    int  `mapstructure:"MAX_CONCURRENT_HTTP_OPS"`   // Max concurrent HTTP operations
	MaxConcurrentCacheOps   int  `mapstructure:"MAX_CONCURRENT_CACHE_OPS"`  // Max concurrent cache operations
	WorkerPoolSizeDB        int  `mapstructure:"WORKER_POOL_SIZE_DB"`       // Database worker pool size
	WorkerPoolSizeHTTP      int  `mapstructure:"WORKER_POOL_SIZE_HTTP"`     // HTTP worker pool size
	WorkerPoolSizeCache     int  `mapstructure:"WORKER_POOL_SIZE_CACHE"`    // Cache worker pool size
	BackgroundWorkerCount   int  `mapstructure:"BACKGROUND_WORKER_COUNT"`   // Background processor worker count
	BackgroundQueueSize     int  `mapstructure:"BACKGROUND_QUEUE_SIZE"`     // Background processor queue size
	CircuitBreakerThreshold int  `mapstructure:"CIRCUIT_BREAKER_THRESHOLD"` // Circuit breaker failure threshold
	RequestTimeoutSeconds   int  `mapstructure:"REQUEST_TIMEOUT_SECONDS"`   // Request timeout in seconds
	HealthCheckInterval     int  `mapstructure:"HEALTH_CHECK_INTERVAL"`     // Health check interval in seconds

	// Analyze service configuration
	AnalyzeServiceEnabled bool          `mapstructure:"ANALYZE_SERVICE_ENABLED"`
	AnalyzeServiceURL     string        `mapstructure:"ANALYZE_SERVICE_URL"`
	AnalyzeServiceTimeout time.Duration `mapstructure:"ANALYZE_SERVICE_TIMEOUT"`

	// Performance settings

	// Security configuration
	TLSEnabled             bool   `mapstructure:"TLS_ENABLED"`
	TLSCertFile            string `mapstructure:"TLS_CERT_FILE"`
	TLSKeyFile             string `mapstructure:"TLS_KEY_FILE"`
	SecurityHeadersEnabled bool   `mapstructure:"SECURITY_HEADERS_ENABLED"`
	InputValidationEnabled bool   `mapstructure:"INPUT_VALIDATION_ENABLED"`

	// Database security
	DBSSLMode         string `mapstructure:"DB_SSL_MODE"`
	DBSSLCert         string `mapstructure:"DB_SSL_CERT"`
	DBSSLKey          string `mapstructure:"DB_SSL_KEY"`
	DBSSLRootCert     string `mapstructure:"DB_SSL_ROOT_CERT"`
	DBAuditLogEnabled bool   `mapstructure:"DB_AUDIT_LOG_ENABLED"`

	// Secrets management
	MasterEncryptionKey    string `mapstructure:"MASTER_ENCRYPTION_KEY"`
	EncryptionSalt         string `mapstructure:"ENCRYPTION_SALT"`
	SecretsRotationEnabled bool   `mapstructure:"SECRETS_ROTATION_ENABLED"`

	// Security monitoring
	SecurityMonitoringEnabled bool   `mapstructure:"SECURITY_MONITORING_ENABLED"`
	SecurityAlertsEnabled     bool   `mapstructure:"SECURITY_ALERTS_ENABLED"`
	SecurityLogLevel          string `mapstructure:"SECURITY_LOG_LEVEL"`
}

// LoadEnv loads environment variables from .env file
func LoadEnv() {
	err := godotenv.Load()
	if err != nil {
		log.Printf("Warning: .env file not found, using environment variables")
	}
}

// GetDBSource returns the database connection string.
func GetDBSource(host, port, user, password, dbname string) string {
	return fmt.Sprintf("postgresql://%s:%s@%s:%s/%s?sslmode=disable",
		user, password, host, port, dbname)
}

// GetEnv gets an environment variable or returns a default value
func GetEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

// GetEnvAsInt gets an environment variable as int or returns a default value
func GetEnvAsInt(key string, defaultValue int64) int64 {
	valueStr := os.Getenv(key)
	if valueStr == "" {
		return defaultValue
	}

	value, err := strconv.ParseInt(valueStr, 10, 64)
	if err != nil {
		log.Printf("Warning: could not parse %s as int: %v", key, err)
		return defaultValue
	}

	return value
}

// DefaultConfig returns configuration from environment variables
func DefaultConfig() Config {
	// Load environment variables from .env file
	LoadEnv()
	// Get database configuration
	dbDriver := GetEnv("DB_DRIVER", "postgres")
	dbHost := GetEnv("DB_HOST", "localhost")
	dbPort := GetEnv("DB_PORT", "5432")
	dbUser := GetEnv("DB_USER", "root")
	dbPassword := GetEnv("DB_PASSWORD", "password")
	dbName := GetEnv("DB_NAME", "toeic_db")
	// Get server configuration
	// Support both SERVER_ADDRESS and PORT environment variables
	// PORT takes precedence for cloud platforms like Heroku, Railway, etc.
	port := GetEnv("PORT", "")
	serverAddress := GetEnv("SERVER_ADDRESS", "")

	if port != "" {
		// If PORT is set, bind to all interfaces on that port (for cloud platforms)
		serverAddress = "0.0.0.0:" + port
	} else if serverAddress == "" {
		// Default fallback
		serverAddress = "127.0.0.1:8000"
	}

	// Get JWT configuration
	tokenKey := GetEnv("TOKEN_SYMMETRIC_KEY", "12345678901234567890123456789012")
	accessTokenDuration := time.Duration(GetEnvAsInt("ACCESS_TOKEN_DURATION", 3600)) * time.Second
	refreshTokenDuration := GetEnvAsInt("REFRESH_TOKEN_DURATION", 604800)
	// Get Cloudinary configuration
	cloudinaryURL := GetEnv("CLOUDINARY_URL", "")

	if cloudinaryURL == "" {
		log.Fatal("CLOUDINARY_URL environment variable is required")
	}

	// Get Google AI configuration
	googleAIAPIKey := GetEnv("GOOGLE_AI_API_KEY", "")

	if googleAIAPIKey == "" {
		log.Println("Warning: GOOGLE_AI_API_KEY environment variable is not set. AI features will be disabled.")
	}
	// Get rate limiting configuration
	rateLimitEnabled := GetEnv("RATE_LIMIT_ENABLED", "true") == "true"
	rateLimitRequests := int(GetEnvAsInt("RATE_LIMIT_REQUESTS", 10))                              // 10 reqs/sec by default
	rateLimitBurst := int(GetEnvAsInt("RATE_LIMIT_BURST", 20))                                    // 20 burst by default
	rateLimitExpiresIn := time.Duration(GetEnvAsInt("RATE_LIMIT_EXPIRES_IN", 3600)) * time.Second // 1 hour by default
	// Get auth rate limiting configuration
	authRateLimitEnabled := GetEnv("AUTH_RATE_LIMIT_ENABLED", "true") == "true"
	authRateLimitRequests := int(GetEnvAsInt("AUTH_RATE_LIMIT_REQUESTS", 3)) // 3 reqs/sec by default (more restricted)
	authRateLimitBurst := int(GetEnvAsInt("AUTH_RATE_LIMIT_BURST", 5))       // 5 burst by default	// Get CORS configuration
	corsAllowedOrigins := GetEnv("CORS_ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080,http://192.168.31.37:8000,flutter-app://toeic-app")

	// Get cache configuration
	cacheEnabled := GetEnv("CACHE_ENABLED", "true") == "true"
	cacheType := GetEnv("CACHE_TYPE", "memory")
	cacheDefaultTTL := time.Duration(GetEnvAsInt("CACHE_DEFAULT_TTL", 1800)) * time.Second // 30 minutes by default
	cacheMaxEntries := int(GetEnvAsInt("CACHE_MAX_ENTRIES", 10000))
	cacheCleanupInt := time.Duration(GetEnvAsInt("CACHE_CLEANUP_INT", 600)) * time.Second // 10 minutes by default

	// Get Redis configuration
	redisAddr := GetEnv("REDIS_ADDR", "localhost:6379")
	redisPassword := GetEnv("REDIS_PASSWORD", "")
	redisDB := int(GetEnvAsInt("REDIS_DB", 0))
	redisPoolSize := int(GetEnvAsInt("REDIS_POOL_SIZE", 10))
	// Get HTTP cache configuration
	httpCacheEnabled := GetEnv("HTTP_CACHE_ENABLED", "true") == "true"
	httpCacheTTL := time.Duration(GetEnvAsInt("HTTP_CACHE_TTL", 900)) * time.Second // 15 minutes by default

	// Get advanced cache configuration for 1M users scalability
	cacheShardCount := int(GetEnvAsInt("CACHE_SHARD_COUNT", 3))  // 3 Redis shards by default
	cacheReplication := int(GetEnvAsInt("CACHE_REPLICATION", 2)) // 2x replication by default
	cacheWarmingEnabled := GetEnv("CACHE_WARMING_ENABLED", "true") == "true"
	cacheCompressionEnabled := GetEnv("CACHE_COMPRESSION_ENABLED", "false") == "true"
	cacheMaxMemoryUsage := GetEnvAsInt("CACHE_MAX_MEMORY_USAGE", 256*1024*1024) // 256MB default
	cacheEvictionPolicy := GetEnv("CACHE_EVICTION_POLICY", "lru")
	cacheMetricsEnabled := GetEnv("CACHE_METRICS_ENABLED", "true") == "true"
	// Get concurrency management configuration
	concurrencyEnabled := GetEnv("CONCURRENCY_ENABLED", "true") == "true"
	maxConcurrentDBOps := int(GetEnvAsInt("MAX_CONCURRENT_DB_OPS", 100))
	maxConcurrentHTTPOps := int(GetEnvAsInt("MAX_CONCURRENT_HTTP_OPS", 200))
	maxConcurrentCacheOps := int(GetEnvAsInt("MAX_CONCURRENT_CACHE_OPS", 150))
	workerPoolSizeDB := int(GetEnvAsInt("WORKER_POOL_SIZE_DB", 20))
	workerPoolSizeHTTP := int(GetEnvAsInt("WORKER_POOL_SIZE_HTTP", 30))
	workerPoolSizeCache := int(GetEnvAsInt("WORKER_POOL_SIZE_CACHE", 25))
	backgroundWorkerCount := int(GetEnvAsInt("BACKGROUND_WORKER_COUNT", 10))
	backgroundQueueSize := int(GetEnvAsInt("BACKGROUND_QUEUE_SIZE", 1000))
	circuitBreakerThreshold := int(GetEnvAsInt("CIRCUIT_BREAKER_THRESHOLD", 10))
	requestTimeoutSeconds := int(GetEnvAsInt("REQUEST_TIMEOUT_SECONDS", 30))
	healthCheckInterval := int(GetEnvAsInt("HEALTH_CHECK_INTERVAL", 30))

	// Get analyze service configuration
	analyzeServiceEnabled := GetEnv("ANALYZE_SERVICE_ENABLED", "true") == "true"
	analyzeServiceURL := GetEnv("ANALYZE_SERVICE_URL", "http://localhost:9000")
	analyzeServiceTimeout := time.Duration(GetEnvAsInt("ANALYZE_SERVICE_TIMEOUT", 30)) * time.Second

	// Get security configuration
	tlsEnabled := GetEnv("TLS_ENABLED", "false") == "true"
	tlsCertFile := GetEnv("TLS_CERT_FILE", "")
	tlsKeyFile := GetEnv("TLS_KEY_FILE", "")
	securityHeadersEnabled := GetEnv("SECURITY_HEADERS_ENABLED", "true") == "true"
	inputValidationEnabled := GetEnv("INPUT_VALIDATION_ENABLED", "true") == "true"

	// Get database security configuration
	dbSSLMode := GetEnv("DB_SSL_MODE", "prefer")
	dbSSLCert := GetEnv("DB_SSL_CERT", "")
	dbSSLKey := GetEnv("DB_SSL_KEY", "")
	dbSSLRootCert := GetEnv("DB_SSL_ROOT_CERT", "")
	dbAuditLogEnabled := GetEnv("DB_AUDIT_LOG_ENABLED", "true") == "true"

	// Get secrets management configuration
	masterEncryptionKey := GetEnv("MASTER_ENCRYPTION_KEY", "")
	encryptionSalt := GetEnv("ENCRYPTION_SALT", "")
	secretsRotationEnabled := GetEnv("SECRETS_ROTATION_ENABLED", "false") == "true"

	// Get security monitoring configuration
	securityMonitoringEnabled := GetEnv("SECURITY_MONITORING_ENABLED", "true") == "true"
	securityAlertsEnabled := GetEnv("SECURITY_ALERTS_ENABLED", "true") == "true"
	securityLogLevel := GetEnv("SECURITY_LOG_LEVEL", "info")

	return Config{
		// Database configuration
		DBDriver:   dbDriver,
		DBSource:   GetDBSource(dbHost, dbPort, dbUser, dbPassword, dbName),
		DBHost:     dbHost,
		DBPort:     dbPort,
		DBUser:     dbUser,
		DBPassword: dbPassword,
		DBName:     dbName,

		ServerAddress:        serverAddress,
		TokenSymmetricKey:    tokenKey,
		AccessTokenDuration:  accessTokenDuration,
		RefreshTokenDuration: refreshTokenDuration,
		CloudinaryURL:        cloudinaryURL,

		// Google AI configuration
		GoogleAIAPIKey: googleAIAPIKey,

		// Rate limiting configuration
		RateLimitEnabled:   rateLimitEnabled,
		RateLimitRequests:  rateLimitRequests,
		RateLimitBurst:     rateLimitBurst,
		RateLimitExpiresIn: rateLimitExpiresIn,
		// Auth rate limiting configuration
		AuthRateLimitEnabled:  authRateLimitEnabled,
		AuthRateLimitRequests: authRateLimitRequests,
		AuthRateLimitBurst:    authRateLimitBurst,
		// CORS configuration
		CORSAllowedOrigins: corsAllowedOrigins,

		// Cache configuration
		CacheEnabled:    cacheEnabled,
		CacheType:       cacheType,
		CacheDefaultTTL: cacheDefaultTTL,
		CacheMaxEntries: cacheMaxEntries,
		CacheCleanupInt: cacheCleanupInt,

		// Redis configuration
		RedisAddr:     redisAddr,
		RedisPassword: redisPassword,
		RedisDB:       redisDB,
		RedisPoolSize: redisPoolSize,
		// HTTP cache configuration
		HTTPCacheEnabled: httpCacheEnabled,
		HTTPCacheTTL:     httpCacheTTL,

		// Advanced cache configuration for 1M users scalability
		CacheShardCount:         cacheShardCount,
		CacheReplication:        cacheReplication,
		CacheWarmingEnabled:     cacheWarmingEnabled,
		CacheCompressionEnabled: cacheCompressionEnabled,
		CacheMaxMemoryUsage:     cacheMaxMemoryUsage,
		CacheEvictionPolicy:     cacheEvictionPolicy,
		CacheMetricsEnabled:     cacheMetricsEnabled,

		// Concurrency management configuration
		ConcurrencyEnabled:      concurrencyEnabled,
		MaxConcurrentDBOps:      maxConcurrentDBOps,
		MaxConcurrentHTTPOps:    maxConcurrentHTTPOps,
		MaxConcurrentCacheOps:   maxConcurrentCacheOps,
		WorkerPoolSizeDB:        workerPoolSizeDB,
		WorkerPoolSizeHTTP:      workerPoolSizeHTTP,
		WorkerPoolSizeCache:     workerPoolSizeCache,
		BackgroundWorkerCount:   backgroundWorkerCount,
		BackgroundQueueSize:     backgroundQueueSize,
		CircuitBreakerThreshold: circuitBreakerThreshold,
		RequestTimeoutSeconds:   requestTimeoutSeconds,
		HealthCheckInterval:     healthCheckInterval,

		// Analyze service configuration
		AnalyzeServiceEnabled: analyzeServiceEnabled,
		AnalyzeServiceURL:     analyzeServiceURL,
		AnalyzeServiceTimeout: analyzeServiceTimeout,

		// Security configuration
		TLSEnabled:             tlsEnabled,
		TLSCertFile:            tlsCertFile,
		TLSKeyFile:             tlsKeyFile,
		SecurityHeadersEnabled: securityHeadersEnabled,
		InputValidationEnabled: inputValidationEnabled,

		// Database security
		DBSSLMode:         dbSSLMode,
		DBSSLCert:         dbSSLCert,
		DBSSLKey:          dbSSLKey,
		DBSSLRootCert:     dbSSLRootCert,
		DBAuditLogEnabled: dbAuditLogEnabled,

		// Secrets management
		MasterEncryptionKey:    masterEncryptionKey,
		EncryptionSalt:         encryptionSalt,
		SecretsRotationEnabled: secretsRotationEnabled,

		// Security monitoring
		SecurityMonitoringEnabled: securityMonitoringEnabled,
		SecurityAlertsEnabled:     securityAlertsEnabled,
		SecurityLogLevel:          securityLogLevel,
	}
}
