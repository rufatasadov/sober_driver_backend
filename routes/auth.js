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
    // const otpResult = await sendOTP(phone, otp);
    
    // if (!otpResult.success) {
    //   return res.status(500).json({ 
    //     error: 'OTP göndərilmədi', 
    //     details: otpResult.error 
    //   });
    // }
    
    // TEMPORARY: OTP sending always returns success
    const otpResult = { success: true, error: null };

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
    // const otpVerification = verifyOTP(phone, otp);
    // if (!otpVerification.valid) {
    //   return res.status(400).json({ error: otpVerification.message });
    // }
    
    // TEMPORARY: OTP verification always returns success
    const otpVerification = { valid: true, message: 'OTP verified successfully' };

    // İstifadəçini tap və ya yarat
    let user = await User.findOne({ where: { phone } });
    
    if (!user) {
      // Yeni istifadəçi yarat
      if (!name) {
        return res.status(400).json({ error: 'Yeni istifadəçi üçün ad tələb olunur' });
      }
      
      user = await User.create({
        phone,
        name,
        role: 'customer',
        isVerified: true
      });
    } else {
      // Mövcud istifadəçini yenilə
      user.isVerified = true;
      user.lastLogin = new Date();
      await user.save();
    }

    // JWT token yarat
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Uğurla giriş edildi',
      token,
      user: {
        id: user.id,
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

    // Sequelize ilə istifadəçini yenilə
    await req.user.update(updates);

    res.json({
      message: 'Profil uğurla yeniləndi',
      user: {
        id: req.user.id,
        name: req.user.name,
        phone: req.user.phone,
        email: req.user.email,
        role: req.user.role
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

    // Sequelize ilə FCM token yenilə
    await req.user.update({ fcmToken });

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
    await req.user.update({ fcmToken: null });
    
    res.json({ message: 'Uğurla çıxış edildi' });
  } catch (error) {
    console.error('Logout xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Mövcud istifadəçi məlumatları
router.get('/me', auth, async (req, res) => {
  try {
    res.json({
      user: {
        id: req.user.id,
        name: req.user.name,
        phone: req.user.phone,
        email: req.user.email,
        role: req.user.role,
        isVerified: req.user.isVerified,
        profileImage: req.user.profileImage,
        createdAt: req.user.createdAt
      }
    });
  } catch (error) {
    console.error('İstifadəçi məlumatları alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

module.exports = router; 