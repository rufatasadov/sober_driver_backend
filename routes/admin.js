const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const { sequelize } = require('../config/database');
const Setting = require('../models/Setting');
const Driver = require('../models/Driver');
const User = require('../models/User');

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
    const roles = await sequelize.query(`
      SELECT r.*, 
             COALESCE(
               JSON_AGG(p.name) FILTER (WHERE p.name IS NOT NULL), 
               '[]'::json
             ) as privileges
      FROM roles r
      LEFT JOIN role_privileges rp ON r.id = rp.role_id
      LEFT JOIN privileges p ON rp.privilege_id = p.id
      GROUP BY r.id
    `, {
      type: sequelize.QueryTypes.SELECT
    });
    
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
    const existingRole = await sequelize.query('SELECT id FROM roles WHERE name = \'${name}\'', {
      replacements: [name],
      type: sequelize.QueryTypes.SELECT
    });
    if (existingRole.length > 0) {
      return res.status(400).json({ error: 'Role with this name already exists' });
    }

    // Create role
    const result = await sequelize.query(
      'INSERT INTO roles (name, description) VALUES (\'${name}\', \'${description}\') RETURNING id',
      {
        replacements: [name, description],
        type: sequelize.QueryTypes.INSERT
      }
    );

    const roleId = result[0].id;

    // Add privileges
    for (const privilege of privileges) {
      await sequelize.query(
        'INSERT INTO role_privileges (role_id, privilege_id) VALUES (\'${roleId}\', \'${privilege}\')',
        {
          //replacements: [roleId, privilege],
          type: sequelize.QueryTypes.INSERT
        }
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
    const existingRole = await sequelize.query('SELECT id FROM roles WHERE id = \'${id}\'', {
      replacements: [id],
      type: sequelize.QueryTypes.SELECT
    });
    if (existingRole.length === 0) {
      return res.status(404).json({ error: 'Role not found' });
    }

    // Update role
    await sequelize.query(
      'UPDATE roles SET name = \'${name}\', description = \'${description}\' WHERE id = \'${id}\'',
      {
        //replacements: [name, description, id],
        type: sequelize.QueryTypes.UPDATE
      }
    );

    // Remove existing privileges
    await sequelize.query('DELETE FROM role_privileges WHERE role_id = \'${id}\'', {
      //replacements: [id],
      type: sequelize.QueryTypes.DELETE
    });

    // Add new privileges
    for (const privilege of privileges) {
      await sequelize.query(
        'INSERT INTO role_privileges (role_id, privilege_id) VALUES (\'${id}\', \'${privilege}\')',
        {
          //replacements: [id, privilege],
          type: sequelize.QueryTypes.INSERT
        }
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
      const usersWithRole = await sequelize.query('SELECT id FROM users WHERE role_id = \'${id}\'', {
      //replacements: [id],
      //replacements: [id],
      type: sequelize.QueryTypes.SELECT
    });
    if (usersWithRole.length > 0) {
      return res.status(400).json({ error: 'Cannot delete role that is assigned to users' });
    }

    // Remove privileges
    await sequelize.query('DELETE FROM role_privileges WHERE role_id = \'${id}\'', {
      //replacements: [id],
      type: sequelize.QueryTypes.DELETE
    });

    // Delete role
    await sequelize.query('DELETE FROM roles WHERE id = \'${id}\'', {
      //replacements: [id],
      type: sequelize.QueryTypes.DELETE
    });

    res.json({ message: 'Role deleted successfully' });
  } catch (error) {
    console.error('Error deleting role:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all users
router.get('/users', auth, requireAdmin, async (req, res) => {
  try {
    const users = await sequelize.query(`
      SELECT u.*, r.name as role_name, r.id as role_id
      FROM users u
      LEFT JOIN roles r ON u.role_id = r.id
      ORDER BY u.created_at DESC
    `, {
      type: sequelize.QueryTypes.SELECT
    });
    
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
    const existingUser = await sequelize.query('SELECT id FROM users WHERE email = \'${email}\' OR phone = \'${phone}\'', {
      replacements: [email, phone],
      type: sequelize.QueryTypes.SELECT
    });
    if (existingUser.length > 0) {
      return res.status(400).json({ error: 'User with this email or phone already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Create user
    const result = await sequelize.query(
      'INSERT INTO users (name, email, phone, password, role_id) VALUES (\'${name}\', \'${email}\', \'${phone}\', \'${hashedPassword}\', \'${roleId}\') RETURNING id',
      {
        //replacements: [name, email, phone, hashedPassword, roleId],
        type: sequelize.QueryTypes.INSERT
      }
    );

    res.status(201).json({ message: 'User created successfully', userId: result[0].id });
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
    const existingUser = await sequelize.query('SELECT id FROM users WHERE id = \'${id}\'', {
      replacements: [id],
      type: sequelize.QueryTypes.SELECT
    });
    if (existingUser.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if email/phone is already taken by another user
    const duplicateUser = await sequelize.query(
      'SELECT id FROM users WHERE (email = \'${email}\' OR phone = \'${phone}\') AND id != \'${id}\'',
      {
        //replacements: [email, phone, id],
        type: sequelize.QueryTypes.SELECT
      }
    );
    if (duplicateUser.length > 0) {
      return res.status(400).json({ error: 'Email or phone already taken by another user' });
    }

    // Update user
    await sequelize.query(
        'UPDATE users SET name = \'${name}\', email = \'${email}\', phone = \'${phone}\', role_id = \'${roleId}\' WHERE id = \'${id}\'',
      {
        //replacements: [name, email, phone, roleId, id],
        type: sequelize.QueryTypes.UPDATE
      }
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
    const existingUser = await sequelize.query('SELECT id FROM users WHERE id = \'${id}\'', {
      replacements: [id],
      type: sequelize.QueryTypes.SELECT
    });
    if (existingUser.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Delete user
      await sequelize.query('DELETE FROM users WHERE id = \'${id}\'', {
      replacements: [id],
      type: sequelize.QueryTypes.DELETE
    });

    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all settings
router.get('/settings', auth, requireAdmin, async (req, res) => {
  try {
    const settings = await Setting.findAll({
      order: [['key', 'ASC']]
    });
    
    res.json({ settings });
  } catch (error) {
    console.error('Error fetching settings:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get a specific setting by key
router.get('/settings/:key', auth, requireAdmin, async (req, res) => {
  try {
    const { key } = req.params;
    const value = await Setting.getValue(key);
    
    if (value === null) {
      return res.status(404).json({ error: 'Setting not found' });
    }
    
    res.json({ key, value });
  } catch (error) {
    console.error('Error fetching setting:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update a setting
router.put('/settings/:key', auth, requireAdmin, [
  body('value').notEmpty().withMessage('Value is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { key } = req.params;
    const { value, description } = req.body;

    await Setting.setValue(key, value, description);

    res.json({ 
      message: 'Setting updated successfully',
      key,
      value
    });
  } catch (error) {
    console.error('Error updating setting:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Create a new setting
router.post('/settings', auth, requireAdmin, [
  body('key').notEmpty().withMessage('Key is required'),
  body('value').notEmpty().withMessage('Value is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { key, value, description } = req.body;

    // Check if setting already exists
    const existingSetting = await Setting.findOne({ where: { key } });
    if (existingSetting) {
      return res.status(400).json({ error: 'Setting with this key already exists' });
    }

    const setting = await Setting.create({ key, value, description });

    res.status(201).json({ 
      message: 'Setting created successfully',
      setting
    });
  } catch (error) {
    console.error('Error creating setting:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete a setting
router.delete('/settings/:key', auth, requireAdmin, async (req, res) => {
  try {
    const { key } = req.params;

    const setting = await Setting.findOne({ where: { key } });
    if (!setting) {
      return res.status(404).json({ error: 'Setting not found' });
    }

    await setting.destroy();

    res.json({ message: 'Setting deleted successfully' });
  } catch (error) {
    console.error('Error deleting setting:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ==================== DRIVER BALANCE MANAGEMENT ====================

// Get all drivers with their balance information
router.get('/drivers/balance', auth, requireAdmin, async (req, res) => {
  try {
    const drivers = await Driver.findAll({
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'name', 'phone', 'email']
      }],
      attributes: ['id', 'licenseNumber', 'balance', 'status', 'isOnline', 'isAvailable'],
      order: [['balance', 'DESC']]
    });

    res.json({
      message: 'Drivers balance information retrieved successfully',
      drivers: drivers.map(driver => ({
        id: driver.id,
        userId: driver.userId,
        name: driver.user?.name || 'N/A',
        phone: driver.user?.phone || 'N/A',
        email: driver.user?.email || 'N/A',
        licenseNumber: driver.licenseNumber,
        balance: parseFloat(driver.balance),
        status: driver.status,
        isOnline: driver.isOnline,
        isAvailable: driver.isAvailable
      }))
    });
  } catch (error) {
    console.error('Error fetching drivers balance:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update driver balance (add or subtract)
router.patch('/drivers/:driverId/balance', auth, requireAdmin, [
  body('amount').isNumeric().withMessage('Amount must be a number'),
  body('operation').isIn(['add', 'subtract']).withMessage('Operation must be add or subtract'),
  body('reason').optional().isLength({ min: 3 }).withMessage('Reason must be at least 3 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { driverId } = req.params;
    const { amount, operation, reason } = req.body;

    const driver = await Driver.findByPk(driverId, {
      include: [{
        model: User,
        as: 'user',
        attributes: ['name', 'phone']
      }]
    });

    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    const currentBalance = parseFloat(driver.balance);
    let newBalance;

    if (operation === 'add') {
      newBalance = currentBalance + parseFloat(amount);
    } else {
      newBalance = currentBalance - parseFloat(amount);
      if (newBalance < 0) {
        return res.status(400).json({ error: 'Insufficient balance. Cannot subtract more than available balance.' });
      }
    }

    await driver.update({ balance: newBalance });

    // Log the transaction (you might want to create a separate transactions table)
    console.log(`Balance ${operation} for driver ${driverId}: ${amount} AZN. Reason: ${reason || 'No reason provided'}. New balance: ${newBalance}`);

    res.json({
      message: `Driver balance ${operation}ed successfully`,
      driver: {
        id: driver.id,
        name: driver.user?.name || 'N/A',
        phone: driver.user?.phone || 'N/A',
        licenseNumber: driver.licenseNumber,
        previousBalance: currentBalance,
        newBalance: newBalance,
        operation: operation,
        amount: parseFloat(amount),
        reason: reason
      }
    });
  } catch (error) {
    console.error('Error updating driver balance:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get driver balance history (if you implement transaction logging)
router.get('/drivers/:driverId/balance-history', auth, requireAdmin, async (req, res) => {
  try {
    const { driverId } = req.params;

    const driver = await Driver.findByPk(driverId, {
      include: [{
        model: User,
        as: 'user',
        attributes: ['name', 'phone']
      }]
    });

    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    // For now, return current balance. In a full implementation, you'd query a transactions table
    res.json({
      message: 'Driver balance history retrieved successfully',
      driver: {
        id: driver.id,
        name: driver.user?.name || 'N/A',
        phone: driver.user?.phone || 'N/A',
        licenseNumber: driver.licenseNumber,
        currentBalance: parseFloat(driver.balance)
      },
      transactions: [] // Placeholder for future transaction history
    });
  } catch (error) {
    console.error('Error fetching driver balance history:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
