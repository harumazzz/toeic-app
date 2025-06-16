package api

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"github.com/toeic-app/internal/analyze"
	"github.com/toeic-app/internal/backup"
	"github.com/toeic-app/internal/cache"
	configPkg "github.com/toeic-app/internal/config"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/errors"
	"github.com/toeic-app/internal/i18n"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/middleware"
	"github.com/toeic-app/internal/monitoring"
	"github.com/toeic-app/internal/notification"
	"github.com/toeic-app/internal/performance"
	"github.com/toeic-app/internal/rbac"
	"github.com/toeic-app/internal/scheduler"
	"github.com/toeic-app/internal/token"
	"github.com/toeic-app/internal/upgrade"
	"github.com/toeic-app/internal/uploader"
	"github.com/toeic-app/internal/websocket"
)

// @BasePath /api/v1
// @Schemes http https
// @SecurityDefinitions.apikey ApiKeyAuth
// @In header
// @Name Authorization

// Server serves HTTP requests for our banking service.
type Server struct {
	config                  configPkg.Config
	store                   db.Querier
	tokenMaker              token.Maker
	router                  *gin.Engine
	uploader                *uploader.CloudinaryUploader
	rateLimiter             *middleware.AdvancedRateLimit      // Store the rate limiter instance
	httpServer              *http.Server                       // Store the HTTP server instance
	backupScheduler         *scheduler.BackupScheduler         // Automated backup scheduler
	enhancedBackupScheduler *scheduler.EnhancedBackupScheduler // Enhanced backup scheduler
	backupManager           *backup.BackupManager              // Enhanced backup manager
	notificationManager     *notification.NotificationManager  // Notification manager for backup events
	cache                   cache.Cache                        // Cache instance
	serviceCache            *cache.ServiceCache                // Service layer cache
	httpCache               *cache.HTTPCacheMiddleware         // HTTP cache middleware
	objectPool              *performance.ObjectPool            // Object pool for memory optimization
	responseOptimizer       *performance.ResponseOptimizer     // Response optimization
	backgroundProcessor     *performance.BackgroundProcessor   // Background task processor

	// Enhanced concurrency management
	concurrencyManager *performance.ConcurrencyManager      // Advanced concurrency management
	poolManager        *performance.ConnectionPoolManager   // Database connection pool management
	concurrentHandler  *middleware.ConcurrentRequestHandler // Concurrent request handling

	// Analyze service
	analyzeService *analyze.Service // Text analysis service for writing enhancement

	// Real-time upgrade notifications
	wsManager      *websocket.Manager // WebSocket manager for real-time connections
	upgradeService *upgrade.Service   // Upgrade notification service

	// Cache management components
	cacheManager     *cache.CacheManager     // Advanced cache coordinator
	distributedCache *cache.DistributedCache // Distributed cache for horizontal scaling
	cacheWarmer      *cache.CacheWarmer      // Cache warming system

	// RBAC system
	rbacService    *rbac.Service              // Role-based access control service
	rbacMiddleware *middleware.RBACMiddleware // RBAC middleware

	// Error metrics for monitoring
	errorMetrics *errors.ErrorMetrics // Error metrics for monitoring

	// Enhanced monitoring system (Week 4: Advanced Monitoring)
	monitoringService *monitoring.AdvancedMonitoringService // Advanced monitoring service with Week 4 features
}

