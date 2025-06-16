package api

import (
	"context"

	"github.com/toeic-app/internal/rbac"
)

// IsUserAdmin checks if a user has admin privileges using the RBAC system
func (server *Server) IsUserAdmin(ctx context.Context, userID int32) (bool, error) {
	// Check if user has admin role
	hasAdminRole, err := server.rbacService.HasRole(ctx, userID, rbac.RoleAdmin)
	if err != nil {
		return false, err
	}

	if hasAdminRole {
		return true, nil
	}

	// Also check if user has admin access permission directly
	hasAdminPermission, err := server.rbacService.CheckPermissionByResourceAction(ctx, userID, "admin", "access")
	if err != nil {
		return false, err
	}

	return hasAdminPermission.HasPermission, nil
}
