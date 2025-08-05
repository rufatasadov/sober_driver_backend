const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const Order = require('../models/Order');
const User = require('../models/User');
const Driver = require('../models/Driver');
const { 
  calculateDistance, 
  calculateFare, 
  estimateTravelTime,
  findNearbyDrivers 
} = require('../utils/geolocation');
const { Op } = require('sequelize');

const router = express.Router();

// Operator səhifəsi üçün əsas məlumatlar
router.get('/dashboard', auth, authorize('operator'), async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Bugünkü statistika
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

    const todayPending = await Order.count({
      where: {
        status: 'pending',
        createdAt: {
          [Op.gte]: today,
          [Op.lt]: tomorrow
        }
      }
    });

    const todayCancelled = await Order.count({
      where: {
        status: 'cancelled',
        createdAt: {
          [Op.gte]: today,
          [Op.lt]: tomorrow
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

    // Son sifarişlər
    const recentOrders = await Order.findAll({
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
              as: 'userId',
              attributes: ['name', 'phone']
            }
          ]
        }
      ],
      order: [['createdAt', 'DESC']],
      limit: 10
    });

    res.json({
      stats: {
        todayOrders,
        todayCompleted,
        todayPending,
        todayCancelled,
        onlineDrivers
      },
      recentOrders
    });
  } catch (error) {
    console.error('Dashboard məlumatları alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Yeni sifariş əlavə et (manual)
router.post('/orders', auth, authorize('operator'), [
  body('customerPhone').isMobilePhone('az-AZ').withMessage('Düzgün telefon nömrəsi daxil edin'),
  body('customerName').notEmpty().withMessage('Müştəri adı tələb olunur'),
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

    const { 
      customerPhone, 
      customerName, 
      pickup, 
      destination, 
      payment, 
      notes 
    } = req.body;

    // Müştərini tap və ya yarat
    let customer = await User.findOne({ where: { phone: customerPhone } });
    if (!customer) {
      customer = await User.create({
        phone: customerPhone,
        name: customerName,
        role: 'customer',
        isVerified: true
      });
    }

    // Məsafə və vaxt hesabla
    const distance = calculateDistance(
      pickup.coordinates[1], pickup.coordinates[0],
      destination.coordinates[1], destination.coordinates[0]
    );

    const estimatedTime = estimateTravelTime(distance);
    const fare = calculateFare(distance, estimatedTime);

    // Yeni sifariş yarat
    const order = await Order.create({
      customerId: customer.id,
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
    });

    res.status(201).json({
      message: 'Sifariş uğurla əlavə edildi',
      order: {
        id: order.id,
        orderNumber: order.orderNumber,
        customer: {
          name: customer.name,
          phone: customer.phone
        },
        pickup: order.pickup,
        destination: order.destination,
        estimatedTime,
        estimatedDistance: Math.round(distance * 100) / 100,
        fare,
        status: order.status
      }
    });
  } catch (error) {
    console.error('Manual sifariş əlavə etmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifarişi sürücüyə təyin et
router.post('/orders/:orderId/assign-driver', auth, authorize('operator'), [
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
    const driver = await Driver.findByPk(driverId);
    if (!driver) {
      return res.status(404).json({ error: 'Sürücü tapılmadı' });
    }

    if (!driver.isOnline || !driver.isAvailable) {
      return res.status(400).json({ error: 'Sürücü online və available olmalıdır' });
    }

    // Sifarişi sürücüyə təyin et
    order.driverId = driver.id;
    order.status = 'driver_assigned';
    order.timeline.push({
      status: 'driver_assigned',
      timestamp: new Date()
    });

    await order.save();

    // Sürücünü unavailable et
    driver.isAvailable = false;
    await driver.save();

    res.json({
      message: 'Sifariş uğurla sürücüyə təyin edildi',
      order: {
        id: order.id,
        orderNumber: order.orderNumber,
        status: order.status,
        driver: {
          id: driver.id,
          name: driver.userId.name,
          phone: driver.userId.phone
        }
      }
    });
  } catch (error) {
    console.error('Sürücü təyin etmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Yaxın sürücüləri tap
router.get('/nearby-drivers', auth, authorize('operator'), async (req, res) => {
  try {
    const { latitude, longitude, maxDistance = 5 } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({ error: 'Koordinatlar tələb olunur' });
    }

    const nearbyDrivers = await findNearbyDrivers(
      parseFloat(latitude),
      parseFloat(longitude),
      parseFloat(maxDistance)
    );

    res.json({
      drivers: nearbyDrivers.map(driver => ({
        id: driver._id,
        name: driver.userId.name,
        phone: driver.userId.phone,
        vehicleInfo: driver.vehicleInfo,
        rating: driver.rating,
        distance: driver.distance // əgər hesablanıbsa
      }))
    });
  } catch (error) {
    console.error('Yaxın sürücülər tapma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifarişlər siyahısı
router.get('/orders', auth, authorize('operator'), async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      status, 
      startDate, 
      endDate,
      customerPhone 
    } = req.query;
    
    const skip = (page - 1) * limit;
    const filter = {};

    if (status) filter.status = status;
    if (customerPhone) {
      const customer = await User.findOne({ where: { phone: customerPhone } });
      if (customer) {
        filter.customerId = customer.id;
      }
    }

    if (startDate && endDate) {
      filter.createdAt = {
        [Op.gte]: new Date(startDate),
        [Op.lte]: new Date(endDate)
      };
    }

    const orders = await Order.findAll({
      where: filter,
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
              as: 'userId',
              attributes: ['name', 'phone']
            }
          ]
        }
      ],
      order: [['createdAt', 'DESC']],
      offset: skip,
      limit: parseInt(limit)
    });

    const total = await Order.count({ where: filter });

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

// Sifariş məlumatlarını yenilə
router.put('/orders/:orderId', auth, authorize('operator'), [
  body('pickup.address').optional().notEmpty().withMessage('Pickup ünvanı boş ola bilməz'),
  body('destination.address').optional().notEmpty().withMessage('Təyinat ünvanı boş ola bilməz'),
  body('notes').optional().isString().withMessage('Qeydlər string olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { pickup, destination, notes } = req.body;
    const order = await Order.findByPk(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    const updates = {};
    if (pickup) {
      updates.pickup = pickup;
    }
    if (destination) {
      updates.destination = destination;
    }
    if (notes !== undefined) {
      updates.notes = notes;
    }

    const updatedOrder = await Order.update(
      updates,
      { where: { id: req.params.orderId }, returning: true }
    );

    res.json({
      message: 'Sifariş uğurla yeniləndi',
      order: updatedOrder[1][0]
    });
  } catch (error) {
    console.error('Sifariş yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Müştəri axtar
router.get('/customers/search', auth, authorize('operator'), async (req, res) => {
  try {
    const { phone, name } = req.query;
    const filter = {};

    if (phone) {
      filter.phone = { [Op.iLike]: `%${phone}%` };
    }
    if (name) {
      filter.name = { [Op.iLike]: `%${name}%` };
    }

    const customers = await User.findAll({
      where: filter,
      attributes: ['name', 'phone', 'email', 'createdAt']
    });

    res.json({ customers });
  } catch (error) {
    console.error('Müştəri axtarış xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Müştəri sifarişləri
router.get('/customers/:customerId/orders', auth, authorize('operator'), async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;

    const orders = await Order.findAll({
      where: { customerId: req.params.customerId },
      include: [
        {
          model: Driver,
          as: 'driver',
          include: [
            {
              model: User,
              as: 'userId',
              attributes: ['name', 'phone']
            }
          ]
        }
      ],
      order: [['createdAt', 'DESC']],
      offset: skip,
      limit: parseInt(limit)
    });

    const total = await Order.count({ where: { customerId: req.params.customerId } });

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
    console.error('Müştəri sifarişləri alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

module.exports = router; 