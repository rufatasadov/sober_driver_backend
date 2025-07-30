const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth } = require('../middleware/auth');
const User = require('../models/User');

const router = express.Router();

// İstifadəçi profilini al
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-__v');
    
    res.json({
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        role: user.role,
        isVerified: user.isVerified,
        profileImage: user.profileImage,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    console.error('Profil alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// İstifadəçi profilini yenilə
router.put('/profile', auth, [
  body('name').optional().isLength({ min: 2 }).withMessage('Ad minimum 2 simvol olmalıdır'),
  body('email').optional().isEmail().withMessage('Düzgün email daxil edin')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, email } = req.body;
    const updates = {};

    if (name) updates.name = name;
    if (email) updates.email = email;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      updates,
      { new: true, runValidators: true }
    ).select('-__v');

    res.json({
      message: 'Profil uğurla yeniləndi',
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        role: user.role,
        isVerified: user.isVerified,
        profileImage: user.profileImage
      }
    });
  } catch (error) {
    console.error('Profil yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

module.exports = router; 