const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const Order = require('../models/Order');
const Driver = require('../models/Driver');
const { 
  calculateDistance, 
  calculateFare, 
  estimateTravelTime,
  findNearbyDrivers 
} = require('../utils/geolocation');

const router = express.Router();

// Yeni sifariş yarat
router.post('/', auth, [
  body('pickup.coordinates').isArray({ min: 2, max: 2 }).withMessage('Pickup koordinatları tələb olunur'),
  body('pickup.address').notEmpty().withMessage('Pickup ünvanı tələb olunur'),
  body('destination.coordinates').isArray({ min: 2, max: 2 }).withMessage('Təyinat koordinatları tələb olunur'),
  body('destination.address').notEmpty().withMessage('Təyinat ünvanı tələb olunur'),
  body('payment.method').isIn(['cash', 'card', 'online']).withMessage('Düzgün ödəniş üsulu seçin')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { pickup, destination, payment, notes } = req.body;

    // Məsafə və vaxt hesabla
    const distance = calculateDistance(
      pickup.coordinates[1], pickup.coordinates[0],
      destination.coordinates[1], destination.coordinates[0]
    );

    const estimatedTime = estimateTravelTime(distance);
    const fare = calculateFare(distance, estimatedTime);

    // Yeni sifariş yarat
    console.log('Creating order with user:', {
      userId: req.user.id,
      userRole: req.user.role
    });
    
    const orderData = {
      customerId: req.user.id, // Sequelize üçün customerId istifadə et
      pickup: {
        location: {
          type: 'Point',
          coordinates: pickup.coordinates
        },
        address: pickup.address,
        instructions: pickup.instructions
      },
      destination: {
        location: {
          type: 'Point',
          coordinates: destination.coordinates
        },
        address: destination.address,
        instructions: destination.instructions
      },
      estimatedTime,
      estimatedDistance: distance,
      fare,
      payment: {
        method: payment.method,
        status: 'pending'
      },
      notes,
      timeline: [{
        status: 'pending',
        timestamp: new Date(),
        location: {
          type: 'Point',
          coordinates: pickup.coordinates
        }
      }]
    };
    
    console.log('Order data to create:', orderData);
    
    const order = await Order.create(orderData);

    // Yaxın sürücüləri tap
    const nearbyDrivers = await findNearbyDrivers(
      pickup.coordinates[1], 
      pickup.coordinates[0]
    );

    res.status(201).json({
      message: 'Sifariş uğurla yaradıldı',
      order: {
        id: order.id, // Sequelize üçün id istifadə et
        orderNumber: order.orderNumber,
        status: order.status,
        estimatedTime,
        estimatedDistance: Math.round(distance * 100) / 100,
        fare,
        nearbyDrivers: nearbyDrivers.length
      }
    });
  } catch (error) {
    console.error('Sifariş yaratma xətası:', error);
    console.error('Request user:', req.user);
    console.error('Request body:', req.body);
    
    if (error.name === 'ValidationError') {
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.errors 
      });
    }
    
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifariş məlumatlarını al
router.get('/:orderId', auth, async (req, res) => {
  try {
    const order = await Order.findById(req.params.orderId)
      .populate('customer', 'name phone')
      .populate({
        path: 'driver',
        populate: {
          path: 'userId',
          select: 'name phone'
        }
      });

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    // Yalnız sifariş sahibi və ya təyin edilmiş sürücü görə bilər
    if (order.customer._id.toString() !== req.user._id.toString() && 
        (!order.driver || order.driver.userId._id.toString() !== req.user._id.toString())) {
      return res.status(403).json({ error: 'Bu sifarişə giriş icazəniz yoxdur' });
    }

    res.json({ order });
  } catch (error) {
    console.error('Sifariş məlumatları alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// İstifadəçinin sifarişləri
router.get('/', auth, async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const skip = (page - 1) * limit;

    const filter = {};
    
    if (req.user.role === 'customer') {
      filter.customer = req.user._id;
    } else if (req.user.role === 'driver') {
      const driver = await Driver.findOne({ userId: req.user._id });
      if (driver) {
        filter.driver = driver._id;
      }
    }

    if (status) {
      filter.status = status;
    }

    const orders = await Order.find(filter)
      .populate('customer', 'name phone')
      .populate({
        path: 'driver',
        populate: {
          path: 'userId',
          select: 'name phone'
        }
      })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Order.countDocuments(filter);

    res.json({
      orders,
      pagination: {
        current: parseInt(page),
        total: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('Sifarişlər alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifariş statusunu yenilə
router.patch('/:orderId/status', auth, [
  body('status').isIn(['accepted', 'driver_assigned', 'driver_arrived', 'in_progress', 'completed', 'cancelled']).withMessage('Düzgün status seçin'),
  body('location').optional().isArray({ min: 2, max: 2 }).withMessage('Koordinatlar düzgün formatda olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { status, location, notes } = req.body;
    const order = await Order.findById(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    // Status dəyişikliyi icazəsini yoxla
    const canUpdateStatus = 
      req.user.role === 'admin' ||
      req.user.role === 'operator' ||
      req.user.role === 'dispatcher' ||
      order.customer.toString() === req.user._id.toString() ||
      (order.driver && order.driver.toString() === req.user._id.toString());

    if (!canUpdateStatus) {
      return res.status(403).json({ error: 'Status dəyişdirmə icazəniz yoxdur' });
    }

    // Status dəyişikliyi məntiqini yoxla
    const validTransitions = {
      pending: ['accepted', 'cancelled'],
      accepted: ['driver_assigned', 'cancelled'],
      driver_assigned: ['driver_arrived', 'cancelled'],
      driver_arrived: ['in_progress', 'cancelled'],
      in_progress: ['completed', 'cancelled'],
      completed: [],
      cancelled: []
    };

    if (!validTransitions[order.status].includes(status)) {
      return res.status(400).json({ 
        error: `Status ${order.status}-dən ${status}-ə keçid mümkün deyil` 
      });
    }

    // Status yenilə
    order.status = status;
    
    // Timeline-ə əlavə et
    order.timeline.push({
      status,
      timestamp: new Date(),
      location: location ? {
        type: 'Point',
        coordinates: location
      } : undefined
    });

    if (notes) {
      order.notes = notes;
    }

    await order.save();

    res.json({
      message: 'Status uğurla yeniləndi',
      order: {
        id: order._id,
        status: order.status,
        timeline: order.timeline
      }
    });
  } catch (error) {
    console.error('Status yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifarişi ləğv et
router.post('/:orderId/cancel', auth, [
  body('reason').optional().isLength({ min: 3 }).withMessage('Ləğv səbəbi minimum 3 simvol olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { reason } = req.body;
    const order = await Order.findById(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    // Ləğv etmə icazəsini yoxla
    if (order.customer.toString() !== req.user._id.toString() && 
        req.user.role !== 'admin' && 
        req.user.role !== 'operator') {
      return res.status(403).json({ error: 'Sifarişi ləğv etmə icazəniz yoxdur' });
    }

    if (order.status === 'completed' || order.status === 'cancelled') {
      return res.status(400).json({ error: 'Bu sifariş artıq tamamlanıb və ya ləğv edilib' });
    }

    order.status = 'cancelled';
    order.cancelledBy = req.user.role === 'customer' ? 'customer' : 'operator';
    order.cancellationReason = reason;

    order.timeline.push({
      status: 'cancelled',
      timestamp: new Date()
    });

    await order.save();

    res.json({
      message: 'Sifariş uğurla ləğv edildi',
      order: {
        id: order._id,
        status: order.status,
        cancelledBy: order.cancelledBy,
        cancellationReason: order.cancellationReason
      }
    });
  } catch (error) {
    console.error('Sifariş ləğv etmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifarişə qiymətləndirmə ver
router.post('/:orderId/rate', auth, [
  body('rating').isInt({ min: 1, max: 5 }).withMessage('Qiymətləndirmə 1-5 arasında olmalıdır'),
  body('comment').optional().isLength({ max: 500 }).withMessage('Şərh maksimum 500 simvol ola bilər')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { rating, comment } = req.body;
    const order = await Order.findById(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    if (order.status !== 'completed') {
      return res.status(400).json({ error: 'Yalnız tamamlanmış sifarişlərə qiymətləndirmə verə bilərsiniz' });
    }

    // Qiymətləndirmə verən istifadəçini müəyyən et
    const isCustomer = order.customer.toString() === req.user._id.toString();
    const isDriver = order.driver && order.driver.toString() === req.user._id.toString();

    if (!isCustomer && !isDriver) {
      return res.status(403).json({ error: 'Bu sifarişə qiymətləndirmə vermə icazəniz yoxdur' });
    }

    // Qiymətləndirməni əlavə et
    if (isCustomer) {
      order.rating.customerRating = {
        rating,
        comment,
        createdAt: new Date()
      };
    } else if (isDriver) {
      order.rating.driverRating = {
        rating,
        comment,
        createdAt: new Date()
      };
    }

    await order.save();

    res.json({
      message: 'Qiymətləndirmə uğurla əlavə edildi',
      rating: {
        rating,
        comment,
        createdAt: new Date()
      }
    });
  } catch (error) {
    console.error('Qiymətləndirmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

module.exports = router; 