package middleware

import (
	"context"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/rbac"
	"github.com/toeic-app/internal/token"
)

// RBACMiddleware provides role-based access control middleware
type RBACMiddleware struct {
	rbacService *rbac.Service
}

// NewRBACMiddleware creates a new RBAC middleware
func NewRBACMiddleware(rbacService *rbac.Service) *RBACMiddleware {
	return &RBACMiddleware{
		rbacService: rbacService,
	}
}

// RequirePermission creates a middleware that requires a specific permission
// Can be called with either one parameter (permission name) or two parameters (resource, action)
func (rm *RBACMiddleware) RequirePermission(args ...string) gin.HandlerFunc {
	var permissionName string
	var resource, action string

	switch len(args) {
	case 1:
		permissionName = args[0]
	case 2:
		resource = args[0]
		action = args[1]
		permissionName = fmt.Sprintf("%s.%s", resource, action)
	default:
		// This is a programming error, so we panic
		panic("RequirePermission requires either 1 permission name or 2 parameters (resource, action)")
	}

	return func(ctx *gin.Context) {
		userID, err := rm.getUserIDFromContext(ctx)
		if err != nil {
			logger.Warn("RBAC: Failed to get user ID from context: %v", err)
			ctx.JSON(http.StatusUnauthorized, gin.H{
				"status":  "error",
				"message": "Authentication required",
				"code":    "RBAC_AUTH_REQUIRED",
			})
			ctx.Abort()
			return
		}

		var hasPermission bool
		if resource != "" && action != "" {
			// Use resource-action check
			permCheck, err := rm.rbacService.CheckPermissionByResourceAction(ctx, userID, resource, action)
			if err != nil {
				logger.Error("RBAC: Failed to check permission %s.%s for user %d: %v", resource, action, userID, err)
				ctx.JSON(http.StatusInternalServerError, gin.H{
					"status":  "error",
					"message": "Failed to verify permissions",
					"code":    "RBAC_PERMISSION_CHECK_FAILED",
				})
				ctx.Abort()
				return
			}
			hasPermission = permCheck.HasPermission
		} else {
			// Use permission name check
			var err error
			hasPermission, err = rm.checkUserPermission(ctx, userID, permissionName)
			if err != nil {
				logger.Error("RBAC: Failed to check permission %s for user %d: %v", permissionName, userID, err)
				ctx.JSON(http.StatusInternalServerError, gin.H{
					"status":  "error",
					"message": "Failed to verify permissions",
					"code":    "RBAC_PERMISSION_CHECK_FAILED",
				})
				ctx.Abort()
				return
			}
		}

		if !hasPermission {
			logger.Warn("RBAC: User %d denied access - missing permission: %s", userID, permissionName)
			ctx.JSON(http.StatusForbidden, gin.H{
				"status":  "error",
				"message": "Insufficient permissions",
				"code":    "RBAC_PERMISSION_DENIED",
				"details": map[string]string{
					"required_permission": permissionName,
				},
			})
			ctx.Abort()
			return
		}

		logger.Debug("RBAC: User %d granted access with permission: %s", userID, permissionName)
		ctx.Next()
	}
}

// RequireAnyPermission creates a middleware that requires any of the specified permissions
func (rm *RBACMiddleware) RequireAnyPermission(permissions ...string) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		userID, err := rm.getUserIDFromContext(ctx)
		if err != nil {
			logger.Warn("RBAC: Failed to get user ID from context: %v", err)
			ctx.JSON(http.StatusUnauthorized, gin.H{
				"status":  "error",
				"message": "Authentication required",
				"code":    "RBAC_AUTH_REQUIRED",
			})
			ctx.Abort()
			return
		}

		hasAnyPermission := false
		var grantedPermission string

		for _, permission := range permissions {
			hasPermission, err := rm.checkUserPermission(ctx, userID, permission)
			if err != nil {
				logger.Error("RBAC: Failed to check permission %s for user %d: %v", permission, userID, err)
				continue
			}

			if hasPermission {
				hasAnyPermission = true
				grantedPermission = permission
				break
			}
		}

		if !hasAnyPermission {
			logger.Warn("RBAC: User %d denied access - missing any of permissions: %v", userID, permissions)
			ctx.JSON(http.StatusForbidden, gin.H{
				"status":  "error",
				"message": "Insufficient permissions",
				"code":    "RBAC_PERMISSION_DENIED",
				"details": map[string]interface{}{
					"required_permissions": permissions,
					"operator":             "ANY",
				},
			})
			ctx.Abort()
			return
		}

		logger.Debug("RBAC: User %d granted access with permission: %s", userID, grantedPermission)
		ctx.Next()
	}
}

