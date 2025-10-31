const express = require('express');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { Op } = require('sequelize');
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

// Operator login (username/password)
router.post('/operator-login', [
  body('username').notEmpty().withMessage('İstifadəçi adı tələb olunur'),
  body('password').notEmpty().withMessage('Şifrə tələb olunur')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, password } = req.body;

    // İstifadəçini tap
    const user = await User.findOne({ 
      where: { 
        username: username,
        role: ['operator', 'admin'] // Yalnız operator və admin istifadəçiləri
      } 
    });

    if (!user) {
      return res.status(401).json({ error: 'İstifadəçi adı və ya şifrə yanlışdır' });
    }

    // Şifrəni yoxla
    const bcrypt = require('bcryptjs');
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({ error: 'İstifadəçi adı və ya şifrə yanlışdır' });
    }

    // Son giriş vaxtını yenilə
    await user.update({
      lastLogin: new Date()
    });

    // JWT token yarat
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Uğurla daxil oldunuz',
      token,
      user: {
        id: user.id,
        name: user.name,
        username: user.username,
        role: user.role,
        phone: user.phone
      }
    });
  } catch (error) {
    console.error('Operator login xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Dispatcher login (username/password)
router.post('/dispatcher-login', [
  body('username').notEmpty().withMessage('İstifadəçi adı tələb olunur'),
  body('password').notEmpty().withMessage('Şifrə tələb olunur')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, password } = req.body;

    // İstifadəçini tap
    const user = await User.findOne({ 
      where: { 
        username: username,
        role: 'dispatcher' // Yalnız dispatcher istifadəçiləri
      } 
    });

    if (!user) {
      return res.status(401).json({ error: 'İstifadəçi adı və ya şifrə yanlışdır' });
    }

    // Şifrəni yoxla
    const bcrypt = require('bcryptjs');
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({ error: 'İstifadəçi adı və ya şifrə yanlışdır' });
    }

    // Son giriş vaxtını yenilə
    await user.update({
      lastLogin: new Date()
    });

    // JWT token yarat
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Uğurla daxil oldunuz',
      token,
      user: {
        id: user.id,
        name: user.name,
        username: user.username,
        role: user.role,
        phone: user.phone
      }
    });
  } catch (error) {
    console.error('Dispatcher login xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Create user account (for direct registration)
router.post('/create-user', [
  body('name').notEmpty().withMessage('Ad tələb olunur'),
  body('phone').isMobilePhone('az-AZ').withMessage('Düzgün telefon nömrəsi daxil edin'),
  body('username').notEmpty().withMessage('İstifadəçi adı tələb olunur'),
  body('password').isLength({ min: 6 }).withMessage('Şifrə minimum 6 simvol olmalıdır'),
  body('role').optional().isIn(['customer', 'driver']).withMessage('Düzgün rol seçin')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, phone, username, password, role = 'driver' } = req.body;

    // İstifadəçi adının və telefon nömrəsinin mövcudluğunu yoxla
    const existingUser = await User.findOne({
      where: {
        [Op.or]: [
          { username: username },
          { phone: phone }
        ]
      }
    });

    if (existingUser) {
      if (existingUser.username === username) {
        return res.status(400).json({ error: 'Bu istifadəçi adı artıq mövcuddur' });
      }
      if (existingUser.phone === phone) {
        return res.status(400).json({ error: 'Bu telefon nömrəsi artıq mövcuddur' });
      }
    }

    // Şifrəni hash et
    const bcrypt = require('bcryptjs');
    const hashedPassword = await bcrypt.hash(password, 10);

    // Yeni istifadəçi yarat
    const user = await User.create({
      name,
      phone,
      username,
      password: hashedPassword,
      role,
      isVerified: true,
      isActive: true
    });

    // JWT token yarat
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: 'İstifadəçi uğurla yaradıldı',
      token,
      user: {
        id: user.id,
        name: user.name,
        username: user.username,
        phone: user.phone,
        role: user.role,
        isVerified: user.isVerified
      }
    });
  } catch (error) {
    console.error('İstifadəçi yaratma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Driver login (username/password)
router.post('/driver-login', [
  body('username').notEmpty().withMessage('İstifadəçi adı tələb olunur'),
  body('password').notEmpty().withMessage('Şifrə tələb olunur')
], async (req, res) => {
  try {
    console.log('📨 Raw request received');
    console.log('📨 Content-Type:', req.headers['content-type']);
    console.log('📨 Raw body:', JSON.stringify(req.body));
    
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, password } = req.body;
    
    console.log('🔐 Driver login attempt for username:', username);
    console.log('📝 Password received:', password ? password.substring(0, 3) + '***' : 'null');
    console.log('📝 Full request body:', JSON.stringify(req.body));
    console.log('📝 Password type:', typeof password);
    console.log('📝 Password length:', password ? password.length : 0);

    // İstifadəçini tap
    const user = await User.findOne({ 
      where: { 
        username: username,
        role: 'driver' // Yalnız driver istifadəçiləri
      } 
    });

    if (!user) {
      console.log('❌ User not found:', username);
      return res.status(401).json({ error: 'İstifadəçi adı və ya şifrə yanlışdır' });
    }
    console.log('✅ User found:', username);
    console.log('📝 Stored password hash:', user.password ? user.password.substring(0, 20) + '...' : 'null');
    console.log('📝 Received password:', password ? password.substring(0, 3) + '***' : 'null');

    // Şifrəni yoxla
    const bcrypt = require('bcryptjs');
    const isPasswordValid = await bcrypt.compare(password, user.password);
    
    console.log('✅ Password comparison result:', isPasswordValid);

    if (!isPasswordValid) {
      console.log('❌ Password mismatch for user:', username);
      return res.status(401).json({ error: 'İstifadəçi adı və ya şifrə yanlışdır' });
    }
    
    console.log('✅ Login successful for:', username);

    // Son giriş vaxtını yenilə
    await user.update({
      lastLogin: new Date()
    });

    // JWT token yarat
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Driver məlumatını tap
    const Driver = require('../models/Driver');
    const driver = await Driver.findOne({ 
      where: { userId: user.id },
      include: [{ model: User, as: 'user' }]
    });
    
    console.log('🚗 Driver found:', driver ? 'Yes' : 'No');
    if (driver) {
      console.log('🚗 Driver isActive status:', driver.isActive);
      console.log('🚗 Driver isOnline status:', driver.isOnline);
    }

    // Check if driver is active - if not, return error (activation must be done from admin panel)
    if (driver && driver.isActive === false) {
      console.log('❌ Driver account is deactivated - activation must be done from admin panel');
      return res.status(403).json({ 
        error: 'Hesabınız deaktivdir. Zəhmət olmasa admin paneldən aktivləşdirin.',
        isDeactivated: true 
      });
    }
    
    console.log('✅ Driver is active, proceeding with login');
    
    // Set driver online when app opens (login)
    if (driver) {
      console.log('🔄 Setting driver to online...');
      console.log('🔄 Before update - isOnline:', driver.isOnline);
      
      try {
        await driver.update({
          isOnline: true,
          lastActive: new Date()
        });
        console.log('✅ Driver update completed');
        
        await driver.reload();
        console.log('✅ Driver reload completed');
        console.log('✅ After update - isOnline:', driver.isOnline);
        console.log('✅ Driver set to online successfully');
      } catch (updateError) {
        console.error('❌ Error updating driver to online:', updateError);
        console.error('❌ Update error details:', updateError.message);
      }
    } else {
      console.log('⚠️ Driver not found, cannot set to online');
    }

    res.json({
      message: 'Uğurla daxil oldunuz',
      token,
      user: {
        id: user.id,
        name: user.name,
        username: user.username,
        role: user.role,
        phone: user.phone
      },
      driver: driver ? {
        id: driver.id,
        licenseNumber: driver.licenseNumber,
        isActive: driver.isActive,
        isOnline: driver.isOnline,
        isAvailable: driver.isAvailable,
        status: driver.status,
        actualAddress: driver.actualAddress,
        licenseExpiryDate: driver.licenseExpiryDate,
        identityCardFront: driver.identityCardFront,
        identityCardBack: driver.identityCardBack,
        licenseFront: driver.licenseFront,
        licenseBack: driver.licenseBack
      } : null
    });
  } catch (error) {
    console.error('Driver login xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Admin login (username/password)
router.post('/admin-login', [
  body('username').notEmpty().withMessage('İstifadəçi adı tələb olunur'),
  body('password').notEmpty().withMessage('Şifrə tələb olunur')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, password } = req.body;

    // İstifadəçini tap
    const user = await User.findOne({ 
      where: { 
        username: username,
        role: 'admin' // Yalnız admin istifadəçiləri
      } 
    });

    if (!user) {
      return res.status(401).json({ error: 'İstifadəçi adı və ya şifrə yanlışdır' });
    }

    // Şifrəni yoxla
    const bcrypt = require('bcryptjs');
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({ error: 'İstifadəçi adı və ya şifrə yanlışdır' });
    }

    // Son giriş vaxtını yenilə
    await user.update({
      lastLogin: new Date()
    });

    // JWT token yarat
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Uğurla daxil oldunuz',
      token,
      user: {
        id: user.id,
        name: user.name,
        username: user.username,
        role: user.role,
        phone: user.phone
      }
    });
  } catch (error) {
    console.error('Admin login xətası:', error);
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
      await user.update({
        isVerified: true,
        lastLogin: new Date()
      });
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
    const user = await User.findByPk(req.user.id);
    if (user) {
      await user.update(updates);
    }

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
    const user = await User.findByPk(req.user.id);
    if (user) {
      await user.update({ fcmToken });
    }

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
    const user = await User.findByPk(req.user.id);
    if (user) {
      await user.update({ fcmToken: null });
    }
    
    // If driver, set offline when logging out
    if (req.user.role === 'driver') {
      const Driver = require('../models/Driver');
      const driver = await Driver.findOne({ where: { userId: req.user.id } });
      if (driver) {
        await driver.update({
          isOnline: false,
          isAvailable: false
        });
        console.log('✅ Driver set to offline on logout');
      }
    }
    
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

// Send password reset code
router.post('/send-reset-code', async (req, res) => {
  try {
    const { phone, email, username } = req.body;
    
    console.log('📥 Send reset code request body:', req.body);

    // Find user by username, phone, or email
    const whereClause = {};
    if (username) {
      whereClause.username = username;
    } else if (phone) {
      whereClause.phone = phone.replace(/\s/g, '');
    } else if (email) {
      whereClause.email = email;
    } else {
      console.log('❌ No username, phone, or email provided');
      return res.status(400).json({ error: 'Username, phone, or email is required' });
    }
    
    console.log('🔍 Searching user with:', whereClause);

    const user = await User.findOne({ where: whereClause });

    if (!user) {
      return res.status(404).json({ error: 'User not found with this phone or email' });
    }

    // TODO: Implement actual OTP sending via SMS/Email
    // For now, just return success with test code
    const resetCode = '123456'; // Test code

    // Store reset code temporarily (in production, use Redis or database)
    // For now, we'll just send the test code

    res.json({
      message: 'Reset code sent successfully',
      testCode: resetCode, // For testing only - remove in production
      expiresIn: '10 minutes'
    });
  } catch (error) {
    console.error('Send reset code error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Verify reset code
router.post('/verify-reset-code', async (req, res) => {
  try {
    const { phone, email, code } = req.body;

    // Find user by phone or email
    const whereClause = {};
    if (phone) {
      whereClause.phone = phone.replace(/\s/g, '');
    } else if (email) {
      whereClause.email = email;
    } else {
      return res.status(400).json({ error: 'Phone or email is required' });
    }

    const user = await User.findOne({ where: whereClause });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Verify code (for now, test code is always 123456)
    if (code !== '123456') {
      return res.status(400).json({ error: 'Invalid reset code' });
    }

    // TODO: In production, verify actual OTP from storage

    res.json({
      message: 'Code verified successfully',
      verified: true
    });
  } catch (error) {
    console.error('Verify reset code error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Reset password
router.post('/reset-password', async (req, res) => {
  try {
    const { phone, email, username, code, newPassword } = req.body;
    
    console.log('🔄 Password reset request for username:', username);
    console.log('📝 New password length:', newPassword ? newPassword.length : 0);

    // Find user by username, phone, or email
    const whereClause = {};
    if (username) {
      whereClause.username = username;
    } else if (phone) {
      whereClause.phone = phone.replace(/\s/g, '');
    } else if (email) {
      whereClause.email = email;
    } else {
      return res.status(400).json({ error: 'Username, phone, or email is required' });
    }
    
    console.log('🔍 Searching user with:', whereClause);

    const user = await User.findOne({ where: whereClause });

    if (!user) {
      console.log('❌ User not found for password reset');
      return res.status(404).json({ error: 'User not found' });
    }
    
    console.log('✅ User found:', user.username);

    // Verify code (for now, test code is always 123456)
    if (code !== '123456') {
      console.log('❌ Invalid reset code:', code);
      return res.status(400).json({ error: 'Invalid reset code' });
    }

    // Update password - User model will automatically hash it in beforeUpdate hook
    // So we just pass the plain text password
    console.log('🔐 Updating password (plain text - will be hashed by model):', newPassword ? newPassword.substring(0, 3) + '***' : 'null');
    
    await user.update({ password: newPassword });
    
    console.log('✅ Password updated successfully for user:', user.username);
    console.log('✅ Password was hashed by User model before saving');

    res.json({
      message: 'Password reset successfully',
      success: true
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router; 