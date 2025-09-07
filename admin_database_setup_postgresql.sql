-- Admin Database Setup Script for PostgreSQL
-- This script creates the necessary tables for role-based access control and parametric tables

-- Create roles table
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create privileges table
CREATE TABLE IF NOT EXISTS privileges (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create role_privileges junction table
CREATE TABLE IF NOT EXISTS role_privileges (
    id SERIAL PRIMARY KEY,
    role_id INTEGER NOT NULL,
    privilege_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (privilege_id) REFERENCES privileges(id) ON DELETE CASCADE,
    UNIQUE (role_id, privilege_id)
);

-- Create parametric_tables table
CREATE TABLE IF NOT EXISTS parametric_tables (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create parametric_table_columns table
CREATE TABLE IF NOT EXISTS parametric_table_columns (
    id SERIAL PRIMARY KEY,
    table_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    required BOOLEAN DEFAULT FALSE,
    unique BOOLEAN DEFAULT FALSE,
    options JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (table_id) REFERENCES parametric_tables(id) ON DELETE CASCADE,
    UNIQUE (table_id, name)
);

-- Insert default roles
INSERT INTO roles (name, description) VALUES
('admin', 'Full system administrator with all privileges'),
('operator', 'Operator with limited access to orders and customers'),
('dispatcher', 'Dispatcher with access to orders and drivers')
ON CONFLICT (name) DO NOTHING;

-- Insert default privileges
INSERT INTO privileges (name, description) VALUES
('admin.access', 'Access to admin panel'),
('users.read', 'Read user information'),
('users.create', 'Create new users'),
('users.update', 'Update existing users'),
('users.delete', 'Delete users'),
('roles.read', 'Read role information'),
('roles.create', 'Create new roles'),
('roles.update', 'Update existing roles'),
('roles.delete', 'Delete roles'),
('orders.read', 'Read order information'),
('orders.create', 'Create new orders'),
('orders.update', 'Update existing orders'),
('orders.delete', 'Delete orders'),
('drivers.read', 'Read driver information'),
('drivers.create', 'Create new drivers'),
('drivers.update', 'Update existing drivers'),
('drivers.delete', 'Delete drivers'),
('customers.read', 'Read customer information'),
('customers.create', 'Create new customers'),
('customers.update', 'Update existing customers'),
('customers.delete', 'Delete customers'),
('payments.read', 'Read payment information'),
('payments.create', 'Create new payments'),
('payments.update', 'Update existing payments'),
('payments.delete', 'Delete payments'),
('reports.read', 'Access to reports'),
('settings.read', 'Read system settings'),
('settings.update', 'Update system settings'),
('parametric_tables.read', 'Read parametric tables'),
('parametric_tables.create', 'Create new parametric tables'),
('parametric_tables.update', 'Update existing parametric tables'),
('parametric_tables.delete', 'Delete parametric tables')
ON CONFLICT (name) DO NOTHING;

-- Assign privileges to admin role
INSERT INTO role_privileges (role_id, privilege_id)
SELECT r.id, p.id
FROM roles r, privileges p
WHERE r.name = 'admin'
ON CONFLICT (role_id, privilege_id) DO NOTHING;

-- Assign privileges to operator role
INSERT INTO role_privileges (role_id, privilege_id)
SELECT r.id, p.id
FROM roles r, privileges p
WHERE r.name = 'operator' 
AND p.name IN (
    'orders.read', 'orders.create', 'orders.update',
    'customers.read', 'customers.create', 'customers.update',
    'drivers.read', 'drivers.update',
    'payments.read', 'reports.read'
)
ON CONFLICT (role_id, privilege_id) DO NOTHING;

-- Assign privileges to dispatcher role
INSERT INTO role_privileges (role_id, privilege_id)
SELECT r.id, p.id
FROM roles r, privileges p
WHERE r.name = 'dispatcher' 
AND p.name IN (
    'orders.read', 'orders.update',
    'drivers.read', 'drivers.update',
    'reports.read'
)
ON CONFLICT (role_id, privilege_id) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_roles_name ON roles(name);
CREATE INDEX IF NOT EXISTS idx_privileges_name ON privileges(name);
CREATE INDEX IF NOT EXISTS idx_role_privileges_role ON role_privileges(role_id);
CREATE INDEX IF NOT EXISTS idx_role_privileges_privilege ON role_privileges(privilege_id);
CREATE INDEX IF NOT EXISTS idx_parametric_tables_name ON parametric_tables(name);
CREATE INDEX IF NOT EXISTS idx_parametric_table_columns_table ON parametric_table_columns(table_id);

-- Add admin access privilege to existing users with admin role (if any)
-- This assumes you have a users table with a role_id field
-- UPDATE users SET role_id = (SELECT id FROM roles WHERE name = 'admin') WHERE role = 'admin';