// NewServer creates a new HTTP server and setup routing.
func NewServer(config configPkg.Config, store db.Querier, dbConn *sql.DB) (*Server, error) {
	tokenMaker, err := token.NewJWTMaker(config.TokenSymmetricKey)
	if err != nil {
		return nil, err
	}
	cloudinaryUploader, err := uploader.NewCloudinaryUploader(config)
	if err != nil {
		return nil, err
	}

	// Initialize cache if enabled
	var cacheInstance cache.Cache
	var serviceCache *cache.ServiceCache
	var httpCache *cache.HTTPCacheMiddleware
	var cacheManager *cache.CacheManager
	var distributedCache *cache.DistributedCache
	var cacheWarmer *cache.CacheWarmer

	if config.CacheEnabled {
		logger.Info("Initializing advanced caching system for 1M user scalability...")

		// Setup cache configuration
		cacheConfig := cache.CacheConfig{
			Type:            config.CacheType,
			MaxEntries:      config.CacheMaxEntries,
			DefaultTTL:      config.CacheDefaultTTL,
			CleanupInterval: config.CacheCleanupInt,
			RedisAddr:       config.RedisAddr,
			RedisPassword:   config.RedisPassword,
			RedisDB:         config.RedisDB,
			RedisPoolSize:   config.RedisPoolSize,
			KeyPrefix:       "toeic:",
		}

		// Initialize primary cache
		cacheInstance, err = cache.NewCache(cacheConfig)
		if err != nil {
			logger.Warn("Failed to initialize primary cache: %v. Continuing without cache.", err)
		} else {
			// Initialize service cache
			serviceCache = cache.NewServiceCache(cacheInstance)

			// Initialize HTTP cache if enabled
			if config.HTTPCacheEnabled {
				httpCacheConfig := cache.DefaultHTTPCacheConfig()
				httpCacheConfig.DefaultTTL = config.HTTPCacheTTL
				httpCache = cache.NewHTTPCacheMiddleware(cacheInstance, httpCacheConfig)
			}

			// Initialize distributed cache for high scalability
			if config.CacheType == "redis" && config.CacheShardCount > 1 {
				logger.Info("Setting up distributed Redis cache with %d shards", config.CacheShardCount)

				shardConfigs := make([]cache.CacheConfig, config.CacheShardCount)
				for i := 0; i < config.CacheShardCount; i++ {
					shardConfig := cacheConfig
					// Distribute across multiple Redis instances (would need multiple Redis addresses in production)
					shardConfig.RedisDB = config.RedisDB + i
					shardConfig.KeyPrefix = fmt.Sprintf("toeic:shard%d:", i)
					shardConfigs[i] = shardConfig
				}

				distributedConfig := cache.DistributedCacheConfig{
					ShardConfigs:        shardConfigs,
					HealthCheckInterval: 30 * time.Second,
					FallbackEnabled:     true,
					ConsistentHashing:   true,
					ReplicationFactor:   config.CacheReplication,
				}

				distributedCache, err = cache.NewDistributedCache(distributedConfig)
				if err != nil {
					logger.Warn("Failed to initialize distributed cache: %v. Using single cache instance.", err)
				} else {
					logger.Info("Distributed cache initialized successfully")
				}
			}

			// Initialize cache warmer for preloading data
			if config.CacheWarmingEnabled {
				warmerConfig := cache.DefaultCacheWarmerConfig()
				cacheWarmer = cache.NewCacheWarmer(cacheInstance, store, warmerConfig)
				logger.Info("Cache warmer initialized")
			}

			// Initialize cache manager to coordinate everything
			managerConfig := cache.DefaultCacheManagerConfig()
			managerConfig.EnableDistributed = distributedCache != nil
			managerConfig.EnableWarming = cacheWarmer != nil
			managerConfig.CompressionEnabled = config.CacheCompressionEnabled
			managerConfig.MetricsEnabled = config.CacheMetricsEnabled
			managerConfig.MaxMemoryUsage = config.CacheMaxMemoryUsage

			cacheManager = cache.NewCacheManager(cacheInstance, managerConfig)
			if distributedCache != nil {
				cacheManager.SetDistributedCache(distributedCache)
			}
			if cacheWarmer != nil {
				cacheManager.SetWarmer(cacheWarmer)
			}

			logger.Info("Advanced cache system initialized: type=%s, shards=%d, warming=%v, compression=%v",
				config.CacheType, config.CacheShardCount, config.CacheWarmingEnabled, config.CacheCompressionEnabled)
		}
	}

	// Initialize WebSocket manager and upgrade service
	wsManager := websocket.NewManager()
	upgradeService := upgrade.NewService(wsManager)

	// Initialize analyze service if enabled
	var analyzeService *analyze.Service
	if config.AnalyzeServiceEnabled {
		logger.Info("Initializing analyze service...")
		analyzeService = analyze.NewService(config)
		logger.Info("Analyze service initialized with URL: %s", config.AnalyzeServiceURL)
	} else {
		logger.Info("Analyze service disabled")
	}
	// Initialize the server
	server := &Server{
		config:              config,
		store:               store,
		tokenMaker:          tokenMaker,
		uploader:            cloudinaryUploader,
		cache:               cacheInstance,
		serviceCache:        serviceCache,
		httpCache:           httpCache,
		objectPool:          performance.NewObjectPool(),
		responseOptimizer:   performance.NewResponseOptimizer(),
		backgroundProcessor: performance.NewBackgroundProcessor(config.BackgroundWorkerCount, config.BackgroundQueueSize),
		analyzeService:      analyzeService,
		wsManager:           wsManager,
		upgradeService:      upgradeService,
		cacheManager:        cacheManager,     // Add cache manager
		distributedCache:    distributedCache, // Add distributed cache
		cacheWarmer:         cacheWarmer,      // Add cache warmer
	}

	// Initialize RBAC system
	server.rbacService = rbac.NewService(store)
	server.rbacMiddleware = middleware.NewRBACMiddleware(server.rbacService)

	logger.Info("Performance optimizations initialized: Object Pool, Response Optimizer, Background Processor")
	logger.Info("WebSocket manager and upgrade service initialized")
	logger.Info("RBAC system initialized")

	// Start WebSocket manager
	wsManager.Start()

	// Initialize concurrency management components if enabled
	if config.ConcurrencyEnabled {
		logger.Info("Initializing concurrency management components...")

		// Initialize concurrency manager
		concurrencyConfig := performance.ConcurrencyConfig{
			MaxDBWorkers:          config.WorkerPoolSizeDB,
			MaxHTTPWorkers:        config.WorkerPoolSizeHTTP,
			MaxCacheWorkers:       config.WorkerPoolSizeCache,
			DBSemaphoreSize:       config.MaxConcurrentDBOps,
			HTTPSemaphoreSize:     config.MaxConcurrentHTTPOps,
			CacheSemaphoreSize:    config.MaxConcurrentCacheOps,
			MonitoringInterval:    time.Duration(config.HealthCheckInterval) * time.Second,
			MetricRetentionPeriod: 24 * time.Hour,
		}
		server.concurrencyManager = performance.NewConcurrencyManager(dbConn, concurrencyConfig)

		// Initialize connection pool manager
		poolConfig := performance.ConnectionPoolConfig{
			InitialMaxOpen:     config.MaxConcurrentDBOps,
			InitialMaxIdle:     config.MaxConcurrentDBOps / 4,
			MinMaxOpen:         10,
			MaxMaxOpen:         config.MaxConcurrentDBOps * 2,
			ScaleUpThreshold:   0.8,
			ScaleDownThreshold: 0.3,
			ScaleStep:          5,
			MonitorInterval:    time.Duration(config.HealthCheckInterval) * time.Second,
			StatsRetention:     24 * time.Hour,
		}
		server.poolManager = performance.NewConnectionPoolManager(dbConn, poolConfig)

		// Initialize concurrent request handler
		handlerConfig := middleware.ConcurrentHandlerConfig{
			MaxConcurrentRequests:   int64(config.MaxConcurrentHTTPOps),
			DegradationThreshold:    int64(float64(config.MaxConcurrentHTTPOps) * 0.8),
			CircuitBreakerThreshold: config.CircuitBreakerThreshold,
			CircuitBreakerTimeout:   5 * time.Minute,
			HealthCheckInterval:     time.Duration(config.HealthCheckInterval) * time.Second,
			RequestTimeout:          time.Duration(config.RequestTimeoutSeconds) * time.Second,
			SlowRequestThreshold:    time.Duration(config.RequestTimeoutSeconds/2) * time.Second,
		}
		server.concurrentHandler = middleware.NewConcurrentRequestHandler(handlerConfig)

		logger.Info("Concurrency management components initialized successfully")
	}

	// Initialize rate limiter if enabled
	if config.RateLimitEnabled {
		server.rateLimiter = middleware.NewAdvancedRateLimit(config, tokenMaker)
		logger.Info("Rate limiting initialized with %d requests/sec, %d burst",
			config.RateLimitRequests, config.RateLimitBurst)
	}

	// Initialize monitoring service (Week 4: Advanced Monitoring)
	logger.Info("Initializing advanced monitoring system...")
	advancedMonitoringConfig := monitoring.DefaultAdvancedMonitoringConfig()

	// Configure external services to monitor if analyze service is enabled
	if config.AnalyzeServiceEnabled {
		// Note: Advanced monitoring will inherit basic monitoring external services
		// through the base MonitoringService configuration
	}

	server.monitoringService = monitoring.NewAdvancedMonitoringService(dbConn, cacheInstance, config, advancedMonitoringConfig)
	logger.Info("Advanced monitoring system initialized with Week 4 features: SLA monitoring, anomaly detection, capacity planning, business analytics, security monitoring, and performance optimization")

	// Initialize enhanced backup system
	logger.Info("Initializing enhanced backup system...")

	// Load backup configuration
	backupConfig := configPkg.LoadBackupConfig()

	// Initialize notification manager for backup events
	server.notificationManager = notification.NewNotificationManager(backupConfig)

	// Initialize enhanced backup manager
	server.backupManager = backup.NewBackupManager(backupConfig, config)

	// Initialize enhanced backup scheduler
	server.enhancedBackupScheduler = scheduler.NewEnhancedBackupScheduler(backupConfig, config)

	logger.Info("Enhanced backup system initialized successfully")

	// Setup routes
	server.setupRouter()
	return server, nil
}

