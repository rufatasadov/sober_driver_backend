const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const Order = require('../models/Order');
const Driver = require('../models/Driver');
const User = require('../models/User');
const { findNearbyDrivers } = require('../utils/geolocation');
const { Op } = require('sequelize');

const router = express.Router();

// Dispetçer dashboard
router.get('/dashboard', auth, authorize('dispatcher'), async (req, res) => {
  try {
    // Aktiv sifarişlər
    const activeOrders = await Order.count({
      where: {
        status: {
          [Op.in]: ['pending', 'accepted', 'driver_assigned', 'driver_arrived', 'in_progress']
        }
      }
    });

    // Online sürücülər
    const onlineDrivers = await Driver.count({
      where: {
        isOnline: true,
        isAvailable: true
      }
    });

    // Bugünkü sifarişlər
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todayOrders = await Order.count({
      where: {
        createdAt: {
          [Op.gte]: today,
          [Op.lt]: tomorrow
        }
      }
    });

    const todayCompleted = await Order.count({
      where: {
        status: 'completed',
        createdAt: {
          [Op.gte]: today,
          [Op.lt]: tomorrow
        }
      }
    });

    // Son aktiv sifarişlər
    const recentActiveOrders = await Order.findAll({
      where: {
        status: {
          [Op.in]: ['pending', 'accepted', 'driver_assigned', 'driver_arrived', 'in_progress']
        }
      },
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['name', 'phone']
        },
        {
          model: Driver,
          as: 'driver',
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['name', 'phone']
            }
          ]
        }
      ],
      order: [['createdAt', 'DESC']],
      limit: 10
    });

    // Online sürücülərin siyahısı
    const onlineDriversList = await Driver.findAll({
      where: {
        isOnline: true
      },
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['name', 'phone']
        }
      ],
      attributes: ['currentLocation', 'rating', 'isAvailable', 'lastActive'],
      limit: 20
    });

    res.json({
      stats: {
        activeOrders,
        onlineDrivers,
        todayOrders,
        todayCompleted
      },
      recentActiveOrders,
      onlineDrivers: onlineDriversList
    });
  } catch (error) {
    console.error('Dispetçer dashboard xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Bütün aktiv sifarişləri al
router.get('/active-orders', auth, authorize('dispatcher'), async (req, res) => {
  try {
    const { page = 1, limit = 20, status } = req.query;
    const skip = (page - 1) * limit;

    const filter = {
      status: { $in: ['pending', 'accepted', 'driver_assigned', 'driver_arrived', 'in_progress'] }
    };

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
    console.error('Aktiv sifarişlər alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Online sürücüləri al
router.get('/online-drivers', auth, authorize('dispatcher'), async (req, res) => {
  try {
    const drivers = await Driver.findAll({
      where: {
        isOnline: true,
        isAvailable: true
      },
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['name', 'phone']
        }
      ],
      order: [['lastActive', 'DESC']]
    });

    res.json({
      drivers: drivers.map(driver => ({
        id: driver.id,
        name: driver.user.name,
        phone: driver.user.phone,
        location: driver.currentLocation,
        rating: driver.rating,
        isAvailable: driver.isAvailable,
        lastActive: driver.lastActive,
        vehicleInfo: driver.vehicleInfo
      }))
    });
  } catch (error) {
    console.error('Online sürücülər alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifarişi sürücüyə təyin et (manual)
router.post('/orders/:orderId/assign-driver', auth, authorize('dispatcher'), [
  body('driverId').notEmpty().withMessage('Sürücü ID tələb olunur')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { driverId } = req.body;
    const order = await Order.findByPk(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    if (order.status !== 'pending') {
      return res.status(400).json({ error: 'Bu sifariş artıq təyin edilib' });
    }

    // Sürücünü yoxla
    const driver = await Driver.findByPk(driverId, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['name', 'phone']
        }
      ]
    });
    if (!driver) {
      return res.status(404).json({ error: 'Sürücü tapılmadı' });
    }

    if (!driver.isOnline) {
      return res.status(400).json({ error: 'Sürücü online olmalıdır' });
    }

    // Sifarişi sürücüyə təyin et
    const timeline = order.timeline || [];
    timeline.push({
      status: 'driver_assigned',
      timestamp: new Date()
    });

    await order.update({
      driverId: driver.id,
      status: 'driver_assigned',
      timeline
    });

    // Sürücünü unavailable et
    await driver.update({ isAvailable: false });

    // Socket event emit et
    const io = req.app.get('io');
    if (io) {
      // Sürücüyə bildir
      io.to(`driver_${driver.userId}`).emit('new_order_assigned', {
        orderId: order.id,
        orderNumber: order.orderNumber,
        pickup: order.pickup,
        destination: order.destination,
        fare: order.fare,
        customer: {
          name: order.customer?.name || 'Müştəri',
          phone: order.customer?.phone || 'N/A'
        },
        etaMinutes: 15 // Default ETA
      });

      // Müştəriyə bildir
      io.to(`user_${order.customerId}`).emit('driver_assigned', {
        orderId: order.id,
        driver: {
          id: driver.id,
          name: driver.user.name,
          phone: driver.user.phone
        }
      });

      // Operator və dispetçerlərə bildir
      io.to('operators').emit('driver_assigned_to_order', { order });
      io.to('dispatchers').emit('driver_assigned_to_order', { order });
    }

    res.json({
      message: 'Sifariş uğurla sürücüyə təyin edildi',
      order: {
        id: order.id,
        orderNumber: order.orderNumber,
        status: order.status,
        driver: {
          id: driver.id,
          name: driver.user.name,
          phone: driver.user.phone
        }
      }
    });
  } catch (error) {
    console.error('Sürücü təyin etmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifariş statusunu yenilə
router.patch('/orders/:orderId/status', auth, authorize('dispatcher'), [
  body('status').isIn(['accepted', 'driver_assigned', 'driver_arrived', 'in_progress', 'completed', 'cancelled']).withMessage('Düzgün status seçin'),
  body('notes').optional().isString().withMessage('Qeydlər string olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { status, notes } = req.body;
    const order = await Order.findById(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
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
      timestamp: new Date()
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

// Sifariş məlumatlarını al
router.get('/orders/:orderId', auth, authorize('dispatcher'), async (req, res) => {
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

    res.json({ order });
  } catch (error) {
    console.error('Sifariş məlumatları alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücü məlumatlarını al
router.get('/drivers/:driverId', auth, authorize('dispatcher'), async (req, res) => {
  try {
    const driver = await Driver.findById(req.params.driverId)
      .populate('userId', 'name phone email')
      .select('-documents');

    if (!driver) {
      return res.status(404).json({ error: 'Sürücü tapılmadı' });
    }

    // Sürücünün aktiv sifarişlərini al
    const activeOrders = await Order.find({
      driver: driver._id,
      status: { $in: ['driver_assigned', 'driver_arrived', 'in_progress'] }
    })
    .populate('customer', 'name phone')
    .sort({ createdAt: -1 });

    res.json({
      driver,
      activeOrders
    });
  } catch (error) {
    console.error('Sürücü məlumatları alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücü statusunu yenilə
router.patch('/drivers/:driverId/status', auth, authorize('dispatcher'), [
  body('isOnline').optional().isBoolean().withMessage('Online status boolean olmalıdır'),
  body('isAvailable').optional().isBoolean().withMessage('Available status boolean olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { isOnline, isAvailable } = req.body;
    const updates = {};

    if (isOnline !== undefined) {
      updates.isOnline = isOnline;
    }
    if (isAvailable !== undefined) {
      updates.isAvailable = isAvailable;
    }

    const driver = await Driver.findByIdAndUpdate(
      req.params.driverId,
      updates,
      { new: true }
    ).populate('userId', 'name phone');

    if (!driver) {
      return res.status(404).json({ error: 'Sürücü tapılmadı' });
    }

    res.json({
      message: 'Sürücü statusu uğurla yeniləndi',
      driver: {
        id: driver._id,
        name: driver.userId.name,
        phone: driver.userId.phone,
        isOnline: driver.isOnline,
        isAvailable: driver.isAvailable
      }
    });
  } catch (error) {
    console.error('Sürücü status yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Real-time xəritə məlumatları
router.get('/map-data', auth, authorize('dispatcher'), async (req, res) => {
  try {
    // Aktiv sifarişlər
    const activeOrders = await Order.find({
      status: { $in: ['pending', 'accepted', 'driver_assigned', 'driver_arrived', 'in_progress'] }
    })
    .populate('customer', 'name phone')
    .populate({
      path: 'driver',
      populate: {
        path: 'userId',
        select: 'name phone'
      }
    })
    .select('pickup destination status driver customer');

    // Online sürücülər
    const onlineDrivers = await Driver.find({
      isOnline: true
    })
    .populate('userId', 'name phone')
    .select('currentLocation isAvailable vehicleInfo');

    res.json({
      orders: activeOrders.map(order => ({
        id: order._id,
        orderNumber: order.orderNumber,
        status: order.status,
        pickup: order.pickup,
        destination: order.destination,
        customer: order.customer,
        driver: order.driver
      })),
      drivers: onlineDrivers.map(driver => ({
        id: driver._id,
        name: driver.userId.name,
        phone: driver.userId.phone,
        location: driver.currentLocation,
        isAvailable: driver.isAvailable,
        vehicleInfo: driver.vehicleInfo
      }))
    });
  } catch (error) {
    console.error('Xəritə məlumatları alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

module.exports = router; 