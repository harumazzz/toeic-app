package api

import (
	"database/sql"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/rbac"
	"github.com/toeic-app/internal/token"
)

// RBAC Response structures

type RoleResponse struct {
	ID          int32                `json:"id"`
	Name        string               `json:"name"`
	Description string               `json:"description"`
	Permissions []PermissionResponse `json:"permissions,omitempty"`
	CreatedAt   string               `json:"created_at"`
	UpdatedAt   string               `json:"updated_at"`
}

type PermissionResponse struct {
	ID          int32  `json:"id"`
	Name        string `json:"name"`
	Resource    string `json:"resource"`
	Action      string `json:"action"`
	Description string `json:"description"`
}

type UserRoleAssignmentResponse struct {
	UserID     int32   `json:"user_id"`
	RoleID     int32   `json:"role_id"`
	RoleName   string  `json:"role_name"`
	AssignedAt string  `json:"assigned_at"`
	AssignedBy *int32  `json:"assigned_by,omitempty"`
	ExpiresAt  *string `json:"expires_at,omitempty"`
}

type PermissionCheckResponse struct {
	HasPermission bool   `json:"has_permission"`
	UserID        int32  `json:"user_id"`
	Permission    string `json:"permission"`
	Resource      string `json:"resource"`
	Action        string `json:"action"`
}

// RBAC Request structures

type CreateRoleRequest struct {
	Name        string `json:"name" binding:"required,min=2,max=50"`
	Description string `json:"description" binding:"max=500"`
}

type UpdateRoleRequest struct {
	Name        string `json:"name" binding:"required,min=2,max=50"`
	Description string `json:"description" binding:"max=500"`
}

type AssignRoleRequest struct {
	UserID    int32  `json:"user_id" binding:"required,min=1"`
	RoleID    int32  `json:"role_id" binding:"required,min=1"`
	ExpiresAt *int64 `json:"expires_at,omitempty"` // Unix timestamp
}

type CheckPermissionRequest struct {
	UserID     int32  `json:"user_id" binding:"required,min=1"`
	Permission string `json:"permission" binding:"required"`
}

type CheckResourceAccessRequest struct {
	UserID   int32  `json:"user_id" binding:"required,min=1"`
	Resource string `json:"resource" binding:"required"`
	Action   string `json:"action" binding:"required"`
}

// Conversion functions

func toRoleResponse(role rbac.Role) RoleResponse {
	permissions := make([]PermissionResponse, len(role.Permissions))
	for i, perm := range role.Permissions {
		permissions[i] = PermissionResponse{
			ID:          perm.ID,
			Name:        perm.Name,
			Resource:    perm.Resource,
			Action:      perm.Action,
			Description: perm.Description,
		}
	}

	return RoleResponse{
		ID:          role.ID,
		Name:        role.Name,
		Description: role.Description,
		Permissions: permissions,
		CreatedAt:   role.CreatedAt.Format(time.RFC3339),
		UpdatedAt:   role.UpdatedAt.Format(time.RFC3339),
	}
}

func toPermissionResponse(perm rbac.Permission) PermissionResponse {
	return PermissionResponse{
		ID:          perm.ID,
		Name:        perm.Name,
		Resource:    perm.Resource,
		Action:      perm.Action,
		Description: perm.Description,
	}
}

// Role Management Handlers

// @Summary     Create a new role
// @Description Create a new role in the system (admin only)
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Param       role body CreateRoleRequest true "Role information"
// @Success     201 {object} Response{data=RoleResponse} "Role created successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     403 {object} Response "Insufficient permissions"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/roles [post]
func (server *Server) createRole(ctx *gin.Context) {
	var req CreateRoleRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	role, err := server.rbacService.CreateRole(ctx, req.Name, req.Description)
	if err != nil {
		logger.Error("Failed to create role: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create role", err)
		return
	}

	response := toRoleResponse(*role)
	SuccessResponse(ctx, http.StatusCreated, "Role created successfully", response)
}

// @Summary     Get role by ID
// @Description Retrieve a role by its ID (admin only)
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Param       id path int true "Role ID"
// @Success     200 {object} Response{data=RoleResponse} "Role retrieved successfully"
// @Failure     400 {object} Response "Invalid role ID"
// @Failure     403 {object} Response "Insufficient permissions"
// @Failure     404 {object} Response "Role not found"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/roles/{id} [get]
func (server *Server) getRole(ctx *gin.Context) {
	roleID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid role ID", err)
		return
	}

	role, err := server.rbacService.GetRole(ctx, int32(roleID))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Role not found", err)
			return
		}
		logger.Error("Failed to get role: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve role", err)
		return
	}

	response := toRoleResponse(*role)
	SuccessResponse(ctx, http.StatusOK, "Role retrieved successfully", response)
}

