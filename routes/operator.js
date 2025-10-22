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
router.get('/dashboard', auth, authorize('admin', 'operator', 'dispatcher'), async (req, res) => {
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
              as: 'user',
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

// Sifarişi sürücüyə təyin et
router.post('/orders/:orderId/assign-driver', auth, authorize('admin', 'operator', 'dispatcher'), [
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
      include: [{ model: User, as: 'user' }]
    });
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

    // Socket event emit et
    const io = req.app.get('io');
    console.log('Operator: Socket io object:', io ? 'Available' : 'Not available');
    if (io) {
      console.log(`Operator: Emitting new_order_assigned to driver_${driver.userId}`);
      // Sürücüyə bildir
      io.to(`driver_${driver.userId}`).emit('new_order_assigned', {
        id: order.id,
        orderNumber: order.orderNumber,
        customerId: order.customerId,
        driverId: order.driverId,
        pickup: order.pickup,
        destination: order.destination,
        status: order.status,
        estimatedTime: order.estimatedTime,
        estimatedDistance: order.estimatedDistance,
        fare: order.fare,
        paymentMethod: order.payment?.method || 'cash',
        notes: order.notes,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        customer: {
          name: order.customer?.name || 'Müştəri',
          phone: order.customer?.phone || 'N/A'
        },
        customerPhone: order.customer?.phone || 'N/A',
        etaMinutes: 15 // Default ETA
      });

      // Müştəriyə bildir
      io.to(`user_${order.customerId}`).emit('driver_assigned', {
        orderId: order.id,
        driver: {
          id: driver.id,
          name: driver.user?.name || 'N/A',
          phone: driver.user?.phone || 'N/A'
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
          name: driver.user?.name || 'N/A',
          phone: driver.user?.phone || 'N/A '
        }
      }
    });
  } catch (error) {
    console.error('Sürücü təyin etmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Yaxın sürücüləri tap
router.get('/nearby-drivers', auth, authorize('admin', 'operator', 'dispatcher'), async (req, res) => {
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
        name: driver.user.name,
        phone: driver.user.phone,
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
router.get('/orders', auth, authorize('admin', 'operator', 'dispatcher'), async (req, res) => {
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
              as: 'user',
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
router.put('/orders/:orderId', auth, authorize('admin', 'operator', 'dispatcher'), [
  body('pickup.address').optional().notEmpty().withMessage('Pickup ünvanı boş ola bilməz'),
  body('destination.address').optional().notEmpty().withMessage('Təyinat ünvanı boş ola bilməz'),
  body('notes').optional().isString().withMessage('Qeydlər string olmalıdır'),
  body('status')
    .optional()
    .isIn(['pending','accepted','driver_assigned','driver_arrived','in_progress','completed','cancelled'])
    .withMessage('Yanlış status dəyəri')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { pickup, destination, notes, status } = req.body;
    const order = await Order.findByPk(req.params.orderId, { include: [{ model: Driver, as: 'driver' }] });

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    // Restrict operator from editing if order is already accepted by driver or beyond
    const userRole = (req.user && (req.user.role?.name || req.user.role)) || 'operator';
    const lockedStatuses = ['accepted', 'driver_assigned', 'driver_arrived', 'in_progress', 'completed'];
    if (userRole === 'operator' && lockedStatuses.includes(order.status)) {
      return res.status(403).json({ error: 'Operator bu statusda sifarişi redaktə edə bilməz' });
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
    if (status) {
      updates.status = status;
    }

    const updatedOrder = await Order.update(
      updates,
      { where: { id: req.params.orderId }, returning: true }
    );

    // Append to timeline when status changes
    if (status && status !== order.status) {
      const fresh = await Order.findByPk(req.params.orderId);
      const tl = Array.isArray(fresh.timeline) ? fresh.timeline : [];
      tl.push({
        status,
        timestamp: new Date(),
        by: { id: req.user?.id, role: req.user?.role || 'operator' }
      });
      await Order.update({ timeline: tl }, { where: { id: req.params.orderId } });
    }

    // If status moved to completed/cancelled -> free up driver
    const newStatus = updates.status || order.status;
    if ((newStatus === 'completed' || newStatus === 'cancelled') && order.driverId) {
      const driver = await Driver.findByPk(order.driverId);
      if (driver) {
        driver.isAvailable = true;
        await driver.save();
      }
    }

    // Return fresh order with associations and updated timeline
    const result = await Order.findByPk(req.params.orderId, {
      include: [
        { model: User, as: 'customer', attributes: ['name', 'phone'] },
        { model: Driver, as: 'driver', include: [{ model: User, as: 'user', attributes: ['name', 'phone'] }] }
      ]
    });

    res.json({
      message: 'Sifariş uğurla yeniləndi',
      order: result
    });
  } catch (error) {
    console.error('Sifariş yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Müştəri axtar
router.get('/customers/search', auth, authorize('admin', 'operator', 'dispatcher'), async (req, res) => {
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

// Müştəri siyahısı
router.get('/customers', auth, authorize('admin', 'operator', 'dispatcher'), async (req, res) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const offset = (page - 1) * limit;

    const whereClause = {};
    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { phone: { [Op.iLike]: `%${search}%` } }
      ];
    }

    const { count, rows: customers } = await User.findAndCountAll({
      where: {
        ...whereClause,
        role: 'customer'
      },
      attributes: [
        'id', 'name', 'phone', 'email', 'createdAt', 'lastLogin'
      ],
      order: [['createdAt', 'DESC']],
      offset: parseInt(offset),
      limit: parseInt(limit)
    });

    // Hər müştəri üçün sifariş statistikası
    const customersWithStats = await Promise.all(
      customers.map(async (customer) => {
        const totalOrders = await Order.count({
          where: { customerId: customer.id }
        });

        const completedOrders = await Order.findAll({
          where: { 
            customerId: customer.id,
            status: 'completed'
          },
          attributes: ['fare']
        });

        const totalSpent = completedOrders.reduce((sum, order) => {
          const fareTotal = order.fare?.total || 0;
          return sum + parseFloat(fareTotal);
        }, 0);

        const lastOrder = await Order.findOne({
          where: { customerId: customer.id },
          order: [['createdAt', 'DESC']],
          attributes: ['createdAt']
        });

        return {
          ...customer.toJSON(),
          totalOrders: totalOrders || 0,
          totalSpent: totalSpent || 0,
          lastOrder: lastOrder?.createdAt
        };
      })
    );

    res.json({
      customers: customersWithStats,
      pagination: {
        current: parseInt(page),
        total: Math.ceil(count / limit),
        hasNext: page * limit < count,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('Customers load error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücü silmə
router.delete('/drivers/:driverId', auth, authorize('admin', 'operator', 'dispatcher'), async (req, res) => {
  try {
    const { driverId } = req.params;

    const driver = await Driver.findByPk(driverId, {
      include: [{ model: User, as: 'user' }]
    });

    if (!driver) {
      return res.status(404).json({ error: 'Sürücü tapılmadı' });
    }

    // Sürücünün aktiv sifarişi varsa silməyə icazə vermə
    const activeOrder = await Order.findOne({
      where: {
        driverId: driverId,
        status: { [Op.in]: ['pending', 'accepted', 'driver_assigned', 'driver_arrived', 'in_progress'] }
      }
    });

    if (activeOrder) {
      return res.status(400).json({ error: 'Sürücünün aktiv sifarişi var, silinə bilməz' });
    }

    // Sürücü və istifadəçini sil
    await driver.destroy();
    await driver.user.destroy();

    res.json({ message: 'Sürücü uğurla silindi' });
  } catch (error) {
    console.error('Driver deletion error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Müştəri əlavə etmə
router.post('/customers', auth, authorize('admin', 'operator', 'dispatcher'), [
  body('name').notEmpty().withMessage('Ad tələb olunur'),
  body('phone').notEmpty().withMessage('Telefon nömrəsi tələb olunur'),
  body('email').optional().isEmail().withMessage('Düzgün email daxil edin')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, phone, email } = req.body;

    // Telefon nömrəsinin mövcudluğunu yoxla
    const existingUser = await User.findOne({
      where: { phone: phone.replace(/\s/g, '') }
    });

    if (existingUser) {
      return res.status(400).json({ error: 'Bu telefon nömrəsi artıq mövcuddur' });
    }

    // Müştəri yarat
    const user = await User.create({
      name,
      phone: phone.replace(/\s/g, ''),
      email,
      role: 'customer',
      isVerified: true,
      isActive: true
    });

    res.status(201).json({
      message: 'Müştəri uğurla əlavə edildi',
      customer: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    console.error('Customer creation error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Müştəri məlumatlarını yeniləmə
router.put('/customers/:customerId', auth, authorize('admin', 'operator', 'dispatcher'), [
  body('name').optional().notEmpty().withMessage('Ad boş ola bilməz'),
  body('phone').optional().notEmpty().withMessage('Telefon nömrəsi boş ola bilməz'),
  body('email').optional().isEmail().withMessage('Düzgün email daxil edin')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { customerId } = req.params;
    const { name, phone, email } = req.body;

    const user = await User.findByPk(customerId);

    if (!user || user.role !== 'customer') {
      return res.status(404).json({ error: 'Müştəri tapılmadı' });
    }

    // Telefon nömrəsi dəyişdirilərsə, yeni nömrənin mövcudluğunu yoxla
    if (phone && phone !== user.phone) {
      const existingUser = await User.findOne({
        where: { 
          phone: phone.replace(/\s/g, ''),
          id: { [Op.ne]: customerId }
        }
      });

      if (existingUser) {
        return res.status(400).json({ error: 'Bu telefon nömrəsi artıq mövcuddur' });
      }
    }

    // Müştəri məlumatlarını yenilə
    await user.update({
      name: name || user.name,
      phone: phone ? phone.replace(/\s/g, '') : user.phone,
      email: email || user.email
    });

    res.json({
      message: 'Müştəri məlumatları yeniləndi',
      customer: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    console.error('Customer update error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Müştəri sifarişləri
router.get('/customers/:customerId/orders', auth, authorize('admin', 'operator', 'dispatcher'), async (req, res) => {
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
              as: 'user',
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

// Müştəri silmə
router.delete('/customers/:customerId', auth, authorize('admin', 'operator', 'dispatcher'), async (req, res) => {
  try {
    const { customerId } = req.params;

    const user = await User.findByPk(customerId);

    if (!user || user.role !== 'customer') {
      return res.status(404).json({ error: 'Müştəri tapılmadı' });
    }

    // Müştərinin aktiv sifarişi varsa silməyə icazə vermə
    const activeOrder = await Order.findOne({
      where: {
        customerId: customerId,
        status: { [Op.in]: ['pending', 'accepted', 'driver_assigned', 'driver_arrived', 'in_progress'] }
      }
    });

    if (activeOrder) {
      return res.status(400).json({ error: 'Müştərinin aktiv sifarişi var, silinə bilməz' });
    }

    // Müştərini sil
    await user.destroy();

    res.json({ message: 'Müştəri uğurla silindi' });
  } catch (error) {
    console.error('Customer deletion error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});



// Müştərinin əvvəlki ünvanları
router.get('/customers/:customerId/addresses', auth, authorize('admin', 'operator', 'dispatcher'), async (req, res) => {
  try {
    const { customerId } = req.params;

    const orders = await Order.findAll({
      where: { 
        customerId,
        status: { [Op.in]: ['completed', 'cancelled'] }
      },
      attributes: [
        'pickup',
        'destination',
        'createdAt'
      ],
      order: [['createdAt', 'DESC']],
      limit: 10
    });

    const addresses = [];
    const seenAddresses = new Set();

    orders.forEach(order => {
      const pickupAddress = order.pickup?.address;
      const destAddress = order.destination?.address;

      if (pickupAddress && !seenAddresses.has(pickupAddress)) {
        addresses.push({
          address: pickupAddress,
          coordinates: order.pickup?.location?.coordinates,
          type: 'pickup',
          lastUsed: order.createdAt
        });
        seenAddresses.add(pickupAddress);
      }

      if (destAddress && !seenAddresses.has(destAddress)) {
        addresses.push({
          address: destAddress,
          coordinates: order.destination?.location?.coordinates,
          type: 'destination',
          lastUsed: order.createdAt
        });
        seenAddresses.add(destAddress);
      }
    });

    res.json({ addresses });
  } catch (error) {
    console.error('Customer addresses error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Müştərinin sifariş sayı
router.get('/customers/:customerId/order-count', auth, authorize('admin', 'operator', 'dispatcher'), async (req, res) => {
  try {
    const { customerId } = req.params;

    const totalOrders = await Order.count({
      where: { customerId }
    });

    const completedOrders = await Order.count({
      where: { 
        customerId,
        status: 'completed'
      }
    });

    const cancelledOrders = await Order.count({
      where: { 
        customerId,
        status: 'cancelled'
      }
    });

    res.json({
      totalOrders,
      completedOrders,
      cancelledOrders
    });
  } catch (error) {
    console.error('Customer order count error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Təkmilləşdirilmiş sifariş yaratma
router.post('/orders', auth, authorize('admin', 'operator', 'dispatcher'), [
  body('customerPhone').isMobilePhone('az-AZ').withMessage('Düzgün telefon nömrəsi daxil edin'),
  body('customerName').notEmpty().withMessage('Müştəri adı tələb olunur'),
  body('pickup.coordinates').isArray({ min: 2, max: 2 }).withMessage('Pickup koordinatları tələb olunur'),
  body('pickup.address').notEmpty().withMessage('Pickup ünvanı tələb olunur'),
  body('destination.coordinates').isArray({ min: 2, max: 2 }).withMessage('Təyinat koordinatları tələb olunur'),
  body('destination.address').notEmpty().withMessage('Təyinat ünvanı tələb olunur'),
  body('stops').optional().isArray().withMessage('Stops massiv olmalıdır'),
  body('stops.*.coordinates').optional().isArray({ min: 2, max: 2 }).withMessage('Stop koordinatları düzgün deyil'),
  body('stops.*.address').optional().isString(),
  body('payment.method').isIn(['cash', 'card', 'online']).withMessage('Düzgün ödəniş üsulu seçin'),
  body('scheduledTime').optional().isISO8601().withMessage('Düzgün vaxt formatı daxil edin'),
  body('manualFare').optional().isFloat({ min: 0 }).withMessage('Qiymət mənfi ola bilməz'),
  body('notes').optional().isString().withMessage('Qeydlər mətn olmalıdır')
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
      stops = [],
      payment, 
      scheduledTime,
      manualFare,
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
    // Multi-leg distance: pickup -> stops... -> destination
    const legs = [pickup, ...stops, destination];
    let distance = 0;
    for (let i = 0; i < legs.length - 1; i++) {
      const from = legs[i];
      const to = legs[i + 1];
      distance += calculateDistance(
        from.coordinates[1], from.coordinates[0],
        to.coordinates[1], to.coordinates[0]
      );
    }

    const estimatedTime = estimateTravelTime(distance);
    const calculatedFare = calculateFare(distance, estimatedTime);
    
    // Əgər manual qiymət verilibsə, onu istifadə et
    const finalFare = manualFare ? parseFloat(manualFare) : calculatedFare;

    // Sifariş vaxtını təyin et
    const orderTime = scheduledTime ? new Date(scheduledTime) : new Date();

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
      stops: stops.map((s) => ({
        location: {
          type: 'Point',
          coordinates: s.coordinates
        },
        address: s.address,
        instructions: s.instructions
      })),
      estimatedTime,
      estimatedDistance: distance,
      fare: {
        base: calculatedFare,
        manual: manualFare ? parseFloat(manualFare) : null,
        total: finalFare,
        discount: manualFare ? calculatedFare - parseFloat(manualFare) : 0
      },
      payment: {
        method: payment.method,
        status: 'pending'
      },
      status: 'pending',
      scheduledTime: orderTime,
      notes: notes || null,
      orderNumber: `ORD-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      timeline: [
        {
          status: 'pending',
          timestamp: new Date(),
          by: { id: req.user?.id, role: req.user?.role || 'operator' }
        }
      ]
    });

    // Sifarişi müştəri ilə birlikdə qaytar
    const orderWithCustomer = await Order.findByPk(order.id, {
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'name', 'phone', 'email']
        }
      ]
    });

    // Socket event emit et - yaxın sürücülərə yeni sifariş bildir
    const io = req.app.get('io');
    if (io) {
      console.log('Operator: Finding nearby drivers for new order');
      
      // Pickup koordinatlarını al
      const pickupCoords = order.pickup.location.coordinates;
      const [pickupLon, pickupLat] = pickupCoords;
      
      // 5 km yaxınlıqdakı sürücüləri tap
      const nearbyDrivers = await findNearbyDrivers(pickupLat, pickupLon, 5);
      
      console.log('Operator: Found nearby drivers:', nearbyDrivers.length);
      
      // Sifariş məlumatlarını hazırla
      const orderData = {
        id: order.id,
        orderNumber: order.orderNumber,
        customerId: order.customerId,
        pickup: order.pickup,
        destination: order.destination,
        status: order.status,
        estimatedTime: order.estimatedTime,
        estimatedDistance: order.estimatedDistance,
        fare: order.fare,
        paymentMethod: order.payment?.method || 'cash',
        notes: order.notes,
        createdAt: order.createdAt,
        customer: {
          name: customer.name,
          phone: customer.phone
        },
        customerPhone: customer.phone,
        etaMinutes: 15, // Default ETA
        broadcastType: 'nearby_drivers', // Bu broadcast sifarişidir
        nearbyDriversCount: nearbyDrivers.length
      };
      
      console.log('Operator: Broadcasting order to nearby drivers:', {
        orderId: orderData.id,
        orderNumber: orderData.orderNumber,
        nearbyDriversCount: nearbyDrivers.length
      });
      
      // Yaxın sürücülərə broadcast et
      if (nearbyDrivers.length > 0) {
        nearbyDrivers.forEach(driver => {
          console.log(`Operator: Sending order to driver ${driver.userId}`);
          io.to(`driver_${driver.userId}`).emit('broadcast_order_available', orderData);
        });
      } else {
        console.log('Operator: No nearby drivers found, sending to all online drivers');
        // Əgər yaxın sürücü yoxdursa, bütün online sürücülərə göndər
        io.to('drivers').emit('new_order_available', orderData);
      }

      // Müştəriyə bildir
      io.to(`user_${order.customerId}`).emit('order_created', {
        orderId: order.id,
        orderNumber: order.orderNumber,
        status: order.status,
        estimatedTime: order.estimatedTime,
        fare: order.fare
      });

      // Operator və dispetçerlərə bildir
      io.to('operators').emit('new_order_created', { order: orderWithCustomer });
      io.to('dispatchers').emit('new_order_created', { order: orderWithCustomer });
    }

    res.status(201).json({
      message: 'Sifariş uğurla yaradıldı',
      order: orderWithCustomer
    });
  } catch (error) {
    console.error('Order creation error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücü siyahısı
router.get('/drivers', auth, authorize('admin', 'operator', 'dispatcher'), async (req, res) => {
  try {
    const { page = 1, limit = 20, status } = req.query;
    const offset = (page - 1) * limit;

    const whereClause = {};
    if (status && status !== 'all') {
      if (status === 'online') {
        whereClause.isOnline = true;
        whereClause.isAvailable = true;
      } else if (status === 'offline') {
        whereClause.isOnline = false;
      } else if (status === 'busy') {
        whereClause.isOnline = true;
        whereClause.isAvailable = false;
      }
    }

    const { count, rows: drivers } = await Driver.findAndCountAll({
      where: whereClause,
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['name', 'phone', 'email']
        }
      ],
      order: [['createdAt', 'DESC']],
      offset: parseInt(offset),
      limit: parseInt(limit)
    });

    res.json({
      drivers,
      pagination: {
        current: parseInt(page),
        total: Math.ceil(count / limit),
        hasNext: page * limit < count,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('Drivers load error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Yeni sürücü əlavə etmə
router.post('/drivers', auth, authorize('admin', 'operator', 'dispatcher'), [
  body('name').notEmpty().withMessage('Ad tələb olunur'),
  body('phone').notEmpty().withMessage('Telefon nömrəsi tələb olunur'),
  body('licenseNumber').notEmpty().withMessage('Sürücülük vəsiqəsi tələb olunur'),
  body('actualAddress').notEmpty().withMessage('Faktiki ünvan tələb olunur'),
  body('licenseExpiryDate').notEmpty().withMessage('Sürücülük vəsiqəsinin bitmə tarixi tələb olunur'),
  body('vehicleMake').optional().notEmpty().withMessage('Avtomobil markası boş ola bilməz'),
  body('vehicleModel').optional().notEmpty().withMessage('Avtomobil modeli boş ola bilməz'),
  body('plateNumber').optional().notEmpty().withMessage('Nömrə nişanı boş ola bilməz'),
  body('email').optional().isEmail().withMessage('Düzgün email daxil edin'),
  body('identityCardFront').optional().isString().withMessage('Şəxsiyyət vəsiqəsi ön tərəfi'),
  body('identityCardBack').optional().isString().withMessage('Şəxsiyyət vəsiqəsi arxa tərəfi'),
  body('licenseFront').optional().isString().withMessage('Sürücülük vəsiqəsi ön tərəfi'),
  body('licenseBack').optional().isString().withMessage('Sürücülük vəsiqəsi arxa tərəfi')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { 
      name, phone, email, licenseNumber, 
      vehicleMake, vehicleModel, plateNumber,
      actualAddress,
      licenseExpiryDate,
      identityCardFront,
      identityCardBack,
      licenseFront,
      licenseBack
    } = req.body;

    // Telefon nömrəsinin mövcudluğunu yoxla
    const existingUser = await User.findOne({
      where: { phone: phone.replace(/\s/g, '') }
    });

    if (existingUser) {
      return res.status(400).json({ error: 'Bu telefon nömrəsi artıq mövcuddur' });
    }

    // Vəsiqə nömrəsinin mövcudluğunu yoxla
    const existingDriver = await Driver.findOne({
      where: { licenseNumber }
    });

    if (existingDriver) {
      return res.status(400).json({ error: 'Bu sürücülük vəsiqəsi artıq mövcuddur' });
    }

    // İstifadəçi yarat
    const user = await User.create({
      name,
      phone: phone.replace(/\s/g, ''),
      email,
      role: 'driver',
      isVerified: true,
      isActive: true
    });

    // Sürücü yarat
    const driverData = {
      userId: user.id,
      licenseNumber,
      actualAddress,
      licenseExpiryDate: new Date(licenseExpiryDate),
      identityCardFront,
      identityCardBack,
      licenseFront,
      licenseBack,
      isOnline: false,
      isAvailable: false,
      status: 'approved',
      isActive: true
    };

    // Əgər avtomobil məlumatları verilibsə, əlavə et
    if (vehicleMake && vehicleModel && plateNumber) {
      driverData.vehicleInfo = {
        make: vehicleMake,
        model: vehicleModel,
        plateNumber: plateNumber.toUpperCase()
      };
    }

    const driver = await Driver.create(driverData);

    res.status(201).json({
      message: 'Sürücü uğurla əlavə edildi',
      driver: {
        id: driver.id,
        user: {
          id: user.id,
          name: user.name,
          phone: user.phone,
          email: user.email
        },
        licenseNumber: driver.licenseNumber,
        vehicleInfo: driver.vehicleInfo || null
      }
    });
  } catch (error) {
    console.error('Driver creation error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücü məlumatlarını yeniləmə
router.put('/drivers/:driverId', auth, authorize('admin', 'operator', 'dispatcher'), [
  body('name').optional().notEmpty().withMessage('Ad boş ola bilməz'),
  body('phone').optional().notEmpty().withMessage('Telefon nömrəsi boş ola bilməz'),
  body('email').optional().isEmail().withMessage('Düzgün email daxil edin'),
  body('licenseNumber').optional().notEmpty().withMessage('Sürücülük vəsiqəsi boş ola bilməz'),
  body('vehicleMake').optional().notEmpty().withMessage('Avtomobil markası boş ola bilməz'),
  body('vehicleModel').optional().notEmpty().withMessage('Avtomobil modeli boş ola bilməz'),
  body('plateNumber').optional().notEmpty().withMessage('Nömrə nişanı boş ola bilməz')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { driverId } = req.params;
    const { 
      name, phone, email, licenseNumber, 
      vehicleMake, vehicleModel, plateNumber 
    } = req.body;

    const driver = await Driver.findByPk(driverId, {
      include: [{ model: User, as: 'user' }]
    });

    if (!driver) {
      return res.status(404).json({ error: 'Sürücü tapılmadı' });
    }

    // Telefon nömrəsi dəyişdirilərsə, yeni nömrənin mövcudluğunu yoxla
    if (phone && phone !== driver.user.phone) {
      const existingUser = await User.findOne({
        where: { 
          phone: phone.replace(/\s/g, ''),
          id: { [Op.ne]: driver.userId }
        }
      });

      if (existingUser) {
        return res.status(400).json({ error: 'Bu telefon nömrəsi artıq mövcuddur' });
      }
    }

    // Vəsiqə nömrəsi dəyişdirilərsə, yeni nömrənin mövcudluğunu yoxla
    if (licenseNumber && licenseNumber !== driver.licenseNumber) {
      const existingDriver = await Driver.findOne({
        where: { 
          licenseNumber,
          id: { [Op.ne]: driverId }
        }
      });

      if (existingDriver) {
        return res.status(400).json({ error: 'Bu sürücülük vəsiqəsi artıq mövcuddur' });
      }
    }

    // İstifadəçi məlumatlarını yenilə
    await driver.user.update({
      name: name || driver.user.name,
      phone: phone ? phone.replace(/\s/g, '') : driver.user.phone,
      email: email || driver.user.email
    });

    // Sürücü məlumatlarını yenilə
    await driver.update({
      licenseNumber: licenseNumber || driver.licenseNumber,
      vehicleInfo: {
        make: vehicleMake || driver.vehicleInfo.make,
        model: vehicleModel || driver.vehicleInfo.model,
        plateNumber: plateNumber ? plateNumber.toUpperCase() : driver.vehicleInfo.plateNumber
      }
    });

    res.json({
      message: 'Sürücü məlumatları yeniləndi',
      driver: {
        id: driver.id,
        user: {
          id: driver.user.id,
          name: driver.user.name,
          phone: driver.user.phone,
          email: driver.user.email
        },
        licenseNumber: driver.licenseNumber,
        vehicleInfo: driver.vehicleInfo
      }
    });
  } catch (error) {
    console.error('Driver update error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

module.exports = router; 