// @Summary Upload an image file
// @Description Uploads an image file to Cloudinary and returns the URL.
// @Tags Uploads
// @Accept multipart/form-data
// @Produce json
// @Param file formData file true "Image file to upload"
// @Success 200 {object} object{url=string} "Successfully uploaded image"
// @Failure 400 {object} Response "Bad Request - File not found or invalid"
// @Failure 500 {object} Response "Internal Server Error - Error opening or uploading file"
// @Router /upload [post]
func (server *Server) uploadFile(ctx *gin.Context) {
	file, err := ctx.FormFile("file")
	if err != nil {
		logger.Error("Error getting file from form: %v", err)
		ErrorResponse(ctx, http.StatusBadRequest, "File not found in form data", err)
		return
	}

	// TODO: consider generating a more unique filename or using a folder structure
	// For now, using the original filename.
	// Be cautious about security implications if filenames are user-controlled and not sanitized.
	filename := file.Filename

	src, err := file.Open()
	if err != nil {
		logger.Error("Error opening uploaded file: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Error opening uploaded file", err)
		return
	}
	defer src.Close()

	imageURL, err := server.uploader.UploadImage(ctx.Request.Context(), src, filename)
	if err != nil {
		logger.Error("Error uploading image to cloudinary: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Error uploading image to cloudinary", err)
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"url": imageURL})
}

// @Summary Upload an audio file
// @Description Uploads an audio file to Cloudinary and returns the URL.
// @Tags Uploads
// @Accept multipart/form-data
// @Produce json
// @Param file formData file true "Audio file to upload"
// @Success 200 {object} object{url=string} "Successfully uploaded audio"
// @Failure 400 {object} Response "Bad Request - File not found or invalid"
// @Failure 500 {object} Response "Internal Server Error - Error opening or uploading file"
// @Router /upload-audio [post]
func (server *Server) uploadAudioFile(ctx *gin.Context) {
	file, err := ctx.FormFile("file")
	if err != nil {
		logger.Error("Error getting file from form: %v", err)
		ErrorResponse(ctx, http.StatusBadRequest, "File not found in form data", err)
		return
	}

	filename := file.Filename

	src, err := file.Open()
	if err != nil {
		logger.Error("Error opening uploaded file: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Error opening uploaded file", err)
		return
	}
	defer src.Close()

	audioURL, err := server.uploader.UploadAudio(ctx.Request.Context(), src, filename)
	if err != nil {
		logger.Error("Error uploading audio to cloudinary: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Error uploading audio to cloudinary", err)
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"url": audioURL})
}

