const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth } = require('../middleware/auth');
const Order = require('../models/Order');

const router = express.Router();

// Ödəniş statusunu yenilə
router.patch('/orders/:orderId/status', auth, [
  body('status').isIn(['pending', 'paid', 'failed']).withMessage('Düzgün ödəniş statusu seçin'),
  body('transactionId').optional().isString().withMessage('Transaction ID string olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { status, transactionId } = req.body;
    const order = await Order.findById(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    // Yalnız sifariş sahibi və ya admin ödəniş statusunu dəyişə bilər
    if (order.customer.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Bu əməliyyatı yerinə yetirmə icazəniz yoxdur' });
    }

    order.payment.status = status;
    if (transactionId) {
      order.payment.transactionId = transactionId;
    }

    await order.save();

    res.json({
      message: 'Ödəniş statusu uğurla yeniləndi',
      payment: order.payment
    });
  } catch (error) {
    console.error('Ödəniş statusu yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Ödəniş məlumatlarını al
router.get('/orders/:orderId', auth, async (req, res) => {
  try {
    const order = await Order.findById(req.params.orderId)
      .select('payment fare');

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    // Yalnız sifariş sahibi və ya admin ödəniş məlumatlarını görə bilər
    if (order.customer.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Bu məlumatlara giriş icazəniz yoxdur' });
    }

    res.json({
      payment: order.payment,
      fare: order.fare
    });
  } catch (error) {
    console.error('Ödəniş məlumatları alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

module.exports = router; 