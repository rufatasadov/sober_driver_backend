const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth } = require('../middleware/auth');
const Order = require('../models/Order');

const router = express.Router();

// Ödəniş məlumatlarını al
router.get('/order/:orderId', auth, async (req, res) => {
  try {
    const order = await Order.findByPk(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    // Yalnız sifariş sahibi və ya təyin edilmiş sürücü görə bilər
    if (order.customerId !== req.user.id && 
        (!order.driverId || order.driverId !== req.user.id)) {
      return res.status(403).json({ error: 'Bu sifarişə giriş icazəniz yoxdur' });
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

// Ödəniş statusunu yenilə
router.post('/order/:orderId/process', auth, [
  body('method').isIn(['cash', 'card', 'online']).withMessage('Düzgün ödəniş üsulu seçin'),
  body('transactionId').optional().isString().withMessage('Transaction ID düzgün formatda olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { method, transactionId } = req.body;
    const order = await Order.findByPk(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    if (order.status !== 'completed') {
      return res.status(400).json({ error: 'Yalnız tamamlanmış sifarişlər üçün ödəniş edə bilərsiniz' });
    }

    // Ödəniş statusunu yenilə
    const paymentData = {
      method,
      status: 'completed',
      transactionId: transactionId || null,
      completedAt: new Date()
    };

    await order.update({ payment: paymentData });

    res.json({
      message: 'Ödəniş uğurla tamamlandı',
      payment: paymentData
    });
  } catch (error) {
    console.error('Ödəniş emal etmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Ödənişi ləğv et
router.post('/order/:orderId/refund', auth, [
  body('reason').isLength({ min: 3 }).withMessage('Ləğv səbəbi minimum 3 simvol olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { reason } = req.body;
    const order = await Order.findByPk(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    if (order.payment.status !== 'completed') {
      return res.status(400).json({ error: 'Yalnız tamamlanmış ödənişlər ləğv edilə bilər' });
    }

    // Ödəniş statusunu yenilə
    const paymentData = {
      ...order.payment,
      status: 'refunded',
      refundReason: reason,
      refundedAt: new Date()
    };

    await order.update({ payment: paymentData });

    res.json({
      message: 'Ödəniş uğurla ləğv edildi',
      payment: paymentData
    });
  } catch (error) {
    console.error('Ödəniş ləğv etmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

module.exports = router; 