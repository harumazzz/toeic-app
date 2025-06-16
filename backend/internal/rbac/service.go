package rbac

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/logger"
)

// Service provides RBAC functionality
type Service struct {
	store db.Querier
}

// NewService creates a new RBAC service
func NewService(store db.Querier) *Service {
	return &Service{
		store: store,
	}
}

// Permission represents a system permission
type Permission struct {
	ID          int32  `json:"id"`
	Name        string `json:"name"`
	Resource    string `json:"resource"`
	Action      string `json:"action"`
	Description string `json:"description"`
}

// Role represents a user role
type Role struct {
	ID          int32        `json:"id"`
	Name        string       `json:"name"`
	Description string       `json:"description"`
	Permissions []Permission `json:"permissions,omitempty"`
	CreatedAt   time.Time    `json:"created_at"`
	UpdatedAt   time.Time    `json:"updated_at"`
}

// UserRoleAssignment represents a user's role assignment
type UserRoleAssignment struct {
	UserID     int32      `json:"user_id"`
	RoleID     int32      `json:"role_id"`
	RoleName   string     `json:"role_name"`
	AssignedAt time.Time  `json:"assigned_at"`
	AssignedBy *int32     `json:"assigned_by,omitempty"`
	ExpiresAt  *time.Time `json:"expires_at,omitempty"`
}

// PermissionCheck represents the result of a permission check
type PermissionCheck struct {
	HasPermission bool   `json:"has_permission"`
	UserID        int32  `json:"user_id"`
	Permission    string `json:"permission"`
	Resource      string `json:"resource"`
	Action        string `json:"action"`
}

// Common permission constants
const (
	// User management permissions
	PermUserCreate = "users.create"
	PermUserRead   = "users.read"
	PermUserUpdate = "users.update"
	PermUserDelete = "users.delete"
	PermUserList   = "users.list"

	// Role management permissions
	PermRoleCreate = "roles.create"
	PermRoleRead   = "roles.read"
	PermRoleUpdate = "roles.update"
	PermRoleDelete = "roles.delete"
	PermRoleAssign = "roles.assign"

	// Content management permissions
	PermContentCreate  = "content.create"
	PermContentRead    = "content.read"
	PermContentUpdate  = "content.update"
	PermContentDelete  = "content.delete"
	PermContentPublish = "content.publish"

	// Exam management permissions
	PermExamCreate = "exams.create"
	PermExamRead   = "exams.read"
	PermExamUpdate = "exams.update"
	PermExamDelete = "exams.delete"
	PermExamGrade  = "exams.grade"

	// Writing management permissions
	PermWritingCreate   = "writing.create"
	PermWritingRead     = "writing.read"
	PermWritingUpdate   = "writing.update"
	PermWritingDelete   = "writing.delete"
	PermWritingEvaluate = "writing.evaluate"

	// Speaking management permissions
	PermSpeakingCreate   = "speaking.create"
	PermSpeakingRead     = "speaking.read"
	PermSpeakingUpdate   = "speaking.update"
	PermSpeakingDelete   = "speaking.delete"
	PermSpeakingEvaluate = "speaking.evaluate"

	// System administration permissions
	PermSystemBackup   = "system.backup"
	PermSystemRestore  = "system.restore"
	PermSystemMonitor  = "system.monitor"
	PermSystemSettings = "system.settings"

	// Analytics permissions
	PermAnalyticsView   = "analytics.view"
	PermAnalyticsExport = "analytics.export"
)

// Common role constants
const (
	RoleAdmin     = "admin"
	RoleTeacher   = "teacher"
	RoleStudent   = "student"
	RoleModerator = "moderator"
)