func (server *Server) setupRouter() {
	router := gin.New() // Create a new clean router without default middleware

	// Initialize error metrics for monitoring
	errorMetrics := errors.NewErrorMetrics()

	// Enhanced error handling configuration
	errorConfig := middleware.DefaultErrorHandlerConfig()

	// Apply enhanced recovery middleware instead of default gin.Recovery()
	router.Use(middleware.Recovery(errorConfig, errorMetrics))

	// Apply error handling middleware
	router.Use(middleware.ErrorHandler(errorConfig, errorMetrics))

	// Store error metrics in server for access from handlers
	server.errorMetrics = errorMetrics

	// Apply other middleware
	router.Use(middleware.Logger())            // Our custom logger
	router.Use(middleware.CORS(server.config)) // Enable CORS with config

	// Apply monitoring middleware if enabled
	if server.monitoringService != nil && server.monitoringService.GetMonitor() != nil {
		router.Use(server.monitoringService.GetMonitor().Middleware())
		logger.Info("Monitoring middleware enabled - collecting request metrics")
	}

	// Apply i18n middleware for language detection and setting
	router.Use(i18n.LanguageMiddleware())
	logger.Info("I18n middleware enabled - supporting multiple languages")

	// Apply rate limiting middleware based on config
	if server.config.RateLimitEnabled && server.rateLimiter != nil {
		logger.Info("Enabling rate limiting with %d requests/sec, %d burst",
			server.config.RateLimitRequests, server.config.RateLimitBurst)

		// Use the rate limiter that was already initialized in NewServer
		router.Use(server.rateLimiter.Middleware())
	}
	// Apply HTTP cache middleware if enabled
	if server.config.HTTPCacheEnabled && server.httpCache != nil {
		logger.Info("Enabling HTTP cache with TTL: %v", server.config.HTTPCacheTTL)
		router.Use(server.httpCache.Middleware())
	} // Apply advanced security middleware for enhanced protection beyond JWT
	advancedSecurity := middleware.NewAdvancedSecurityMiddleware(server.config, server.tokenMaker)
	router.Use(advancedSecurity.Middleware())
	logger.Info("Advanced security middleware enabled - additional headers required for authentication")

	// Apply enhanced security headers middleware
	router.Use(middleware.SecurityHeaders(server.config))
	logger.Info("Enhanced security headers middleware enabled")

	// Apply HTTPS redirect in production
	router.Use(middleware.HTTPSRedirect(server.config))
	logger.Info("HTTPS redirect middleware enabled for production")

	// Apply request size limits
	router.Use(middleware.RequestSizeLimit(10 * 1024 * 1024)) // 10MB limit
	logger.Info("Request size limiting enabled (10MB)")

	// Apply enhanced input validation
	inputConfig := middleware.DefaultInputValidationConfig()
	router.Use(middleware.EnhancedInputValidation(inputConfig))
	logger.Info("Enhanced input validation middleware enabled")

	// Apply XML bomb protection
	router.Use(middleware.XMLBombProtection(10, 5))
	logger.Info("XML bomb protection middleware enabled")

	// Health check and metrics routes
	router.GET("/health", server.healthCheck)
	router.GET("/metrics", server.getMetrics)

	// Enhanced monitoring endpoints
	if server.monitoringService != nil {
		// Prometheus metrics endpoint
		if server.monitoringService.GetMonitor() != nil {
			router.GET("/prometheus", server.monitoringService.GetMonitor().GetPrometheusMetrics())
		}

		// Enhanced health endpoints
		if server.monitoringService.GetHealthService() != nil {
			router.GET("/health/detailed", server.monitoringService.GetHealthService().GetHealthHandler())
			router.GET("/health/live", server.monitoringService.GetHealthService().GetLivenessHandler())
			router.GET("/health/ready", server.monitoringService.GetHealthService().GetReadinessHandler())
		}

		// Alert endpoints
		if server.monitoringService.GetAlertManager() != nil {
			router.GET("/alerts", server.getActiveAlerts)
			router.GET("/alerts/history", server.getAlertHistory)
		}

		// Advanced monitoring endpoints (Week 4)
		monitoringGroup := router.Group("/api")
		server.monitoringService.RegisterAdvancedRoutes(monitoringGroup)

		// Monitoring status endpoint
		router.GET("/monitoring/status", server.getMonitoringStatus)
	}

	// Authentication routes
	authGroup := router.Group("/api/auth")
	{
		authGroup.POST("/login", server.loginUser)
		authGroup.POST("/register", server.registerUser)
		authGroup.POST("/refresh-token", server.refreshToken)
		authGroup.POST("/logout", server.logoutUser)
	}

	// API v1 group
	v1 := router.Group("/api/v1")
	{
		// Public routes
		v1.POST("/users", server.createUser)
		v1.POST("/upload", server.uploadFile)
		v1.POST("/upload-audio", server.uploadAudioFile)
		// Grammar routes (publicly accessible for now, consider auth later if needed)
		grammarsPublic := v1.Group("/grammars")
		{
			grammarsPublic.GET("", server.listGrammars)
			grammarsPublic.GET("/:id", server.getGrammar)
			grammarsPublic.GET("/random", server.getRandomGrammar)
			grammarsPublic.GET("/level", server.listGrammarsByLevel)
			grammarsPublic.GET("/tag", server.listGrammarsByTag)
			grammarsPublic.GET("/search", server.searchGrammars)
			grammarsPublic.POST("/batch", server.batchGetGrammars)
		}

		// Performance monitoring routes (publicly accessible)
		performance := v1.Group("/performance")
		{
			performance.GET("/stats", server.getPerformanceStats)
			performance.GET("/search-test", server.searchPerformanceTest)
			performance.GET("/concurrency", server.getConcurrencyMetrics)
			performance.GET("/concurrency/health", server.getConcurrencyHealth)
		}
		// Upgrade notification routes (publicly accessible)
		upgrade := v1.Group("/upgrade")
		{
			upgrade.POST("/check", server.checkForUpdates)       // Check for updates
			upgrade.GET("/current", server.getCurrentVersion)    // Get current version
			upgrade.GET("/versions", server.getAllVersions)      // Get all versions
			upgrade.GET("/versions/:version", server.getVersion) // Get specific version
			upgrade.GET("/ws/status", server.getWebSocketStatus) // WebSocket status
		}
		// I18n routes (publicly accessible)
		i18nRoutes := v1.Group("/i18n")
		{
			i18nRoutes.GET("/languages", server.getLanguages)     // Get supported languages
			i18nRoutes.GET("/current", server.getCurrentLanguage) // Get current language
			i18nRoutes.GET("/stats", server.getI18nStats)         // Get i18n statistics
			i18nRoutes.GET("/translate", server.testTranslation)  // Test translation
		}

		// Protected routes requiring authentication
		authRoutes := v1.Group("/")
		authRoutes.Use(server.authMiddleware())
		{ // RBAC management routes
			rbacRoutes := authRoutes.Group("/rbac")
			rbacRoutes.Use(server.rbacMiddleware.RequirePermission("rbac", "manage"))
			{
				// Role management
				roles := rbacRoutes.Group("/roles")
				{
					roles.POST("", server.createRole)
					roles.GET("", server.listRoles)
					roles.GET("/:id", server.getRole)
					roles.PUT("/:id", server.updateRole)
					roles.DELETE("/:id", server.deleteRole)
					roles.POST("/:id/permissions", server.assignPermissionToRole)
					roles.DELETE("/:id/permissions/:permission_id", server.removePermissionFromRole)
				} // User role management
				userRoles := rbacRoutes.Group("/user-roles")
				{
					userRoles.POST("", server.assignRole)
					userRoles.DELETE("/:user_id/:role_id", server.removeRole)
					userRoles.GET("/user/:user_id", server.getUserRoles)
					userRoles.GET("/role/:role_id", server.getUsersByRole)
				}

				// Permission checking
				permissions := rbacRoutes.Group("/permissions")
				{
					permissions.GET("", server.listPermissions)
					permissions.POST("/check", server.checkPermission)
					permissions.GET("/user/:user_id", server.getUserPermissions)
				}
			}

			// Admin routes for database management
			adminRoutes := authRoutes.Group("/admin")
			adminRoutes.Use(server.rbacMiddleware.RequirePermission("admin", "access"))
			{
				backups := adminRoutes.Group("/backups")
				{
					// Legacy backup routes
					backups.POST("", server.createBackup)                     // Create a new backup
					backups.GET("", server.listBackups)                       // List all backups
					backups.GET("/download/:filename", server.downloadBackup) // Download a backup
					backups.DELETE("/:filename", server.deleteBackup)         // Delete a backup
					backups.POST("/restore", server.restoreBackup)            // Restore from a backup
					backups.POST("/upload", server.uploadBackup)              // Upload a backup file

					// Enhanced backup routes
					backups.POST("/enhanced", server.createEnhancedBackup)          // Create enhanced backup
					backups.POST("/enhanced/restore", server.restoreEnhancedBackup) // Restore with enhanced features
					backups.GET("/status", server.getBackupStatus)                  // Get backup system status
					backups.POST("/validate/:filename", server.validateBackupFile)  // Validate backup file
					backups.GET("/schedules", server.getBackupSchedules)            // Get backup schedules
					backups.POST("/schedules", server.addBackupSchedule)            // Add backup schedule
					backups.DELETE("/schedules/:id", server.removeBackupSchedule)   // Remove backup schedule
					backups.GET("/history", server.getBackupHistory)                // Get backup history
					backups.POST("/cleanup", server.cleanupOldBackupsHandler)       // Manual cleanup
				} // Cache management routes
				if server.config.CacheEnabled {
					cacheRoutes := adminRoutes.Group("/cache")
					cacheRoutes.Use(server.rbacMiddleware.RequirePermission("cache", "manage"))
					{
						cacheRoutes.GET("/stats", server.getCacheStats)                   // Get cache statistics
						cacheRoutes.DELETE("/clear", server.clearCache)                   // Clear all cache
						cacheRoutes.DELETE("/clear/:pattern", server.clearCacheByPattern) // Clear cache by pattern

						// Advanced cache management routes
						cacheRoutes.GET("/advanced-stats", server.getAdvancedCacheStats)      // Get advanced cache statistics
						cacheRoutes.GET("/health", server.getCacheHealth)                     // Get cache health status
						cacheRoutes.POST("/warm", server.triggerCacheWarming)                 // Trigger manual cache warming
						cacheRoutes.POST("/invalidate/tag/:tag", server.invalidateCacheByTag) // Invalidate cache by tag
					}
				} // Concurrency management routes
				if server.config.ConcurrencyEnabled {
					concurrencyRoutes := adminRoutes.Group("/performance/concurrency")
					concurrencyRoutes.Use(server.rbacMiddleware.RequirePermission("performance", "manage"))
					{
						concurrencyRoutes.POST("/reset", server.resetConcurrencyMetrics) // Reset concurrency metrics
					}
				}
				// Admin upgrade management routes
				upgradeAdmin := adminRoutes.Group("/upgrade")
				upgradeAdmin.Use(server.rbacMiddleware.RequirePermission("system", "manage"))
				{
					upgradeAdmin.GET("/stats", server.getUpgradeStats) // Get upgrade statistics
					upgradeAdmin.POST("/versions", server.addVersion)  // Add new version
					upgradeAdmin.POST("/notify", server.notifyUpgrade) // Send upgrade notification
				} // Admin i18n management routes
				i18nAdmin := adminRoutes.Group("/i18n")
				i18nAdmin.Use(server.rbacMiddleware.RequirePermission("i18n", "manage"))
				{
					i18nAdmin.GET("/languages", server.getLanguages)                          // Get languages for admin (reuse public method)
					i18nAdmin.POST("/languages/:language/messages", server.addMessage)        // Add/update single message
					i18nAdmin.POST("/languages/:language/messages/batch", server.addMessages) // Add/update multiple messages
					i18nAdmin.GET("/languages/:language/export", server.exportMessages)       // Export messages for language
				}
			}

			users := authRoutes.Group("/users")
			{
				users.GET("/me", server.getCurrentUser)
				users.GET("/:id", server.getUser)
				users.GET("", server.listUsers)
				users.PUT("/:id", server.updateUser)
				users.DELETE("/:id", server.deleteUser)
			}
			words := authRoutes.Group("/words")
			{
				words.GET("/:id", server.getWord)
				words.GET("", server.listWords)
				words.GET("/search", server.searchWords)
				words.POST("", server.createWord)
				words.PUT("/:id", server.updateWord)
				words.DELETE("/:id", server.deleteWord)
			} // Protected Grammar routes (e.g., for admin management)
			grammarsProtected := authRoutes.Group("/grammars")
			{
				grammarsProtected.POST("", server.createGrammar)
				grammarsProtected.PUT("/:id", server.updateGrammar)
				grammarsProtected.DELETE("/:id", server.deleteGrammar)
			}

			// Protected upgrade routes (for authenticated users)
			upgradeProtected := authRoutes.Group("/upgrade")
			{
				upgradeProtected.GET("/ws", server.upgradeWebSocket)                  // WebSocket upgrade
				upgradeProtected.POST("/subscribe", server.subscribeToUpgrades)       // Subscribe to notifications
				upgradeProtected.POST("/unsubscribe", server.unsubscribeFromUpgrades) // Unsubscribe from notifications
			}

			// Example routes
			examples := authRoutes.Group("/examples")
			{
				examples.GET("/:id", server.getExample)
				examples.GET("", server.listExamples)
				examples.POST("/batch", server.batchGetExamples)
				examples.POST("", server.createExample)
				examples.PUT("/:id", server.updateExample)
				examples.DELETE("/:id", server.deleteExample)
			} // Exam routes
			exams := authRoutes.Group("/exams")
			{
				exams.POST("", server.createExam)
				exams.GET("/:id", server.getExam)
				exams.GET("", server.listExams)
				exams.PUT("/:id", server.updateExam)
				exams.DELETE("/:id", server.deleteExam)
				exams.GET("/:id/questions", server.getExamQuestions)
			}

			// Exam Parts route (separate to avoid wildcard conflict)
			authRoutes.GET("/exam-parts/:exam_id", server.listPartsByExam)

			// Part routes
			parts := authRoutes.Group("/parts")
			{
				parts.POST("", server.createPart)
				parts.GET("/:id", server.getPart)
				parts.PUT("/:id", server.updatePart)
				parts.DELETE("/:id", server.deletePart)
			}

			// Part Contents route (separate to avoid wildcard conflict)
			authRoutes.GET("/part-contents/:part_id", server.listContentsByPart)

			// Content routes
			contents := authRoutes.Group("/contents")
			{
				contents.POST("", server.createContent)
				contents.GET("/:id", server.getContent)
				contents.PUT("/:id", server.updateContent)
				contents.DELETE("/:id", server.deleteContent)
			}

			// Content Questions route (separate to avoid wildcard conflict)
			authRoutes.GET("/content-questions/:content_id", server.listQuestionsByContent) // Question routes
			questions := authRoutes.Group("/questions")
			{
				questions.POST("", server.createQuestion)
				questions.GET("/:id", server.getQuestion)
				questions.PUT("/:id", server.updateQuestion)
				questions.DELETE("/:id", server.deleteQuestion)
			} // User Word Progress routes
			userWordProgress := authRoutes.Group("/user-word-progress")
			{
				userWordProgress.POST("", server.createUserWordProgress)
				userWordProgress.GET("/:word_id", server.getUserWordProgress)
				userWordProgress.PUT("/:word_id", server.updateUserWordProgress)
				userWordProgress.DELETE("/:word_id", server.deleteUserWordProgress)
				userWordProgress.GET("/reviews", server.getWordsForReview)
				userWordProgress.GET("/word/:word_id", server.getWordWithProgress)
				userWordProgress.GET("/saved", server.getAllSavedWords)
			} // Writing routes
			writing := authRoutes.Group("/writing")
			{
				// Prompt submissions - separate to avoid wildcard conflict
				writing.GET("/prompt-submissions/:prompt_id", server.listUserWritingsByPromptID)
				// Writing prompt routes
				{
					prompts := writing.Group("/prompts")
					{
						prompts.POST("", server.createWritingPrompt)
						prompts.GET("/:id", server.getWritingPrompt)
						prompts.GET("", server.listWritingPrompts)
						prompts.PUT("/:id", server.updateWritingPrompt)
						prompts.DELETE("/:id", server.deleteWritingPrompt)
					}
				}
				// User writing submissions routes
				submissions := writing.Group("/submissions")
				{
					submissions.POST("", server.createUserWriting)
					submissions.GET("/:id", server.getUserWriting)
					submissions.PUT("/:id", server.updateUserWriting)
					submissions.DELETE("/:id", server.deleteUserWriting)
				}

				// User-specific writing submissions
				writing.GET("/users/:user_id/submissions", server.listUserWritingsByUserID)
			} // Speaking routes
			speaking := authRoutes.Group("/speaking")
			{
				// Speaking session routes
				sessions := speaking.Group("/sessions")
				{
					sessions.POST("", server.createSpeakingSession)
					sessions.GET("/:id", server.getSpeakingSession)
					sessions.PUT("/:id", server.updateSpeakingSession)
					sessions.DELETE("/:id", server.deleteSpeakingSession)
					// Session turns nested under the specific session
					sessions.GET("/:id/turns", server.listSpeakingTurnsBySessionID)
				}

				// User-specific speaking sessions
				speaking.GET("/users/:user_id/sessions", server.listSpeakingSessionsByUserID)

				// Speaking turn routes
				turns := speaking.Group("/turns")
				{
					turns.POST("", server.createSpeakingTurn)
					turns.GET("/:id", server.getSpeakingTurn)
					turns.PUT("/:id", server.updateSpeakingTurn)
					turns.DELETE("/:id", server.deleteSpeakingTurn)
				}
			} // Exam Attempt routes
			examAttempts := authRoutes.Group("/exam-attempts")
			{
				examAttempts.POST("", server.createExamAttempt)
				examAttempts.GET("/:id", server.getExamAttempt)
				examAttempts.GET("", server.listUserExamAttempts)
				examAttempts.PUT("/:id", server.updateExamAttempt)
				examAttempts.DELETE("/:id", server.deleteExamAttempt)
				examAttempts.POST("/:id/complete", server.completeExamAttempt)
				examAttempts.POST("/:id/abandon", server.abandonExamAttempt)
				examAttempts.GET("/stats", server.getExamAttemptStats)
				// Nested routes for specific exam attempts
				examAttempts.GET("/:id/answers", server.getUserAnswersByAttempt)
				examAttempts.GET("/:id/score", server.getAttemptScore)
			}

			// User Answer routes
			userAnswers := authRoutes.Group("/user-answers")
			{
				userAnswers.POST("", server.createUserAnswer)
				userAnswers.GET("/:id", server.getUserAnswer)
				userAnswers.PUT("/:id", server.updateUserAnswer)
				userAnswers.DELETE("/:id", server.deleteUserAnswer)
			}

			// Exam leaderboard route
			authRoutes.GET("/exams/:id/leaderboard", server.getExamLeaderboard) // Text analysis routes
			if server.config.AnalyzeServiceEnabled && server.analyzeService != nil {
				analyze := authRoutes.Group("/analyze")
				{
					analyze.POST("/text", server.analyzeText)
					analyze.POST("/texts", server.analyzeMultipleTexts)
					analyze.GET("/health", server.getAnalyzeServiceHealth)
					analyze.GET("/stats", server.getAnalyzeServiceStats)
					analyze.POST("/cache/clear", server.clearAnalyzeServiceCache)
					analyze.GET("/cache", server.getCachedAnalysis)
				}
			}
		}
	}

	// API documentation with custom URL and configuration options
	router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Log all routes for debugging
	logger.Debug("API Routes:")
	for _, route := range router.Routes() {
		logger.Debug("Route: %s %s", route.Method, route.Path)
	}

	server.router = router
}