// @Summary     List all roles
// @Description Get a list of all roles in the system (admin only)
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=[]RoleResponse} "Roles retrieved successfully"
// @Failure     403 {object} Response "Insufficient permissions"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/roles [get]
func (server *Server) listRoles(ctx *gin.Context) {
	roles, err := server.rbacService.ListRoles(ctx)
	if err != nil {
		logger.Error("Failed to list roles: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve roles", err)
		return
	}

	responses := make([]RoleResponse, len(roles))
	for i, role := range roles {
		responses[i] = toRoleResponse(role)
	}

	SuccessResponse(ctx, http.StatusOK, "Roles retrieved successfully", responses)
}

// @Summary     Update a role
// @Description Update an existing role (admin only)
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Param       id path int true "Role ID"
// @Param       role body UpdateRoleRequest true "Updated role information"
// @Success     200 {object} Response{data=RoleResponse} "Role updated successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     403 {object} Response "Insufficient permissions"
// @Failure     404 {object} Response "Role not found"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/roles/{id} [put]
func (server *Server) updateRole(ctx *gin.Context) {
	roleID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid role ID", err)
		return
	}

	var req UpdateRoleRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	role, err := server.rbacService.UpdateRole(ctx, int32(roleID), req.Name, req.Description)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Role not found", err)
			return
		}
		logger.Error("Failed to update role: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update role", err)
		return
	}

	response := toRoleResponse(*role)
	SuccessResponse(ctx, http.StatusOK, "Role updated successfully", response)
}

// @Summary     Delete a role
// @Description Delete a role from the system (admin only)
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Param       id path int true "Role ID"
// @Success     200 {object} Response "Role deleted successfully"
// @Failure     400 {object} Response "Invalid role ID"
// @Failure     403 {object} Response "Insufficient permissions"
// @Failure     404 {object} Response "Role not found"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/roles/{id} [delete]
func (server *Server) deleteRole(ctx *gin.Context) {
	roleID, err := strconv.ParseInt(ctx.Param("id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid role ID", err)
		return
	}

	err = server.rbacService.DeleteRole(ctx, int32(roleID))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "Role not found", err)
			return
		}
		logger.Error("Failed to delete role: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete role", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Role deleted successfully", nil)
}

// User Role Management Handlers

