const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth } = require('../middleware/auth');
const User = require('../models/User');

const router = express.Router();

// FCM token yenilə
router.post('/fcm-token', auth, [
  body('fcmToken').isString().withMessage('FCM token tələb olunur')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { fcmToken } = req.body;

    await req.user.update({ fcmToken });

    res.json({ message: 'FCM token uğurla yeniləndi' });
  } catch (error) {
    console.error('FCM token yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Bildiriş tərəfindən oxunma statusu
router.post('/mark-read', auth, [
  body('notificationIds').isArray().withMessage('Bildiriş ID-ləri array olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { notificationIds } = req.body;

    // Burada bildirişləri oxunmuş kimi qeyd edə bilərsiniz
    // Sadəlik üçün yalnız response qaytarırıq

    res.json({ 
      message: 'Bildirişlər oxunmuş kimi qeyd edildi',
      count: notificationIds.length
    });
  } catch (error) {
    console.error('Bildiriş statusu yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

module.exports = router; 