// Start runs the HTTP server on a specific address.
func (server *Server) Start(address string) error {
	logger.Info("Starting HTTP server on address: %s", address)

	// Start monitoring service if enabled
	if server.monitoringService != nil {
		logger.Info("Starting monitoring service...")
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		server.monitoringService.Start(ctx)
		logger.Info("Monitoring service started successfully")
	}

	// Start cache manager if available
	if server.cacheManager != nil {
		logger.Info("Starting advanced cache manager...")
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		if err := server.cacheManager.Start(ctx); err != nil {
			logger.Error("Failed to start cache manager: %v", err)
			logger.Warn("Continuing without advanced cache management")
		} else {
			logger.Info("Cache manager started successfully")
		}
	}

	// Start cache warming if available (via cache manager)
	if server.cacheManager != nil {
		logger.Info("Starting cache warming process...")
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
			defer cancel()

			if err := server.cacheManager.WarmCache(ctx); err != nil {
				logger.Warn("Initial cache warming failed: %v", err)
			} else {
				logger.Info("Initial cache warming completed successfully")
			}
		}()
	}

	// Create a proper http.Server with reasonable timeouts
	server.httpServer = &http.Server{
		Addr:         address,
		Handler:      server.router,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// Run the server
	return server.httpServer.ListenAndServe()
}