// @Summary     Assign role to user
// @Description Assign a role to a user (admin only)
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Param       assignment body AssignRoleRequest true "Role assignment information"
// @Success     200 {object} Response "Role assigned successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     403 {object} Response "Insufficient permissions"
// @Failure     404 {object} Response "User or role not found"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/user-roles [post]
func (server *Server) assignRole(ctx *gin.Context) {
	var req AssignRoleRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	// Get current user ID for assignment tracking
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ErrorResponse(ctx, http.StatusUnauthorized, "Authorization payload not found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusUnauthorized, "Invalid authorization payload", nil)
		return
	}

	var expiresAt *time.Time
	if req.ExpiresAt != nil {
		expTime := time.Unix(*req.ExpiresAt, 0)
		expiresAt = &expTime
	}

	err := server.rbacService.AssignRole(ctx, req.UserID, req.RoleID, authPayload.ID, expiresAt)
	if err != nil {
		logger.Error("Failed to assign role: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to assign role", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Role assigned successfully", nil)
}

// @Summary     Remove role from user
// @Description Remove a role from a user (admin only)
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Param       user_id path int true "User ID"
// @Param       role_id path int true "Role ID"
// @Success     200 {object} Response "Role removed successfully"
// @Failure     400 {object} Response "Invalid user or role ID"
// @Failure     403 {object} Response "Insufficient permissions"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/users/{user_id}/roles/{role_id} [delete]
func (server *Server) removeRole(ctx *gin.Context) {
	userID, err := strconv.ParseInt(ctx.Param("user_id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
		return
	}

	roleID, err := strconv.ParseInt(ctx.Param("role_id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid role ID", err)
		return
	}

	err = server.rbacService.RemoveRole(ctx, int32(userID), int32(roleID))
	if err != nil {
		logger.Error("Failed to remove role: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to remove role", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Role removed successfully", nil)
}

// @Summary     Get user roles
// @Description Get all roles assigned to a user
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Param       user_id path int true "User ID"
// @Success     200 {object} Response{data=[]RoleResponse} "User roles retrieved successfully"
// @Failure     400 {object} Response "Invalid user ID"
// @Failure     404 {object} Response "User not found"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/users/{user_id}/roles [get]
func (server *Server) getUserRoles(ctx *gin.Context) {
	userID, err := strconv.ParseInt(ctx.Param("user_id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
		return
	}

	// Check if requesting user can view this information
	if !server.canAccessUserInfo(ctx, int32(userID)) {
		ErrorResponse(ctx, http.StatusForbidden, "Insufficient permissions", nil)
		return
	}

	roles, err := server.rbacService.GetUserRoles(ctx, int32(userID))
	if err != nil {
		logger.Error("Failed to get user roles: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve user roles", err)
		return
	}

	responses := make([]RoleResponse, len(roles))
	for i, role := range roles {
		responses[i] = toRoleResponse(role)
	}

	SuccessResponse(ctx, http.StatusOK, "User roles retrieved successfully", responses)
}

// @Summary     Get user permissions
// @Description Get all permissions granted to a user through their roles
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Param       user_id path int true "User ID"
// @Success     200 {object} Response{data=[]PermissionResponse} "User permissions retrieved successfully"
// @Failure     400 {object} Response "Invalid user ID"
// @Failure     404 {object} Response "User not found"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/users/{user_id}/permissions [get]
func (server *Server) getUserPermissions(ctx *gin.Context) {
	userID, err := strconv.ParseInt(ctx.Param("user_id"), 10, 32)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
		return
	}

	// Check if requesting user can view this information
	if !server.canAccessUserInfo(ctx, int32(userID)) {
		ErrorResponse(ctx, http.StatusForbidden, "Insufficient permissions", nil)
		return
	}

	permissions, err := server.rbacService.GetUserPermissions(ctx, int32(userID))
	if err != nil {
		logger.Error("Failed to get user permissions: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve user permissions", err)
		return
	}

	responses := make([]PermissionResponse, len(permissions))
	for i, permission := range permissions {
		responses[i] = toPermissionResponse(permission)
	}

	SuccessResponse(ctx, http.StatusOK, "User permissions retrieved successfully", responses)
}

// Permission Check Handlers

// @Summary     Check user permission
// @Description Check if a user has a specific permission (admin only)
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Param       check body CheckPermissionRequest true "Permission check information"
// @Success     200 {object} Response{data=PermissionCheckResponse} "Permission check completed"
// @Failure     400 {object} Response "Invalid request"
// @Failure     403 {object} Response "Insufficient permissions"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/check-permission [post]
func (server *Server) checkPermission(ctx *gin.Context) {
	var req CheckPermissionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	check, err := server.rbacService.CheckPermission(ctx, req.UserID, req.Permission)
	if err != nil {
		logger.Error("Failed to check permission: %v", err)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to check permission", err)
		return
	}

	response := PermissionCheckResponse{
		HasPermission: check.HasPermission,
		UserID:        check.UserID,
		Permission:    check.Permission,
		Resource:      check.Resource,
		Action:        check.Action,
	}

	SuccessResponse(ctx, http.StatusOK, "Permission check completed", response)
}

// getUsersByRole returns all users assigned to a specific role
// @Summary     Get users by role
// @Description Retrieve all users assigned to a specific role (admin only)
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Param       roleName path string true "Role name"
// @Success     200 {object} Response{data=[]UserRoleAssignmentResponse} "Users retrieved successfully"
// @Failure     400 {object} Response "Invalid role name"
// @Failure     403 {object} Response "Insufficient permissions"
// @Failure     404 {object} Response "Role not found"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/roles/users/{roleName} [get]
func (server *Server) getUsersByRole(ctx *gin.Context) {
	roleName := ctx.Param("roleName")
	if roleName == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Role name is required",
			"code":    "RBAC_ROLE_NAME_REQUIRED",
		})
		return
	}

	users, err := server.rbacService.GetUsersByRole(ctx, roleName)
	if err != nil {
		logger.Error("Failed to get users by role %s: %v", roleName, err)
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Failed to retrieve users by role",
			"code":    "RBAC_GET_USERS_BY_ROLE_FAILED",
		})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"role":  roleName,
			"users": users,
		},
	})
}

