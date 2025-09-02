const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const db = require('../config/database');

// Middleware to check if user has admin privileges
const requireAdmin = (req, res, next) => {
  try {
    if (!req.user.role || !req.user.role.privileges.includes('admin.access')) {
      return res.status(403).json({ error: 'Admin access required' });
    }
    next();
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

// Get all roles
router.get('/roles', auth, requireAdmin, async (req, res) => {
  try {
    const [roles] = await db.query(`
      SELECT r.*, 
             JSON_ARRAYAGG(p.name) as privileges
      FROM roles r
      LEFT JOIN role_privileges rp ON r.id = rp.role_id
      LEFT JOIN privileges p ON rp.privilege_id = p.id
      GROUP BY r.id
    `);
    
    res.json({ roles });
  } catch (error) {
    console.error('Error fetching roles:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Create new role
router.post('/roles', auth, requireAdmin, [
  body('name').notEmpty().withMessage('Role name is required'),
  body('description').notEmpty().withMessage('Description is required'),
  body('privileges').isArray().withMessage('Privileges must be an array'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, description, privileges } = req.body;

    // Check if role already exists
    const [existingRole] = await db.query('SELECT id FROM roles WHERE name = ?', [name]);
    if (existingRole.length > 0) {
      return res.status(400).json({ error: 'Role with this name already exists' });
    }

    // Create role
    const [result] = await db.query(
      'INSERT INTO roles (name, description) VALUES (?, ?)',
      [name, description]
    );

    const roleId = result.insertId;

    // Add privileges
    for (const privilege of privileges) {
      await db.query(
        'INSERT INTO role_privileges (role_id, privilege_id) VALUES (?, ?)',
        [roleId, privilege]
      );
    }

    res.status(201).json({ message: 'Role created successfully', roleId });
  } catch (error) {
    console.error('Error creating role:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update role
router.put('/roles/:id', auth, requireAdmin, [
  body('name').notEmpty().withMessage('Role name is required'),
  body('description').notEmpty().withMessage('Description is required'),
  body('privileges').isArray().withMessage('Privileges must be an array'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const { name, description, privileges } = req.body;

    // Check if role exists
    const [existingRole] = await db.query('SELECT id FROM roles WHERE id = ?', [id]);
    if (existingRole.length === 0) {
      return res.status(404).json({ error: 'Role not found' });
    }

    // Update role
    await db.query(
      'UPDATE roles SET name = ?, description = ? WHERE id = ?',
      [name, description, id]
    );

    // Remove existing privileges
    await db.query('DELETE FROM role_privileges WHERE role_id = ?', [id]);

    // Add new privileges
    for (const privilege of privileges) {
      await db.query(
        'INSERT INTO role_privileges (role_id, privilege_id) VALUES (?, ?)',
        [id, privilege]
      );
    }

    res.json({ message: 'Role updated successfully' });
  } catch (error) {
    console.error('Error updating role:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete role
router.delete('/roles/:id', auth, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    // Check if role is assigned to any users
    const [usersWithRole] = await db.query('SELECT id FROM users WHERE role_id = ?', [id]);
    if (usersWithRole.length > 0) {
      return res.status(400).json({ error: 'Cannot delete role that is assigned to users' });
    }

    // Remove privileges
    await db.query('DELETE FROM role_privileges WHERE role_id = ?', [id]);

    // Delete role
    await db.query('DELETE FROM roles WHERE id = ?', [id]);

    res.json({ message: 'Role deleted successfully' });
  } catch (error) {
    console.error('Error deleting role:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all users
router.get('/users', auth, requireAdmin, async (req, res) => {
  try {
    const [users] = await db.query(`
      SELECT u.*, r.name as role_name, r.id as role_id
      FROM users u
      LEFT JOIN roles r ON u.role_id = r.id
      ORDER BY u.created_at DESC
    `);
    
    res.json({ users });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Create new user
router.post('/users', auth, requireAdmin, [
  body('name').notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('phone').notEmpty().withMessage('Phone is required'),
  body('roleId').notEmpty().withMessage('Role is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, email, phone, roleId, password } = req.body;

    // Check if user already exists
    const [existingUser] = await db.query('SELECT id FROM users WHERE email = ? OR phone = ?', [email, phone]);
    if (existingUser.length > 0) {
      return res.status(400).json({ error: 'User with this email or phone already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Create user
    const [result] = await db.query(
      'INSERT INTO users (name, email, phone, password, role_id) VALUES (?, ?, ?, ?, ?)',
      [name, email, phone, hashedPassword, roleId]
    );

    res.status(201).json({ message: 'User created successfully', userId: result.insertId });
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update user
router.put('/users/:id', auth, requireAdmin, [
  body('name').notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('phone').notEmpty().withMessage('Phone is required'),
  body('roleId').notEmpty().withMessage('Role is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const { name, email, phone, roleId } = req.body;

    // Check if user exists
    const [existingUser] = await db.query('SELECT id FROM users WHERE id = ?', [id]);
    if (existingUser.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if email/phone is already taken by another user
    const [duplicateUser] = await db.query(
      'SELECT id FROM users WHERE (email = ? OR phone = ?) AND id != ?',
      [email, phone, id]
    );
    if (duplicateUser.length > 0) {
      return res.status(400).json({ error: 'Email or phone already taken by another user' });
    }

    // Update user
    await db.query(
      'UPDATE users SET name = ?, email = ?, phone = ?, role_id = ? WHERE id = ?',
      [name, email, phone, roleId, id]
    );

    res.json({ message: 'User updated successfully' });
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete user
router.delete('/users/:id', auth, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    // Check if user exists
    const [existingUser] = await db.query('SELECT id FROM users WHERE id = ?', [id]);
    if (existingUser.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Delete user
    await db.query('DELETE FROM users WHERE id = ?', [id]);

    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all parametric tables
router.get('/parametric-tables', auth, requireAdmin, async (req, res) => {
  try {
    const [tables] = await db.query(`
      SELECT pt.*, 
             JSON_ARRAYAGG(
               JSON_OBJECT(
                 'name', ptc.name,
                 'type', ptc.type,
                 'required', ptc.required,
                 'unique', ptc.unique,
                 'options', ptc.options
               )
             ) as columns
      FROM parametric_tables pt
      LEFT JOIN parametric_table_columns ptc ON pt.id = ptc.table_id
      GROUP BY pt.id
    `);
    
    res.json({ tables });
  } catch (error) {
    console.error('Error fetching parametric tables:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Create new parametric table
router.post('/parametric-tables', auth, requireAdmin, [
  body('name').notEmpty().withMessage('Table name is required'),
  body('description').notEmpty().withMessage('Description is required'),
  body('columns').isArray().withMessage('Columns must be an array'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, description, columns } = req.body;

    // Check if table already exists
    const [existingTable] = await db.query('SELECT id FROM parametric_tables WHERE name = ?', [name]);
    if (existingTable.length > 0) {
      return res.status(400).json({ error: 'Table with this name already exists' });
    }

    // Create table
    const [result] = await db.query(
      'INSERT INTO parametric_tables (name, description) VALUES (?, ?)',
      [name, description]
    );

    const tableId = result.insertId;

    // Add columns
    for (const column of columns) {
      await db.query(
        'INSERT INTO parametric_table_columns (table_id, name, type, required, unique, options) VALUES (?, ?, ?, ?, ?, ?)',
        [
          tableId,
          column.name,
          column.type,
          column.required || false,
          column.unique || false,
          column.options ? JSON.stringify(column.options) : null
        ]
      );
    }

    res.status(201).json({ message: 'Parametric table created successfully', tableId });
  } catch (error) {
    console.error('Error creating parametric table:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update parametric table
router.put('/parametric-tables/:id', auth, requireAdmin, [
  body('name').notEmpty().withMessage('Table name is required'),
  body('description').notEmpty().withMessage('Description is required'),
  body('columns').isArray().withMessage('Columns must be an array'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const { name, description, columns } = req.body;

    // Check if table exists
    const [existingTable] = await db.query('SELECT id FROM parametric_tables WHERE id = ?', [id]);
    if (existingTable.length === 0) {
      return res.status(404).json({ error: 'Table not found' });
    }

    // Update table
    await db.query(
      'UPDATE parametric_tables SET name = ?, description = ? WHERE id = ?',
      [name, description, id]
    );

    // Remove existing columns
    await db.query('DELETE FROM parametric_table_columns WHERE table_id = ?', [id]);

    // Add new columns
    for (const column of columns) {
      await db.query(
        'INSERT INTO parametric_table_columns (table_id, name, type, required, unique, options) VALUES (?, ?, ?, ?, ?, ?)',
        [
          id,
          column.name,
          column.type,
          column.required || false,
          column.unique || false,
          column.options ? JSON.stringify(column.options) : null
        ]
      );
    }

    res.json({ message: 'Parametric table updated successfully' });
  } catch (error) {
    console.error('Error updating parametric table:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete parametric table
router.delete('/parametric-tables/:id', auth, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    // Check if table exists
    const [existingTable] = await db.query('SELECT id FROM parametric_tables WHERE id = ?', [id]);
    if (existingTable.length === 0) {
      return res.status(404).json({ error: 'Table not found' });
    }

    // Remove columns
    await db.query('DELETE FROM parametric_table_columns WHERE table_id = ?', [id]);

    // Delete table
    await db.query('DELETE FROM parametric_tables WHERE id = ?', [id]);

    res.json({ message: 'Parametric table deleted successfully' });
  } catch (error) {
    console.error('Error deleting parametric table:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router; 