// CheckPermission checks if a user has a specific permission
func (s *Service) CheckPermission(ctx context.Context, userID int32, permission string) (*PermissionCheck, error) {
	hasPermission, err := s.store.CheckUserPermission(ctx, db.CheckUserPermissionParams{
		UserID: userID,
		Name:   permission,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to check permission: %w", err)
	}

	// Parse permission to get resource and action
	parts := strings.Split(permission, ".")
	var resource, action string
	if len(parts) == 2 {
		resource = parts[0]
		action = parts[1]
	}

	return &PermissionCheck{
		HasPermission: hasPermission,
		UserID:        userID,
		Permission:    permission,
		Resource:      resource,
		Action:        action,
	}, nil
}

// CheckPermissionByResourceAction checks if a user has permission for a specific resource and action
func (s *Service) CheckPermissionByResourceAction(ctx context.Context, userID int32, resource, action string) (*PermissionCheck, error) {
	hasPermission, err := s.store.CheckUserPermissionByResourceAction(ctx, db.CheckUserPermissionByResourceActionParams{
		UserID:   userID,
		Resource: resource,
		Action:   action,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to check permission by resource/action: %w", err)
	}

	permission := fmt.Sprintf("%s.%s", resource, action)

	return &PermissionCheck{
		HasPermission: hasPermission,
		UserID:        userID,
		Permission:    permission,
		Resource:      resource,
		Action:        action,
	}, nil
}

// GetUserRoles returns all roles assigned to a user
func (s *Service) GetUserRoles(ctx context.Context, userID int32) ([]Role, error) {
	roleRecords, err := s.store.GetUserRoles(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user roles: %w", err)
	}

	roles := make([]Role, len(roleRecords))
	for i, record := range roleRecords {
		roles[i] = Role{
			ID:          record.ID,
			Name:        record.Name,
			Description: record.Description.String,
			CreatedAt:   record.CreatedAt,
			UpdatedAt:   record.UpdatedAt,
		}
	}

	return roles, nil
}

// GetUserPermissions returns all permissions granted to a user through their roles
func (s *Service) GetUserPermissions(ctx context.Context, userID int32) ([]Permission, error) {
	permissionRecords, err := s.store.GetUserPermissions(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user permissions: %w", err)
	}

	permissions := make([]Permission, len(permissionRecords))
	for i, record := range permissionRecords {
		permissions[i] = Permission{
			ID:          record.ID,
			Name:        record.Name,
			Resource:    record.Resource,
			Action:      record.Action,
			Description: record.Description.String,
		}
	}

	return permissions, nil
}

// AssignRole assigns a role to a user
func (s *Service) AssignRole(ctx context.Context, userID, roleID, assignedBy int32, expiresAt *time.Time) error {
	var sqlExpiresAt sql.NullTime
	if expiresAt != nil {
		sqlExpiresAt = sql.NullTime{Time: *expiresAt, Valid: true}
	}

	var sqlAssignedBy sql.NullInt32
	if assignedBy > 0 {
		sqlAssignedBy = sql.NullInt32{Int32: assignedBy, Valid: true}
	}

	err := s.store.AssignRoleToUser(ctx, db.AssignRoleToUserParams{
		UserID:     userID,
		RoleID:     roleID,
		AssignedBy: sqlAssignedBy,
		ExpiresAt:  sqlExpiresAt,
	})
	if err != nil {
		return fmt.Errorf("failed to assign role to user: %w", err)
	}

	logger.Info("Role %d assigned to user %d by user %d", roleID, userID, assignedBy)
	return nil
}

// RemoveRole removes a role from a user
func (s *Service) RemoveRole(ctx context.Context, userID, roleID int32) error {
	err := s.store.RemoveRoleFromUser(ctx, db.RemoveRoleFromUserParams{
		UserID: userID,
		RoleID: roleID,
	})
	if err != nil {
		return fmt.Errorf("failed to remove role from user: %w", err)
	}

	logger.Info("Role %d removed from user %d", roleID, userID)
	return nil
}

// IsAdmin checks if a user has admin role
func (s *Service) IsAdmin(ctx context.Context, userID int32) (bool, error) {
	check, err := s.CheckPermission(ctx, userID, PermSystemSettings)
	if err != nil {
		return false, err
	}
	return check.HasPermission, nil
}

// HasRole checks if a user has a specific role
func (s *Service) HasRole(ctx context.Context, userID int32, roleName string) (bool, error) {
	roles, err := s.GetUserRoles(ctx, userID)
	if err != nil {
		return false, err
	}

	for _, role := range roles {
		if role.Name == roleName {
			return true, nil
		}
	}

	return false, nil
}

// GetRole retrieves a role by ID
func (s *Service) GetRole(ctx context.Context, roleID int32) (*Role, error) {
	roleRecord, err := s.store.GetRole(ctx, roleID)
	if err != nil {
		return nil, fmt.Errorf("failed to get role: %w", err)
	}
	role := &Role{
		ID:          roleRecord.ID,
		Name:        roleRecord.Name,
		Description: roleRecord.Description.String,
		CreatedAt:   roleRecord.CreatedAt,
		UpdatedAt:   roleRecord.UpdatedAt,
	}

	// Get role permissions
	permissionRecords, err := s.store.GetRolePermissions(ctx, roleID)
	if err != nil {
		return nil, fmt.Errorf("failed to get role permissions: %w", err)
	}

	permissions := make([]Permission, len(permissionRecords))
	for i, record := range permissionRecords {
		permissions[i] = Permission{
			ID:          record.ID,
			Name:        record.Name,
			Resource:    record.Resource,
			Action:      record.Action,
			Description: record.Description.String,
		}
	}
	role.Permissions = permissions

	return role, nil
}

// GetRoleByName retrieves a role by name
func (s *Service) GetRoleByName(ctx context.Context, roleName string) (*Role, error) {
	roleRecord, err := s.store.GetRoleByName(ctx, roleName)
	if err != nil {
		return nil, fmt.Errorf("failed to get role by name: %w", err)
	}

	return s.GetRole(ctx, roleRecord.ID)
}

// ListRoles returns all roles in the system
func (s *Service) ListRoles(ctx context.Context) ([]Role, error) {
	roleRecords, err := s.store.ListRoles(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to list roles: %w", err)
	}

	roles := make([]Role, len(roleRecords))
	for i, record := range roleRecords {
		roles[i] = Role{
			ID:          record.ID,
			Name:        record.Name,
			Description: record.Description.String,
			CreatedAt:   record.CreatedAt,
			UpdatedAt:   record.UpdatedAt,
		}
	}

	return roles, nil
}

// CreateRole creates a new role
func (s *Service) CreateRole(ctx context.Context, name, description string) (*Role, error) {
	roleRecord, err := s.store.CreateRole(ctx, db.CreateRoleParams{
		Name:        name,
		Description: sql.NullString{String: description, Valid: description != ""},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create role: %w", err)
	}

	role := &Role{
		ID:          roleRecord.ID,
		Name:        roleRecord.Name,
		Description: roleRecord.Description.String,
		CreatedAt:   roleRecord.CreatedAt,
		UpdatedAt:   roleRecord.UpdatedAt,
		Permissions: []Permission{},
	}

	logger.Info("Role created: %s (ID: %d)", name, roleRecord.ID)
	return role, nil
}

// UpdateRole updates an existing role
func (s *Service) UpdateRole(ctx context.Context, roleID int32, name, description string) (*Role, error) {
	roleRecord, err := s.store.UpdateRole(ctx, db.UpdateRoleParams{
		ID:          roleID,
		Name:        name,
		Description: sql.NullString{String: description, Valid: description != ""},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to update role: %w", err)
	}

	role := &Role{
		ID:          roleRecord.ID,
		Name:        roleRecord.Name,
		Description: roleRecord.Description.String,
		CreatedAt:   roleRecord.CreatedAt,
		UpdatedAt:   roleRecord.UpdatedAt,
	}

	logger.Info("Role updated: %s (ID: %d)", name, roleRecord.ID)
	return role, nil
}

// DeleteRole deletes a role
func (s *Service) DeleteRole(ctx context.Context, roleID int32) error {
	err := s.store.DeleteRole(ctx, roleID)
	if err != nil {
		return fmt.Errorf("failed to delete role: %w", err)
	}

	logger.Info("Role deleted: ID %d", roleID)
	return nil
}

// CleanupExpiredRoles removes expired role assignments
func (s *Service) CleanupExpiredRoles(ctx context.Context) error {
	err := s.store.CleanupExpiredRoles(ctx)
	if err != nil {
		return fmt.Errorf("failed to cleanup expired roles: %w", err)
	}

	logger.Info("Expired roles cleaned up")
	return nil
}

// GetUserRoleAssignments returns detailed role assignment information for a user
func (s *Service) GetUserRoleAssignments(ctx context.Context, userID int32) ([]UserRoleAssignment, error) {
	assignments, err := s.store.GetUserRoleAssignments(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user role assignments: %w", err)
	}

	result := make([]UserRoleAssignment, len(assignments))
	for i, assignment := range assignments {
		result[i] = UserRoleAssignment{
			UserID:     assignment.UserID,
			RoleID:     assignment.RoleID,
			RoleName:   assignment.RoleName,
			AssignedAt: assignment.AssignedAt,
		}

		if assignment.AssignedBy.Valid {
			result[i].AssignedBy = &assignment.AssignedBy.Int32
		}

		if assignment.ExpiresAt.Valid {
			result[i].ExpiresAt = &assignment.ExpiresAt.Time
		}
	}

	return result, nil
}

// EnsureUserHasRole ensures a user has a specific role, creating the assignment if it doesn't exist
func (s *Service) EnsureUserHasRole(ctx context.Context, userID int32, roleName string, assignedBy int32) error {
	role, err := s.GetRoleByName(ctx, roleName)
	if err != nil {
		return fmt.Errorf("failed to get role %s: %w", roleName, err)
	}

	hasRole, err := s.HasRole(ctx, userID, roleName)
	if err != nil {
		return fmt.Errorf("failed to check if user has role: %w", err)
	}

	if !hasRole {
		err = s.AssignRole(ctx, userID, role.ID, assignedBy, nil)
		if err != nil {
			return fmt.Errorf("failed to assign role %s to user: %w", roleName, err)
		}
		logger.Info("Assigned default role %s to user %d", roleName, userID)
	}

	return nil
}

// GetUsersByRole returns all users assigned to a specific role
func (s *Service) GetUsersByRole(ctx context.Context, roleName string) ([]int32, error) {
	users, err := s.store.GetUsersByRole(ctx, roleName)
	if err != nil {
		return nil, fmt.Errorf("failed to get users by role: %w", err)
	}

	// users is already []int32, so we can return it directly
	return users, nil
}

// GetAllPermissions returns all permissions in the system
func (s *Service) GetAllPermissions(ctx context.Context) ([]Permission, error) {
	permissionRecords, err := s.store.ListPermissions(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get all permissions: %w", err)
	}

	permissions := make([]Permission, len(permissionRecords))
	for i, record := range permissionRecords {
		permissions[i] = Permission{
			ID:          record.ID,
			Name:        record.Name,
			Resource:    record.Resource,
			Action:      record.Action,
			Description: record.Description.String,
		}
	}

	return permissions, nil
}

// AssignPermissionToRole assigns a permission to a role
func (s *Service) AssignPermissionToRole(ctx context.Context, roleID, permissionID, assignedBy int32) error {
	err := s.store.AssignPermissionToRole(ctx, db.AssignPermissionToRoleParams{
		RoleID:       roleID,
		PermissionID: permissionID,
	})
	if err != nil {
		return fmt.Errorf("failed to assign permission to role: %w", err)
	}

	logger.Info("Permission %d assigned to role %d by user %d", permissionID, roleID, assignedBy)
	return nil
}

// RemovePermissionFromRole removes a permission from a role
func (s *Service) RemovePermissionFromRole(ctx context.Context, roleID, permissionID int32) error {
	err := s.store.RemovePermissionFromRole(ctx, db.RemovePermissionFromRoleParams{
		RoleID:       roleID,
		PermissionID: permissionID,
	})
	if err != nil {
		return fmt.Errorf("failed to remove permission from role: %w", err)
	}

	logger.Info("Permission %d removed from role %d", permissionID, roleID)
	return nil
}
