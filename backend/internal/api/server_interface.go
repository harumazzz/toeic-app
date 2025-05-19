package api

import (
	"context"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/token"
)

// ServerInterface defines the methods that the Server struct must implement
// This is used for middleware to avoid circular dependencies
type ServerInterface interface {
	// Authentication related methods
	GetAuthPayload(ctx *gin.Context) (*token.Payload, error)

	// Admin check method
	IsUserAdmin(ctx context.Context, userID int32) (bool, error)
}