// Shutdown gracefully stops the server and cleans up resources
func (server *Server) Shutdown(ctx context.Context) error {
	logger.Info("Shutting down HTTP server...")

	// Shut down the HTTP server first, so it stops accepting new requests
	var err error
	if server.httpServer != nil {
		// First shut down the HTTP server
		if err = server.httpServer.Shutdown(ctx); err != nil {
			logger.Error("HTTP server shutdown error: %v", err)
			// Continue with other cleanup even if HTTP shutdown fails
		} else {
			logger.Info("HTTP server shutdown complete")
		}
	}

	// Clean up rate limiter resources if enabled
	if server.config.RateLimitEnabled && server.rateLimiter != nil {
		server.rateLimiter.Stop()
		logger.Info("Rate limiter shutdown complete")
	}
	// Stop the token maker to clean up blacklist resources
	if server.tokenMaker != nil {
		server.tokenMaker.Stop()
		logger.Info("Token blacklist cleanup stopped")
	} // Stop automatic backups
	if err := server.StopAutomaticBackups(); err != nil {
		logger.Error("Error stopping automatic backups: %v", err)
	}

	// Shutdown WebSocket manager
	if server.wsManager != nil {
		if err := server.wsManager.Shutdown(ctx); err != nil {
			logger.Error("Error shutting down WebSocket manager: %v", err)
		} else {
			logger.Info("WebSocket manager shutdown complete")
		}
	}

	// Stop background processor
	if server.backgroundProcessor != nil {
		server.backgroundProcessor.Stop()
		logger.Info("Background processor shutdown complete")
	}

	// Stop concurrency management components if enabled
	if server.config.ConcurrencyEnabled {
		logger.Info("Shutting down concurrency management components...")

		// Stop concurrency manager
		if server.concurrencyManager != nil {
			shutdownCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
			defer cancel()
			if err := server.concurrencyManager.Shutdown(shutdownCtx); err != nil {
				logger.Error("Error shutting down concurrency manager: %v", err)
			} else {
				logger.Info("Concurrency manager shutdown complete")
			}
		}

		// Stop connection pool manager
		if server.poolManager != nil {
			server.poolManager.Stop()
			logger.Info("Connection pool manager shutdown complete")
		}

		// Note: ConcurrentRequestHandler doesn't have a Stop method
		// It will be cleaned up when the HTTP server shuts down
		if server.concurrentHandler != nil {
			logger.Info("Concurrent request handler will be cleaned up with HTTP server shutdown")
		}
	}

	// Close database connections if needed
	// This would be implemented here if we needed to close DB connections

	return err
}

