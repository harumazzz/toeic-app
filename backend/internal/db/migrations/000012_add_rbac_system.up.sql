-- Create roles table
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create permissions table
CREATE TABLE permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    resource VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create role_permissions junction table
CREATE TABLE role_permissions (
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    permission_id INTEGER REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    PRIMARY KEY (role_id, permission_id)
);

-- Create user_roles junction table
CREATE TABLE user_roles (
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    assigned_by INTEGER REFERENCES users(id),
    expires_at TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (user_id, role_id)
);

-- Add updated_at trigger for roles
CREATE TRIGGER update_roles_updated_at
BEFORE UPDATE ON roles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Insert default roles
INSERT INTO roles (name, description) VALUES
    ('admin', 'Full system administrator with all permissions'),
    ('teacher', 'Teaching staff with content management permissions'),
    ('student', 'Regular user with basic access permissions'),
    ('moderator', 'Content moderator with limited administrative permissions');

-- Insert default permissions
INSERT INTO permissions (name, resource, action, description) VALUES
    -- User management
    ('users.create', 'users', 'create', 'Create new users'),
    ('users.read', 'users', 'read', 'View user information'),
    ('users.update', 'users', 'update', 'Update user information'),
    ('users.delete', 'users', 'delete', 'Delete users'),
    ('users.list', 'users', 'list', 'List all users'),
    
    -- Role management
    ('roles.create', 'roles', 'create', 'Create new roles'),
    ('roles.read', 'roles', 'read', 'View role information'),
    ('roles.update', 'roles', 'update', 'Update role information'),
    ('roles.delete', 'roles', 'delete', 'Delete roles'),
    ('roles.assign', 'roles', 'assign', 'Assign roles to users'),
    
    -- Content management
    ('content.create', 'content', 'create', 'Create new content'),
    ('content.read', 'content', 'read', 'View content'),
    ('content.update', 'content', 'update', 'Update content'),
    ('content.delete', 'content', 'delete', 'Delete content'),
    ('content.publish', 'content', 'publish', 'Publish content'),
    
    -- Exam management
    ('exams.create', 'exams', 'create', 'Create new exams'),
    ('exams.read', 'exams', 'read', 'View exams'),
    ('exams.update', 'exams', 'update', 'Update exams'),
    ('exams.delete', 'exams', 'delete', 'Delete exams'),
    ('exams.grade', 'exams', 'grade', 'Grade exam attempts'),
    
    -- Writing management
    ('writing.create', 'writing', 'create', 'Create writing submissions'),
    ('writing.read', 'writing', 'read', 'View writing submissions'),
    ('writing.update', 'writing', 'update', 'Update writing submissions'),
    ('writing.delete', 'writing', 'delete', 'Delete writing submissions'),
    ('writing.evaluate', 'writing', 'evaluate', 'Evaluate writing submissions'),
    
    -- Speaking management
    ('speaking.create', 'speaking', 'create', 'Create speaking sessions'),
    ('speaking.read', 'speaking', 'read', 'View speaking sessions'),
    ('speaking.update', 'speaking', 'update', 'Update speaking sessions'),
    ('speaking.delete', 'speaking', 'delete', 'Delete speaking sessions'),
    ('speaking.evaluate', 'speaking', 'evaluate', 'Evaluate speaking sessions'),
    
    -- System administration
    ('system.backup', 'system', 'backup', 'Create system backups'),
    ('system.restore', 'system', 'restore', 'Restore system from backup'),
    ('system.monitor', 'system', 'monitor', 'Monitor system performance'),
    ('system.settings', 'system', 'settings', 'Manage system settings'),
    
    -- Analytics and reporting
    ('analytics.view', 'analytics', 'view', 'View analytics and reports'),
    ('analytics.export', 'analytics', 'export', 'Export analytics data');

-- Assign permissions to roles
-- Admin gets all permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id 
FROM roles r, permissions p 
WHERE r.name = 'admin';

-- Teacher permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id 
FROM roles r, permissions p 
WHERE r.name = 'teacher' 
AND p.name IN (
    'users.read', 'users.list',
    'content.create', 'content.read', 'content.update', 'content.publish',
    'exams.create', 'exams.read', 'exams.update', 'exams.grade',
    'writing.read', 'writing.evaluate',
    'speaking.read', 'speaking.evaluate',
    'analytics.view'
);

-- Student permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id 
FROM roles r, permissions p 
WHERE r.name = 'student' 
AND p.name IN (
    'content.read',
    'exams.read',
    'writing.create', 'writing.read', 'writing.update',
    'speaking.create', 'speaking.read', 'speaking.update'
);

-- Moderator permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id 
FROM roles r, permissions p 
WHERE r.name = 'moderator' 
AND p.name IN (
    'users.read', 'users.list', 'users.update',
    'content.read', 'content.update', 'content.delete',
    'exams.read', 'exams.update',
    'writing.read', 'writing.update', 'writing.delete',
    'speaking.read', 'speaking.update', 'speaking.delete',
    'analytics.view'
);

-- Assign default admin role to user with ID 1 (if exists)
INSERT INTO user_roles (user_id, role_id, assigned_by)
SELECT 1, r.id, 1
FROM roles r 
WHERE r.name = 'admin' 
AND EXISTS (SELECT 1 FROM users WHERE id = 1);

-- Create indexes for performance
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission_id ON role_permissions(permission_id);
CREATE INDEX idx_permissions_resource_action ON permissions(resource, action);
