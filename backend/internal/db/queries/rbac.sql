-- name: CreateRole :one
INSERT INTO roles (name, description)
VALUES ($1, $2)
RETURNING *;

-- name: GetRole :one
SELECT * FROM roles WHERE id = $1 LIMIT 1;

-- name: GetRoleByName :one
SELECT * FROM roles WHERE name = $1 LIMIT 1;

-- name: ListRoles :many
SELECT * FROM roles ORDER BY name;

-- name: UpdateRole :one
UPDATE roles
SET name = $2, description = $3, updated_at = NOW()
WHERE id = $1
RETURNING *;

-- name: DeleteRole :exec
DELETE FROM roles WHERE id = $1;

-- name: CreatePermission :one
INSERT INTO permissions (name, resource, action, description)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: GetPermission :one
SELECT * FROM permissions WHERE id = $1 LIMIT 1;

-- name: GetPermissionByName :one
SELECT * FROM permissions WHERE name = $1 LIMIT 1;

-- name: ListPermissions :many
SELECT * FROM permissions ORDER BY resource, action;

-- name: ListPermissionsByResource :many
SELECT * FROM permissions WHERE resource = $1 ORDER BY action;

-- name: UpdatePermission :one
UPDATE permissions
SET name = $2, resource = $3, action = $4, description = $5
WHERE id = $1
RETURNING *;

-- name: DeletePermission :exec
DELETE FROM permissions WHERE id = $1;

-- name: AssignPermissionToRole :exec
INSERT INTO role_permissions (role_id, permission_id)
VALUES ($1, $2)
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- name: RemovePermissionFromRole :exec
DELETE FROM role_permissions 
WHERE role_id = $1 AND permission_id = $2;

-- name: GetRolePermissions :many
SELECT p.* FROM permissions p
JOIN role_permissions rp ON p.id = rp.permission_id
WHERE rp.role_id = $1
ORDER BY p.resource, p.action;

-- name: AssignRoleToUser :exec
INSERT INTO user_roles (user_id, role_id, assigned_by, expires_at)
VALUES ($1, $2, $3, $4)
ON CONFLICT (user_id, role_id) DO UPDATE SET
    assigned_at = NOW(),
    assigned_by = $3,
    expires_at = $4;

-- name: RemoveRoleFromUser :exec
DELETE FROM user_roles 
WHERE user_id = $1 AND role_id = $2;

-- name: GetUserRoles :many
SELECT r.* FROM roles r
JOIN user_roles ur ON r.id = ur.role_id
WHERE ur.user_id = $1 
AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
ORDER BY r.name;

-- name: GetUserPermissions :many
SELECT DISTINCT p.* FROM permissions p
JOIN role_permissions rp ON p.id = rp.permission_id
JOIN user_roles ur ON rp.role_id = ur.role_id
WHERE ur.user_id = $1 
AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
ORDER BY p.resource, p.action;

-- name: CheckUserPermission :one
SELECT COUNT(*) > 0 as has_permission FROM permissions p
JOIN role_permissions rp ON p.id = rp.permission_id
JOIN user_roles ur ON rp.role_id = ur.role_id
WHERE ur.user_id = $1 
AND p.name = $2
AND (ur.expires_at IS NULL OR ur.expires_at > NOW());

-- name: CheckUserPermissionByResourceAction :one
SELECT COUNT(*) > 0 as has_permission FROM permissions p
JOIN role_permissions rp ON p.id = rp.permission_id
JOIN user_roles ur ON rp.role_id = ur.role_id
WHERE ur.user_id = $1 
AND p.resource = $2 
AND p.action = $3
AND (ur.expires_at IS NULL OR ur.expires_at > NOW());

-- name: ListUsersWithRole :many
SELECT u.* FROM users u
JOIN user_roles ur ON u.id = ur.user_id
WHERE ur.role_id = $1
AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
ORDER BY u.username;

-- name: GetUserRoleAssignments :many
SELECT ur.*, r.name as role_name, r.description as role_description
FROM user_roles ur
JOIN roles r ON ur.role_id = r.id
WHERE ur.user_id = $1
ORDER BY ur.assigned_at DESC;

-- name: CleanupExpiredRoles :exec
DELETE FROM user_roles 
WHERE expires_at IS NOT NULL AND expires_at <= NOW();

-- name: GetUsersByRole :many
SELECT ur.user_id FROM user_roles ur
JOIN roles r ON ur.role_id = r.id
WHERE r.name = $1
AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
ORDER BY ur.user_id;
