const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const Order = require('../models/Order');
const Driver = require('../models/Driver');
const User = require('../models/User'); // Added for population
const { 
  calculateDistance, 
  calculateFare, 
  estimateTravelTime,
  findNearbyDrivers 
} = require('../utils/geolocation');

const router = express.Router();

// Yeni sifariş yarat
// Əgər customerPhone və customerName verilibsə, yeni müştəri yaradılacaq
// Əgər customerPhone verilməzsə, cari istifadəçi müştəri kimi istifadə olunacaq
router.post('/', auth, [
  body('pickup.coordinates').isArray({ min: 2, max: 2 }).withMessage('Pickup koordinatları tələb olunur'),
  body('pickup.address').notEmpty().withMessage('Pickup ünvanı tələb olunur'),
  body('destination.coordinates').isArray({ min: 2, max: 2 }).withMessage('Təyinat koordinatları tələb olunur'),
  body('destination.address').notEmpty().withMessage('Təyinat ünvanı tələb olunur'),
  body('payment.method').isIn(['cash', 'card', 'online']).withMessage('Düzgün ödəniş üsulu seçin'),
  body('customerPhone').optional().isMobilePhone('az-AZ').withMessage('Düzgün telefon nömrəsi daxil edin'),
  body('customerName').optional().notEmpty().withMessage('Müştəri adı tələb olunur')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { pickup, destination, payment, notes, customerPhone, customerName } = req.body;

    // Müştərini müəyyən et
    let customerId = req.user.id;
    
    // Əgər telefon nömrəsi verilibsə, müştərini tap və ya yarat
    if (customerPhone) {
      // Telefon nömrəsini təmizlə (boşluqları sil)
      const cleanPhone = customerPhone.replace(/\s/g, '');
      
      let customer = await User.findOne({ where: { phone: cleanPhone } });
      if (!customer) {
        // Yeni müştəri yarat - əgər telefon nömrəsi customer cədvəlində yoxdursa
        if (!customerName) {
          return res.status(400).json({ 
            error: 'Yeni müştəri yaratmaq üçün ad tələb olunur',
            details: 'customerPhone verildiyi halda customerName də tələb olunur'
          });
        }
        
        try {
          customer = await User.create({
            phone: cleanPhone,
            name: customerName,
            role: 'customer',
            isVerified: true
          });
          
          console.log('Yeni müştəri yaradıldı:', {
            id: customer.id,
            name: customer.name,
            phone: customer.phone
          });
        } catch (customerError) {
          console.error('Müştəri yaratma xətası:', customerError);
          return res.status(500).json({ 
            error: 'Müştəri yaradıla bilmədi',
            details: customerError.message 
          });
        }
      }
      customerId = customer.id;
    }

    // Məsafə və vaxt hesabla
    const distance = calculateDistance(
      pickup.coordinates[1], pickup.coordinates[0],
      destination.coordinates[1], destination.coordinates[0]
    );

    const estimatedTime = estimateTravelTime(distance);
    const fare = calculateFare(distance, estimatedTime);

    // Order number yarat
    const generateOrderNumber = () => {
      const date = new Date();
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
      return `ORD-${year}${month}${day}-${random}`;
    };

    // Yeni sifariş yarat
    console.log('Creating order with user:', {
      userId: req.user.id,
      userRole: req.user.role,
      customerId: customerId
    });
    
    const orderData = {
      orderNumber: generateOrderNumber(), // Manual order number yarat
      customerId: customerId, // Müəyyən edilmiş müştəri ID-si
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

    // Sifarişi müştəri məlumatları ilə birlikdə qaytar
    const orderWithCustomer = await Order.findByPk(order.id, {
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'name', 'phone']
        }
      ]
    });

    // Socket event emit et - bütün online sürücülərə yeni sifariş bildir
    const io = req.app.get('io');
    if (io) {
      console.log('Orders: Emitting new order to all drivers');
      
      // Bütün online sürücülərə yeni sifariş bildir
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
          name: orderWithCustomer.customer?.name || 'Müştəri',
          phone: orderWithCustomer.customer?.phone || 'N/A'
        },
        customerPhone: orderWithCustomer.customer?.phone,
        etaMinutes: 15 // Default ETA
      };
      
      console.log('Orders: Emitting order data to drivers:', {
        orderId: orderData.id,
        orderNumber: orderData.orderNumber,
        status: orderData.status
      });
      
      io.to('drivers').emit('new_order_available', orderData);

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
      order: {
        id: order.id,
        orderNumber: order.orderNumber,
        status: order.status,
        estimatedTime,
        estimatedDistance: Math.round(distance * 100) / 100,
        fare,
        nearbyDrivers: nearbyDrivers.length,
        customer: orderWithCustomer.customer
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

// Müştərinin öz sifarişləri
router.get('/my-orders', auth, async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const offset = (page - 1) * limit;

    const whereClause = { customerId: req.user.id };
    
    if (status) {
      whereClause.status = status;
    }

    const { count, rows: orders } = await Order.findAndCountAll({
      where: whereClause,
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
      offset: parseInt(offset),
      limit: parseInt(limit)
    });

    res.json({
      orders,
      pagination: {
        current: parseInt(page),
        total: Math.ceil(count / limit),
        hasNext: page * limit < count,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('Müştəri sifarişləri alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// İstifadəçinin sifarişləri
router.get('/', auth, async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const offset = (page - 1) * limit;

    const whereClause = {};
    
    if (req.user.role === 'customer') {
      whereClause.customerId = req.user.id;
    } else if (req.user.role === 'driver') {
      const driver = await Driver.findOne({ where: { userId: req.user.id } });
      if (driver) {
        whereClause.driverId = driver.id;
      }
    }

    if (status) {
      whereClause.status = status;
    }

    const { count, rows: orders } = await Order.findAndCountAll({
      where: whereClause,
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
      offset: parseInt(offset),
      limit: parseInt(limit)
    });

    res.json({
      orders,
      pagination: {
        current: parseInt(page),
        total: Math.ceil(count / limit),
        hasNext: page * limit < count,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('Sifarişlər alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifariş məlumatlarını al
router.get('/:orderId', auth, async (req, res) => {
  try {
    const order = await Order.findByPk(req.params.orderId, {
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
      ]
    });

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    // Yalnız sifariş sahibi və ya təyin edilmiş sürücü görə bilər
    if (order.customerId !== req.user.id && 
        (!order.driverId || order.driver.user.id !== req.user.id)) {
      return res.status(403).json({ error: 'Bu sifarişə giriş icazəniz yoxdur' });
    }

    res.json({ order });
  } catch (error) {
    console.error('Sifariş məlumatları alma xətası:', error);
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
    const order = await Order.findByPk(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    // Status dəyişikliyi icazəsini yoxla
    const canUpdateStatus = 
      req.user.role.name === 'admin' ||
      req.user.role.name === 'operator' ||
      req.user.role.name === 'dispatcher' ||
      req.user.role.name === 'driver' ||
      order.customerId === req.user.id ||
      (order.driverId && order.driverId === req.user.id);

    if (!canUpdateStatus) {
      return res.status(403).json({ error: 'Status dəyişdirmə icazəniz yoxdur req.user.role = ' + req.user.role.name + ' order.customerId = ' + order.customerId + ' order.driverId = ' + order.driverId + ' order.status = ' + order.status + ' status = ' + status    });
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
    const timeline = order.timeline || [];
    timeline.push({
      status,
      timestamp: new Date(),
      location: location ? {
        type: 'Point',
        coordinates: location
      } : undefined
    });

    await order.update({
      status,
      timeline,
      notes: notes || order.notes
    });

    res.json({
      message: 'Status uğurla yeniləndi',
      order: {
        id: order.id,
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
    const order = await Order.findByPk(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    // Ləğv etmə icazəsini yoxla
    if (order.customerId !== req.user.id && 
        req.user.role !== 'admin' && 
        req.user.role !== 'operator') {
      return res.status(403).json({ error: 'Sifarişi ləğv etmə icazəniz yoxdur' });
    }

    if (order.status === 'completed' || order.status === 'cancelled') {
      return res.status(400).json({ error: 'Bu sifariş artıq tamamlanıb və ya ləğv edilib' });
    }

    const timeline = order.timeline || [];
    timeline.push({
      status: 'cancelled',
      timestamp: new Date()
    });

    await order.update({
      status: 'cancelled',
      cancelledBy: req.user.role === 'customer' ? 'customer' : 'operator',
      cancellationReason: reason,
      timeline
    });

    res.json({
      message: 'Sifariş uğurla ləğv edildi',
      order: {
        id: order.id,
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
    const order = await Order.findByPk(req.params.orderId);

    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    if (order.status !== 'completed') {
      return res.status(400).json({ error: 'Yalnız tamamlanmış sifarişlərə qiymətləndirmə verə bilərsiniz' });
    }

    // Qiymətləndirmə verən istifadəçini müəyyən et
    const isCustomer = order.customerId === req.user.id;
    const isDriver = order.driverId && order.driverId === req.user.id;

    if (!isCustomer && !isDriver) {
      return res.status(403).json({ error: 'Bu sifarişə qiymətləndirmə vermə icazəniz yoxdur' });
    }

    // Qiymətləndirməni əlavə et
    const ratingData = order.rating || {};
    
    if (isCustomer) {
      ratingData.customerRating = {
        rating,
        comment,
        createdAt: new Date()
      };
    } else if (isDriver) {
      ratingData.driverRating = {
        rating,
        comment,
        createdAt: new Date()
      };
    }

    await order.update({ rating: ratingData });

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