// listPermissions returns all available permissions in the system
// @Summary     List permissions
// @Description Get a list of all permissions in the system (admin only)
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=[]PermissionResponse} "Permissions retrieved successfully"
// @Failure     403 {object} Response "Insufficient permissions"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/permissions [get]
func (server *Server) listPermissions(ctx *gin.Context) {
	permissions, err := server.rbacService.GetAllPermissions(ctx)
	if err != nil {
		logger.Error("Failed to list permissions: %v", err)
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Failed to retrieve permissions",
			"code":    "RBAC_LIST_PERMISSIONS_FAILED",
		})
		return
	}

	var permissionResponses []PermissionResponse
	for _, perm := range permissions {
		permissionResponses = append(permissionResponses, toPermissionResponse(perm))
	}

	ctx.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"permissions": permissionResponses,
			"total":       len(permissionResponses),
		},
	})
}

// assignPermissionToRole assigns a permission to a role
// @Summary     Assign permission to role
// @Description Assign a permission to a role (admin only)
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Param       role_id       path int32  true  "Role ID"
// @Param       permission_id  path int32  true  "Permission ID"
// @Success     200 {object} Response "Permission assigned successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     403 {object} Response "Insufficient permissions"
// @Failure     404 {object} Response "Role or permission not found"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/roles/{role_id}/permissions/{permission_id} [post]
func (server *Server) assignPermissionToRole(ctx *gin.Context) {
	type AssignPermissionRequest struct {
		RoleID       int32 `json:"role_id" binding:"required"`
		PermissionID int32 `json:"permission_id" binding:"required"`
	}

	var req AssignPermissionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request format",
			"code":    "RBAC_INVALID_REQUEST",
			"details": err.Error(),
		})
		return
	}

	// Get current user for audit trail
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Authentication required",
			"code":    "RBAC_AUTH_REQUIRED",
		})
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Invalid authentication token",
			"code":    "RBAC_INVALID_TOKEN",
		})
		return
	}

	err := server.rbacService.AssignPermissionToRole(ctx, req.RoleID, req.PermissionID, authPayload.ID)
	if err != nil {
		logger.Error("Failed to assign permission %d to role %d: %v", req.PermissionID, req.RoleID, err)
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Failed to assign permission to role",
			"code":    "RBAC_ASSIGN_PERMISSION_FAILED",
		})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Permission assigned to role successfully",
		"data": gin.H{
			"role_id":       req.RoleID,
			"permission_id": req.PermissionID,
			"assigned_by":   authPayload.ID,
			"assigned_at":   time.Now().Format(time.RFC3339),
		},
	})
}

// removePermissionFromRole removes a permission from a role
// @Summary     Remove permission from role
// @Description Remove a permission from a role (admin only)
// @Tags        rbac
// @Accept      json
// @Produce     json
// @Param       role_id       path int32  true  "Role ID"
// @Param       permission_id  path int32  true  "Permission ID"
// @Success     200 {object} Response "Permission removed successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     403 {object} Response "Insufficient permissions"
// @Failure     404 {object} Response "Role or permission not found"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/admin/roles/{role_id}/permissions/{permission_id} [delete]
func (server *Server) removePermissionFromRole(ctx *gin.Context) {
	type RemovePermissionRequest struct {
		RoleID       int32 `json:"role_id" binding:"required"`
		PermissionID int32 `json:"permission_id" binding:"required"`
	}

	var req RemovePermissionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request format",
			"code":    "RBAC_INVALID_REQUEST",
			"details": err.Error(),
		})
		return
	}

	err := server.rbacService.RemovePermissionFromRole(ctx, req.RoleID, req.PermissionID)
	if err != nil {
		logger.Error("Failed to remove permission %d from role %d: %v", req.PermissionID, req.RoleID, err)
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Failed to remove permission from role",
			"code":    "RBAC_REMOVE_PERMISSION_FAILED",
		})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Permission removed from role successfully",
		"data": gin.H{
			"role_id":       req.RoleID,
			"permission_id": req.PermissionID,
			"removed_at":    time.Now().Format(time.RFC3339),
		},
	})
}

// Helper functions

func (server *Server) canAccessUserInfo(ctx *gin.Context, targetUserID int32) bool {
	// Get current user
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		return false
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		return false
	}

	// Users can access their own information
	if authPayload.ID == targetUserID {
		return true
	}

	// Check if user has admin privileges
	check, err := server.rbacService.CheckPermission(ctx, authPayload.ID, rbac.PermUserRead)
	if err != nil {
		return false
	}

	return check.HasPermission
}