// RequireAllPermissions creates a middleware that requires all of the specified permissions
func (rm *RBACMiddleware) RequireAllPermissions(permissions ...string) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		userID, err := rm.getUserIDFromContext(ctx)
		if err != nil {
			logger.Warn("RBAC: Failed to get user ID from context: %v", err)
			ctx.JSON(http.StatusUnauthorized, gin.H{
				"status":  "error",
				"message": "Authentication required",
				"code":    "RBAC_AUTH_REQUIRED",
			})
			ctx.Abort()
			return
		}

		var missingPermissions []string

		for _, permission := range permissions {
			hasPermission, err := rm.checkUserPermission(ctx, userID, permission)
			if err != nil {
				logger.Error("RBAC: Failed to check permission %s for user %d: %v", permission, userID, err)
				missingPermissions = append(missingPermissions, permission)
				continue
			}

			if !hasPermission {
				missingPermissions = append(missingPermissions, permission)
			}
		}

		if len(missingPermissions) > 0 {
			logger.Warn("RBAC: User %d denied access - missing permissions: %v", userID, missingPermissions)
			ctx.JSON(http.StatusForbidden, gin.H{
				"status":  "error",
				"message": "Insufficient permissions",
				"code":    "RBAC_PERMISSION_DENIED",
				"details": map[string]interface{}{
					"required_permissions": permissions,
					"missing_permissions":  missingPermissions,
					"operator":             "ALL",
				},
			})
			ctx.Abort()
			return
		}

		logger.Debug("RBAC: User %d granted access with all required permissions: %v", userID, permissions)
		ctx.Next()
	}
}

// RequireRole creates a middleware that requires a specific role
func (rm *RBACMiddleware) RequireRole(roleName string) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		userID, err := rm.getUserIDFromContext(ctx)
		if err != nil {
			logger.Warn("RBAC: Failed to get user ID from context: %v", err)
			ctx.JSON(http.StatusUnauthorized, gin.H{
				"status":  "error",
				"message": "Authentication required",
				"code":    "RBAC_AUTH_REQUIRED",
			})
			ctx.Abort()
			return
		}

		hasRole, err := rm.rbacService.HasRole(ctx, userID, roleName)
		if err != nil {
			logger.Error("RBAC: Failed to check role %s for user %d: %v", roleName, userID, err)
			ctx.JSON(http.StatusInternalServerError, gin.H{
				"status":  "error",
				"message": "Failed to verify role",
				"code":    "RBAC_ROLE_CHECK_FAILED",
			})
			ctx.Abort()
			return
		}

		if !hasRole {
			logger.Warn("RBAC: User %d denied access - missing role: %s", userID, roleName)
			ctx.JSON(http.StatusForbidden, gin.H{
				"status":  "error",
				"message": "Insufficient permissions",
				"code":    "RBAC_ROLE_DENIED",
				"details": map[string]string{
					"required_role": roleName,
				},
			})
			ctx.Abort()
			return
		}

		logger.Debug("RBAC: User %d granted access with role: %s", userID, roleName)
		ctx.Next()
	}
}

// RequireResourceAccess creates a middleware that requires permission for a specific resource and action
func (rm *RBACMiddleware) RequireResourceAccess(resource, action string) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		userID, err := rm.getUserIDFromContext(ctx)
		if err != nil {
			logger.Warn("RBAC: Failed to get user ID from context: %v", err)
			ctx.JSON(http.StatusUnauthorized, gin.H{
				"status":  "error",
				"message": "Authentication required",
				"code":    "RBAC_AUTH_REQUIRED",
			})
			ctx.Abort()
			return
		}

		check, err := rm.rbacService.CheckPermissionByResourceAction(ctx, userID, resource, action)
		if err != nil {
			logger.Error("RBAC: Failed to check resource access %s.%s for user %d: %v", resource, action, userID, err)
			ctx.JSON(http.StatusInternalServerError, gin.H{
				"status":  "error",
				"message": "Failed to verify permissions",
				"code":    "RBAC_PERMISSION_CHECK_FAILED",
			})
			ctx.Abort()
			return
		}

		if !check.HasPermission {
			logger.Warn("RBAC: User %d denied access to resource %s action %s", userID, resource, action)
			ctx.JSON(http.StatusForbidden, gin.H{
				"status":  "error",
				"message": "Insufficient permissions",
				"code":    "RBAC_RESOURCE_ACCESS_DENIED",
				"details": map[string]string{
					"resource": resource,
					"action":   action,
				},
			})
			ctx.Abort()
			return
		}

		logger.Debug("RBAC: User %d granted access to resource %s action %s", userID, resource, action)
		ctx.Next()
	}
}

// RequireAdmin creates a middleware that requires admin privileges
func (rm *RBACMiddleware) RequireAdmin() gin.HandlerFunc {
	return rm.RequirePermission(rbac.PermSystemSettings)
}

