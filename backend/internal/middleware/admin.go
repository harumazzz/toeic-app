package middleware

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/constants"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/token"
)

// AdminRoleCheck is a function type that checks if a user has admin role
type AdminRoleCheck func(ctx context.Context, userID int32) (bool, error)

// AdminOnly is a middleware that restricts access to admin users only
func AdminOnly(roleCheck AdminRoleCheck) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// Get the authenticated user from the context
		payload, exists := ctx.Get(constants.AuthorizationPayloadKey)
		if !exists {
			logger.Warn("Admin check failed - no auth payload in context")
			ctx.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "Authentication required"})
			ctx.Abort()
			return
		}

		authPayload, ok := payload.(*token.Payload)
		if !ok {
			logger.Error("Failed to cast authorization payload")
			ctx.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Authentication error"})
			ctx.Abort()
			return
		}

		// Check if the user is an admin
		isAdmin, err := roleCheck(ctx, authPayload.ID)
		if err != nil {
			logger.Error("Failed to check admin status: %v", err)
			ctx.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Failed to verify admin privileges"})
			ctx.Abort()
			return
		}

		if !isAdmin {
			logger.Warn("Admin access denied for user ID: %d", authPayload.ID)
			ctx.JSON(http.StatusForbidden, gin.H{"status": "error", "message": "Admin privileges required"})
			ctx.Abort()
			return
		}

		// User is confirmed as an admin
		logger.Debug("Admin access granted for user ID: %d", authPayload.ID)
		ctx.Next()
	}
}
