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

// Müştəri siyahısı
router.get('/customers', auth, authorize('operator'), async (req, res) => {
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

        const totalSpent = await Order.sum('fare.total', {
          where: { 
            customerId: customer.id,
            status: 'completed'
          }
        });

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

// Yeni müştəri əlavə etmə
router.post('/customers', auth, authorize('operator'), [
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

    const customer = await User.create({
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
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        email: customer.email
      }
    });
  } catch (error) {
    console.error('Customer creation error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Müştəri məlumatlarını yeniləmə
router.put('/customers/:customerId', auth, authorize('operator'), [
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

    const customer = await User.findByPk(customerId);
    if (!customer || customer.role !== 'customer') {
      return res.status(404).json({ error: 'Müştəri tapılmadı' });
    }

    // Telefon nömrəsi dəyişdirilərsə, yeni nömrənin mövcudluğunu yoxla
    if (phone && phone !== customer.phone) {
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

    await customer.update({
      name: name || customer.name,
      phone: phone ? phone.replace(/\s/g, '') : customer.phone,
      email: email || customer.email
    });

    res.json({
      message: 'Müştəri məlumatları yeniləndi',
      customer: {
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        email: customer.email
      }
    });
  } catch (error) {
    console.error('Customer update error:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücü siyahısı
router.get('/drivers', auth, authorize('operator'), async (req, res) => {
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
router.post('/drivers', auth, authorize('operator'), [
  body('name').notEmpty().withMessage('Ad tələb olunur'),
  body('phone').notEmpty().withMessage('Telefon nömrəsi tələb olunur'),
  body('licenseNumber').notEmpty().withMessage('Sürücülük vəsiqəsi tələb olunur'),
  body('vehicleMake').optional().notEmpty().withMessage('Avtomobil markası boş ola bilməz'),
  body('vehicleModel').optional().notEmpty().withMessage('Avtomobil modeli boş ola bilməz'),
  body('plateNumber').optional().notEmpty().withMessage('Nömrə nişanı boş ola bilməz'),
  body('email').optional().isEmail().withMessage('Düzgün email daxil edin')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { 
      name, phone, email, licenseNumber, 
      vehicleMake, vehicleModel, plateNumber 
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
      isOnline: false,
      isAvailable: false,
      status: 'approved'
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
router.put('/drivers/:driverId', auth, authorize('operator'), [
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