// StartAutomaticBackups initializes and starts the enhanced backup scheduler
func (server *Server) StartAutomaticBackups(ctx context.Context) error {
	logger.Info("Starting enhanced automatic database backup system")

	// Use the enhanced backup scheduler if available
	if server.enhancedBackupScheduler != nil {
		err := server.enhancedBackupScheduler.Start()
		if err != nil {
			return fmt.Errorf("failed to start enhanced backup scheduler: %w", err)
		}
		logger.Info("Enhanced backup scheduler started successfully")
		return nil
	}

	// Fallback to legacy backup system
	logger.Info("Enhanced backup scheduler not available, using legacy system")

	// Create backup function that will be called by the scheduler
	backupFunc := func() error {
		backupID := time.Now().Format("20060102_150405")
		filename := fmt.Sprintf("auto_backup_%s.sql", backupID)
		description := "Automated scheduled backup"

		logger.Info("Running scheduled backup: %s", filename)
		_, err := server.createBackupWithTransaction(filename, description)
		return err
	}

	// Get backup interval from config (default to 24 hours)
	interval := 24 * time.Hour

	// Initialize the scheduler
	server.backupScheduler = scheduler.NewBackupScheduler(
		interval,
		backupFunc,
		"Daily automated database backup",
	)

	// Start the scheduler
	err := server.backupScheduler.Start()
	if err != nil {
		return fmt.Errorf("failed to start backup scheduler: %w", err)
	}

	logger.Info("Automatic database backups started with interval: %v", interval)
	return nil
}

