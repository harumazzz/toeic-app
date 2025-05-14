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
		}
	}

	// Legacy routes for backward compatibility
	router.POST("/api/users", server.createUser)
	// Legacy protected routes
	legacyAuth := router.Group("/api")
	legacyAuth.Use(server.authMiddleware())
	{
		legacyAuth.GET("/users/:id", server.getUser)
		legacyAuth.GET("/users", server.listUsers)
		legacyAuth.PUT("/users/:id", server.updateUser)
		legacyAuth.DELETE("/users/:id", server.deleteUser)
	} // API documentation with custom URL and configuration options
	// Configure Swagger with JWT auth support
	// The URL points to API definition

	router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	server.router = router
}

// Start runs the HTTP server on a specific address.
func (server *Server) Start(address string) error {
	return server.router.Run(address)
}