// CheckOwnership creates a middleware that allows access if user is owner or has permission
func (rm *RBACMiddleware) CheckOwnership(getOwnerID func(*gin.Context) (int32, error), fallbackPermission string) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		userID, err := rm.getUserIDFromContext(ctx)
		if err != nil {
			logger.Warn("RBAC: Failed to get user ID from context: %v", err)
			ctx.JSON(http.StatusUnauthorized, gin.H{
				"status":  "error",
				"message": "Authentication required",
				"code":    "RBAC_AUTH_REQUIRED",
			})
			ctx.Abort()
			return
		}

		// Check if user is the owner
		ownerID, err := getOwnerID(ctx)
		if err != nil {
			logger.Error("RBAC: Failed to get owner ID: %v", err)
			ctx.JSON(http.StatusInternalServerError, gin.H{
				"status":  "error",
				"message": "Failed to verify ownership",
				"code":    "RBAC_OWNERSHIP_CHECK_FAILED",
			})
			ctx.Abort()
			return
		}

		if userID == ownerID {
			logger.Debug("RBAC: User %d granted access as owner", userID)
			ctx.Next()
			return
		}

		// If not owner, check fallback permission
		hasPermission, err := rm.checkUserPermission(ctx, userID, fallbackPermission)
		if err != nil {
			logger.Error("RBAC: Failed to check fallback permission %s for user %d: %v", fallbackPermission, userID, err)
			ctx.JSON(http.StatusInternalServerError, gin.H{
				"status":  "error",
				"message": "Failed to verify permissions",
				"code":    "RBAC_PERMISSION_CHECK_FAILED",
			})
			ctx.Abort()
			return
		}

		if !hasPermission {
			logger.Warn("RBAC: User %d denied access - not owner and missing permission: %s", userID, fallbackPermission)
			ctx.JSON(http.StatusForbidden, gin.H{
				"status":  "error",
				"message": "Access denied - not owner and insufficient permissions",
				"code":    "RBAC_OWNERSHIP_AND_PERMISSION_DENIED",
				"details": map[string]string{
					"fallback_permission": fallbackPermission,
				},
			})
			ctx.Abort()
			return
		}

		logger.Debug("RBAC: User %d granted access via fallback permission: %s", userID, fallbackPermission)
		ctx.Next()
	}
}

// InjectUserPermissions adds user permissions to the context for use in handlers
func (rm *RBACMiddleware) InjectUserPermissions() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		userID, err := rm.getUserIDFromContext(ctx)
		if err != nil {
			// User is not authenticated, continue without permissions
			ctx.Next()
			return
		}

		permissions, err := rm.rbacService.GetUserPermissions(ctx, userID)
		if err != nil {
			logger.Error("RBAC: Failed to get user permissions for user %d: %v", userID, err)
			ctx.Next()
			return
		}

		roles, err := rm.rbacService.GetUserRoles(ctx, userID)
		if err != nil {
			logger.Error("RBAC: Failed to get user roles for user %d: %v", userID, err)
			ctx.Next()
			return
		}

		// Add permissions and roles to context
		ctx.Set("user_permissions", permissions)
		ctx.Set("user_roles", roles)

		// Add convenience flags
		ctx.Set("is_admin", rm.hasPermissionInList(permissions, rbac.PermSystemSettings))
		ctx.Set("is_teacher", rm.hasRoleInList(roles, rbac.RoleTeacher))
		ctx.Set("is_student", rm.hasRoleInList(roles, rbac.RoleStudent))

		ctx.Next()
	}
}

// Helper functions

func (rm *RBACMiddleware) getUserIDFromContext(ctx *gin.Context) (int32, error) {
	payload, exists := ctx.Get("authorization_payload")
	if !exists {
		return 0, fmt.Errorf("authorization payload not found")
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		return 0, fmt.Errorf("invalid authorization payload")
	}

	return authPayload.ID, nil
}

func (rm *RBACMiddleware) checkUserPermission(ctx context.Context, userID int32, permission string) (bool, error) {
	check, err := rm.rbacService.CheckPermission(ctx, userID, permission)
	if err != nil {
		return false, err
	}
	return check.HasPermission, nil
}

func (rm *RBACMiddleware) hasPermissionInList(permissions []rbac.Permission, targetPermission string) bool {
	for _, permission := range permissions {
		if permission.Name == targetPermission {
			return true
		}
	}
	return false
}

func (rm *RBACMiddleware) hasRoleInList(roles []rbac.Role, targetRole string) bool {
	for _, role := range roles {
		if role.Name == targetRole {
			return true
		}
	}
	return false
}

// Convenience functions for common patterns

// RequireOwnerOrAdmin combines ownership check with admin fallback
func (rm *RBACMiddleware) RequireOwnerOrAdmin(getOwnerID func(*gin.Context) (int32, error)) gin.HandlerFunc {
	return rm.CheckOwnership(getOwnerID, rbac.PermSystemSettings)
}

// RequireTeacherOrAdmin allows access for teachers and admins
func (rm *RBACMiddleware) RequireTeacherOrAdmin() gin.HandlerFunc {
	return rm.RequireAnyPermission(rbac.PermContentCreate, rbac.PermSystemSettings)
}

// RequireContentManager allows access for content creators and administrators
func (rm *RBACMiddleware) RequireContentManager() gin.HandlerFunc {
	return rm.RequireAnyPermission(rbac.PermContentCreate, rbac.PermContentUpdate, rbac.PermSystemSettings)
}

// RequireExamManager allows access for exam managers and administrators
func (rm *RBACMiddleware) RequireExamManager() gin.HandlerFunc {
	return rm.RequireAnyPermission(rbac.PermExamCreate, rbac.PermExamUpdate, rbac.PermSystemSettings)
}