// StopAutomaticBackups stops the backup scheduler
func (server *Server) StopAutomaticBackups() error {
	// Stop enhanced backup scheduler if available
	if server.enhancedBackupScheduler != nil && server.enhancedBackupScheduler.IsRunning() {
		logger.Info("Stopping enhanced automatic database backups")
		return server.enhancedBackupScheduler.Stop()
	}

	// Fallback to legacy backup scheduler
	if server.backupScheduler != nil && server.backupScheduler.IsRunning() {
		logger.Info("Stopping legacy automatic database backups")
		return server.backupScheduler.Stop()
	}
	return nil
}

// CleanupOldBackups removes backups older than the specified retention period
func (server *Server) CleanupOldBackups(maxAge time.Duration) error {
	backupDir := filepath.Join(".", "backups")
	logger.Info("Cleaning up old backups older than %v", maxAge)

	// Ensure the backup directory exists
	if err := ensureBackupDir(backupDir); err != nil {
		return err
	}

	// Get all backup files
	files, err := os.ReadDir(backupDir)
	if err != nil {
		return err
	}

	now := time.Now()
	deletedCount := 0

	for _, file := range files {
		// Skip directories
		if file.IsDir() {
			continue
		}

		// Skip non-SQL files
		if filepath.Ext(file.Name()) != ".sql" {
			continue
		}

		// Get file info
		fileInfo, err := file.Info()
		if err != nil {
			logger.Warn("Failed to get file info for %s: %v", file.Name(), err)
			continue
		}

		// Check if file is older than the retention period
		if now.Sub(fileInfo.ModTime()) > maxAge {
			filePath := filepath.Join(backupDir, file.Name())

			// Delete the file
			if err := os.Remove(filePath); err != nil {
				logger.Warn("Failed to delete old backup %s: %v", file.Name(), err)
				continue
			}

			logger.Debug("Deleted old backup: %s (age: %v)", file.Name(), now.Sub(fileInfo.ModTime()))
			deletedCount++
		}
	}

	logger.Info("Backup cleanup complete: removed %d old backups", deletedCount)
	return nil
}

func (server *Server) SetReleaseMode() {
	gin.SetMode(gin.ReleaseMode)
}

// GetCache returns the cache instance
func (server *Server) GetCache() cache.Cache {
	return server.cache
}
