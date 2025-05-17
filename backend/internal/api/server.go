package api

import (
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"github.com/toeic-app/internal/config"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/middleware"
	"github.com/toeic-app/internal/token"
)

// @BasePath /api/v1
// @Schemes http https
// @SecurityDefinitions.apikey ApiKeyAuth
// @In header
// @Name Authorization

// Server serves HTTP requests for our banking service.
type Server struct {
	config     config.Config
	store      db.Querier
	tokenMaker token.Maker
	router     *gin.Engine
}

// NewServer creates a new HTTP server and setup routing.
func NewServer(config config.Config, store db.Querier) (*Server, error) {
	tokenMaker, err := token.NewJWTMaker(config.TokenSymmetricKey)
	if err != nil {
		return nil, err
	}

	server := &Server{
		config:     config,
		store:      store,
		tokenMaker: tokenMaker,
	}

	server.setupRouter()
	return server, nil
}

func (server *Server) setupRouter() {
	router := gin.New() // Create a new clean router without default middleware

	// Apply middleware
	router.Use(gin.Recovery())      // Recovery middleware recovers from panics
	router.Use(middleware.Logger()) // Our custom logger
	router.Use(middleware.CORS())
	// Health check and metrics routes
	router.GET("/health", server.healthCheck)
	router.GET("/metrics", server.getMetrics)

	// Authentication routes
	router.POST("/api/login", server.loginUser)
	router.POST("/api/register", server.registerUser)
	router.POST("/api/refresh-token", server.refreshToken)

	// API v1 group
	v1 := router.Group("/api/v1")
	{
		// Public routes
		v1.POST("/users", server.createUser)

		// Grammar routes (publicly accessible for now, consider auth later if needed)
		grammarsPublic := v1.Group("/grammars")
		{
			grammarsPublic.GET("", server.listGrammars)
			grammarsPublic.GET("/:id", server.getGrammar)
			grammarsPublic.GET("/random", server.getRandomGrammar)
			grammarsPublic.GET("/level", server.listGrammarsByLevel)
			grammarsPublic.GET("/tag", server.listGrammarsByTag)
			grammarsPublic.GET("/search", server.searchGrammars)
		}

		// Protected routes requiring authentication
		authRoutes := v1.Group("/")
		authRoutes.Use(server.authMiddleware())
		{
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
			}

			// User Word Progress routes
			userWordProgress := authRoutes.Group("/user-word-progress")
			{
				userWordProgress.POST("", server.createUserWordProgress)
				userWordProgress.GET("/:word_id", server.getUserWordProgress)
				userWordProgress.PUT("/:word_id", server.updateUserWordProgress)
				userWordProgress.DELETE("/:word_id", server.deleteUserWordProgress)
				userWordProgress.GET("/reviews", server.getWordsForReview)
				userWordProgress.GET("/word/:word_id", server.getWordWithProgress)
			}
		}
	}

	// API documentation with custom URL and configuration options
	router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	server.router = router
}

// Start runs the HTTP server on a specific address.
func (server *Server) Start(address string) error {
	return server.router.Run(address)
}
