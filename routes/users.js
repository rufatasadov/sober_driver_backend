const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const User = require('../models/User');
const { Op } = require('sequelize');

const router = express.Router();

// Bütün istifadəçiləri al (admin üçün)
router.get('/', auth, authorize('admin'), async (req, res) => {
  try {
    const { page = 1, limit = 10, role, search } = req.query;
    const offset = (page - 1) * limit;

    const whereClause = {};
    
    if (role) {
      whereClause.role = role;
    }
    
    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { phone: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } }
      ];
    }

    const { count, rows: users } = await User.findAndCountAll({
      where: whereClause,
      attributes: { exclude: ['password'] },
      order: [['createdAt', 'DESC']],
      offset: parseInt(offset),
      limit: parseInt(limit)
    });

    res.json({
      users,
      pagination: {
        current: parseInt(page),
        total: Math.ceil(count / limit),
        hasNext: page * limit < count,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('İstifadəçilər alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// İstifadəçi məlumatlarını al
router.get('/:userId', auth, authorize('admin'), async (req, res) => {
  try {
    const user = await User.findByPk(req.params.userId, {
      attributes: { exclude: ['password'] }
    });

    if (!user) {
      return res.status(404).json({ error: 'İstifadəçi tapılmadı' });
    }

    res.json({ user });
  } catch (error) {
    console.error('İstifadəçi məlumatları alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// İstifadəçi rolunu yenilə
router.put('/:userId/role', auth, authorize('admin'), [
  body('role').isIn(['customer', 'driver', 'operator', 'dispatcher', 'admin']).withMessage('Düzgün rol seçin')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { role } = req.body;
    const user = await User.findByPk(req.params.userId);

    if (!user) {
      return res.status(404).json({ error: 'İstifadəçi tapılmadı' });
    }

    await user.update({ role });

    res.json({
      message: 'İstifadəçi rolu uğurla yeniləndi',
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        role: user.role
      }
    });
  } catch (error) {
    console.error('İstifadəçi rolu yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// İstifadəçini deaktiv et
router.put('/:userId/deactivate', auth, authorize('admin'), async (req, res) => {
  try {
    const user = await User.findByPk(req.params.userId);

    if (!user) {
      return res.status(404).json({ error: 'İstifadəçi tapılmadı' });
    }

    await user.update({ isActive: false });

    res.json({
      message: 'İstifadəçi uğurla deaktiv edildi',
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        isActive: user.isActive
      }
    });
  } catch (error) {
    console.error('İstifadəçi deaktiv etmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

module.exports = router; 
module.exports = router; 