const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { sequelize } = require('../config/database');

const auth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ error: 'Access denied. No token provided.' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get user with role and privileges using Sequelize
    const users = await sequelize.query(`
      SELECT u.*, r.name as role_name, r.id as role_id,
             COALESCE(
               JSON_AGG(p.name) FILTER (WHERE p.name IS NOT NULL), 
               '[]'::json
             ) as privileges
      FROM users u
      LEFT JOIN roles r ON u.role_id = r.id
      LEFT JOIN role_privileges rp ON r.id = rp.role_id
      LEFT JOIN privileges p ON rp.privilege_id = p.id
      WHERE u.id = $1
      GROUP BY u.id, r.id, r.name
    `, {
      replacements: [decoded.userId],
      type: sequelize.QueryTypes.SELECT
    });

    if (users.length === 0) {
      return res.status(401).json({ error: 'Invalid token. User not found.' });
    }

    const user = users[0];

    if (!user.isActive) {
      return res.status(401).json({ error: 'Account is deactivated.' });
    }

    // Structure user data for admin routes
    req.user = {
      ...user,
      role: {
        id: user.role_id,
        name: user.role_name,
        privileges: user.privileges || []
      }
    };
    req.token = token;
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(401).json({ error: 'Invalid token.' });
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Access denied. No token provided.' });
    }

    if (!roles.includes(req.user.role?.name)) {
      return res.status(403).json({ 
        error: 'Access denied. Insufficient permissions.' 
      });
    }

    next();
  };
};

module.exports = { auth, authorize }; 