const express = require('express');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const { generateOTP, sendOTP, storeOTP, verifyOTP } = require('../utils/otp');

const router = express.Router();

// OTP göndər
router.post('/send-otp', [
  body('phone').isMobilePhone('az-AZ').withMessage('Düzgün telefon nömrəsi daxil edin')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { phone } = req.body;
    
    // OTP yaradıb göndər
    const otp = generateOTP();
    const otpResult = await sendOTP(phone, otp);
    
    if (!otpResult.success) {
      return res.status(500).json({ 
        error: 'OTP göndərilmədi', 
        details: otpResult.error 
      });
    }

    // OTP-ni saxla
    storeOTP(phone, otp);

    res.json({ 
      message: 'OTP uğurla göndərildi',
      phone: phone
    });
  } catch (error) {
    console.error('OTP göndərmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// OTP ilə login/qeydiyyat
router.post('/verify-otp', [
  body('phone').isMobilePhone('az-AZ').withMessage('Düzgün telefon nömrəsi daxil edin'),
  body('otp').isLength({ min: 6, max: 6 }).withMessage('OTP 6 rəqəm olmalıdır'),
  body('name').optional().isLength({ min: 2 }).withMessage('Ad minimum 2 simvol olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { phone, otp, name } = req.body;

    // OTP yoxla
    const otpVerification = verifyOTP(phone, otp);
    if (!otpVerification.valid) {
      return res.status(400).json({ error: otpVerification.message });
    }

    // İstifadəçini tap və ya yarat
    let user = await User.findOne({ phone });
    
    if (!user) {
      // Yeni istifadəçi yarat
      if (!name) {
        return res.status(400).json({ error: 'Yeni istifadəçi üçün ad tələb olunur' });
      }
      
      user = new User({
        phone,
        name,
        role: 'customer',
        isVerified: true
      });
      await user.save();
    } else {
      // Mövcud istifadəçini yenilə
      user.isVerified = true;
      user.lastLogin = new Date();
      await user.save();
    }

    // JWT token yarat
    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Uğurla giriş edildi',
      token,
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        isVerified: user.isVerified
      }
    });
  } catch (error) {
    console.error('OTP yoxlama xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Profil məlumatlarını yenilə
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
    );

    res.json({
      message: 'Profil uğurla yeniləndi',
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Profil yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// FCM token yenilə
router.put('/fcm-token', auth, [
  body('fcmToken').notEmpty().withMessage('FCM token tələb olunur')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { fcmToken } = req.body;

    await User.findByIdAndUpdate(req.user._id, { fcmToken });

    res.json({ message: 'FCM token uğurla yeniləndi' });
  } catch (error) {
    console.error('FCM token yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Logout
router.post('/logout', auth, async (req, res) => {
  try {
    // FCM token-i təmizlə
    await User.findByIdAndUpdate(req.user._id, { fcmToken: null });
    
    res.json({ message: 'Uğurla çıxış edildi' });
  } catch (error) {
    console.error('Logout xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Mövcud istifadəçi məlumatları
router.get('/me', auth, async (req, res) => {
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
    console.error('İstifadəçi məlumatları alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

module.exports = router; 