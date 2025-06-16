package api

import (
	"database/sql"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/middleware"
	"github.com/toeic-app/internal/performance"
)

// RegisterPerformanceRoutes registers performance monitoring routes
// This function should be called from your main server setup
func RegisterPerformanceRoutes(r *gin.RouterGroup, db *sql.DB, rbacMiddleware *middleware.RBACMiddleware) {
	performanceController := NewPerformanceController(performance.NewPerformanceMonitor(db))

	// Performance monitoring routes (admin only)
	perfGroup := r.Group("/performance")

	// Apply authentication and authorization middleware
	// Note: You may need to adjust these middleware calls based on your actual server structure
	if rbacMiddleware != nil {
		perfGroup.Use(rbacMiddleware.RequirePermission("system.monitor"))
	}

	{
		perfGroup.GET("/metrics", performanceController.GetPerformanceMetrics)
		perfGroup.GET("/indexes", performanceController.GetIndexUsageStats)
		perfGroup.GET("/tables", performanceController.GetTableStats)
		perfGroup.GET("/cache", performanceController.GetCacheHitRatio)
		perfGroup.GET("/recommendations", performanceController.GetOptimizationRecommendations)
		perfGroup.GET("/dashboard", performanceController.PerformanceDashboard)
		perfGroup.POST("/optimize", performanceController.RunOptimization)
	}
}

// Example usage in your main server setup:
//
// func (s *Server) setupRoutes() {
//     api := s.router.Group("/api/v1")
//
//     // Register performance routes
//     RegisterPerformanceRoutes(api, s.dbConnection, s.rbacMiddleware)
// }
