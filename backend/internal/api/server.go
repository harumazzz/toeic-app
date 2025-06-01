package api

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"github.com/toeic-app/internal/config"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/middleware"
	"github.com/toeic-app/internal/scheduler"
	"github.com/toeic-app/internal/token"
	"github.com/toeic-app/internal/uploader"
)

// @BasePath /api/v1
// @Schemes http https
// @SecurityDefinitions.apikey ApiKeyAuth
// @In header
// @Name Authorization

// Server serves HTTP requests for our banking service.
type Server struct {
	config          config.Config
	store           db.Querier
	tokenMaker      token.Maker
	router          *gin.Engine
	uploader        *uploader.CloudinaryUploader
	rateLimiter     *middleware.AdvancedRateLimit // Store the rate limiter instance
	httpServer      *http.Server                  // Store the HTTP server instance
	backupScheduler *scheduler.BackupScheduler    // Automated backup scheduler
}

// NewServer creates a new HTTP server and setup routing.
func NewServer(config config.Config, store db.Querier) (*Server, error) {
	tokenMaker, err := token.NewJWTMaker(config.TokenSymmetricKey)
	if err != nil {
		return nil, err
	}

	cloudinaryUploader, err := uploader.NewCloudinaryUploader(config)
	if err != nil {
		return nil, err
	}

	// Initialize the server
	server := &Server{
		config:     config,
		store:      store,
		tokenMaker: tokenMaker,
		uploader:   cloudinaryUploader,
	}

	// Initialize rate limiter if enabled
	if config.RateLimitEnabled {
		server.rateLimiter = middleware.NewAdvancedRateLimit(config, tokenMaker)
		logger.Info("Rate limiting initialized with %d requests/sec, %d burst",
			config.RateLimitRequests, config.RateLimitBurst)
	}

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
	// Apply middleware
	router.Use(gin.Recovery())                 // Recovery middleware recovers from panics
	router.Use(middleware.Logger())            // Our custom logger
	router.Use(middleware.CORS(server.config)) // Enable CORS with config

	// Apply rate limiting middleware based on config
	if server.config.RateLimitEnabled {
		logger.Info("Enabling rate limiting with %d requests/sec, %d burst",
			server.config.RateLimitRequests, server.config.RateLimitBurst)

		// Initialize advanced rate limiter
		advancedLimiter := middleware.NewAdvancedRateLimit(server.config, server.tokenMaker)
		router.Use(advancedLimiter.Middleware())
	}
	// Health check and metrics routes
	router.GET("/health", server.healthCheck)
	router.GET("/metrics", server.getMetrics)

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

		// Protected routes requiring authentication
		authRoutes := v1.Group("/")
		authRoutes.Use(server.authMiddleware())
		{ // Admin routes for database management
			adminRoutes := authRoutes.Group("/admin")
			adminRoutes.Use(middleware.AdminOnly(server.IsUserAdmin))
			{
				backups := adminRoutes.Group("/backups")
				{
					backups.POST("", server.createBackup)                     // Create a new backup
					backups.GET("", server.listBackups)                       // List all backups
					backups.GET("/download/:filename", server.downloadBackup) // Download a backup
					backups.DELETE("/:filename", server.deleteBackup)         // Delete a backup
					backups.POST("/restore", server.restoreBackup)            // Restore from a backup
					backups.POST("/upload", server.uploadBackup)              // Upload a backup file
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
			}

			// Protected Grammar routes (e.g., for admin management)
			grammarsProtected := authRoutes.Group("/grammars")
			{
				grammarsProtected.POST("", server.createGrammar)
				grammarsProtected.PUT("/:id", server.updateGrammar)
				grammarsProtected.DELETE("/:id", server.deleteGrammar)
			} // Example routes
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
			} // Writing routes
			writing := authRoutes.Group("/writing")
			{ // Writing prompt routes
				prompts := writing.Group("/prompts")
				{
					prompts.POST("", server.createWritingPrompt)
					prompts.GET("/:id", server.getWritingPrompt)
					prompts.GET("", server.listWritingPrompts)
					prompts.PUT("/:id", server.updateWritingPrompt)
					prompts.DELETE("/:id", server.deleteWritingPrompt)
				}

				// Prompt submissions - separate to avoid wildcard conflict
				writing.GET("/prompt-submissions/:prompt_id", server.listUserWritingsByPromptID)

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
	}

	// Stop automatic backups
	if err := server.StopAutomaticBackups(); err != nil {
		logger.Error("Error stopping automatic backups: %v", err)
	}

	// Close database connections if needed
	// This would be implemented here if we needed to close DB connections

	return err
}

// StartAutomaticBackups initializes and starts the automated backup scheduler
func (server *Server) StartAutomaticBackups(ctx context.Context) error {
	logger.Info("Setting up automatic database backups")

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
	if server.backupScheduler != nil && server.backupScheduler.IsRunning() {
		logger.Info("Stopping automatic database backups")
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
