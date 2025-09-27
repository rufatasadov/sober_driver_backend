const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const { Op } = require('sequelize');
const Driver = require('../models/Driver');
const User = require('../models/User');
const Order = require('../models/Order');
const { findNearbyDrivers } = require('../utils/geolocation');

const router = express.Router();

// Sürücü qeydiyyatı
router.post('/register', auth, [
  body('licenseNumber').notEmpty().withMessage('Sürücülük vəsiqəsi nömrəsi tələb olunur'),
  body('vehicleInfo.make').notEmpty().withMessage('Avtomobil markası tələb olunur'),
  body('vehicleInfo.model').notEmpty().withMessage('Avtomobil modeli tələb olunur'),
  body('vehicleInfo.year').isInt({ min: 1990, max: new Date().getFullYear() }).withMessage('Düzgün il daxil edin'),
  body('vehicleInfo.color').notEmpty().withMessage('Avtomobil rəngi tələb olunur'),
  body('vehicleInfo.plateNumber').notEmpty().withMessage('Nömrə nişanı tələb olunur')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    // İstifadəçinin sürücü olub-olmadığını yoxla
    const existingDriver = await Driver.findOne({ where: { userId: req.user.id } });
    if (existingDriver) {
      return res.status(400).json({ error: 'Siz artıq sürücü kimi qeydiyyatdan keçmisiniz' });
    }

    const { licenseNumber, vehicleInfo, documents } = req.body;

    // Lisenziya və nömrə nişanının unikallığını yoxla
    const existingLicense = await Driver.findOne({ where: { licenseNumber } });
    if (existingLicense) {
      return res.status(400).json({ error: 'Bu sürücülük vəsiqəsi artıq istifadə olunub' });
    }

    const existingPlate = await Driver.findOne({ 
      where: { 
        vehicleInfo: { 
          plateNumber: vehicleInfo.plateNumber 
        } 
      } 
    });
    if (existingPlate) {
      return res.status(400).json({ error: 'Bu nömrə nişanı artıq istifadə olunub' });
    }

    // Yeni sürücü yarat
    const driver = await Driver.create({
      userId: req.user.id,
      licenseNumber,
      vehicleInfo,
      documents: documents || {},
      status: 'pending'
    });

    // İstifadəçi rolunu yenilə
    const user = await User.findByPk(req.user.id);
    if (user) {
      await user.update({ role: 'driver' });
    }

    res.status(201).json({
      message: 'Sürücü qeydiyyatı uğurla tamamlandı',
      driver: {
        id: driver.id,
        licenseNumber: driver.licenseNumber,
        vehicleInfo: driver.vehicleInfo,
        status: driver.status
      }
    });
  } catch (error) {
    console.error('Sürücü qeydiyyat xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücü məlumatlarını al
router.get('/profile', auth, authorize('driver'), async (req, res) => {
  try {
    const driver = await Driver.findOne({ 
      where: { userId: req.user.id },
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['name', 'phone', 'email']
        }
      ]
    });

    if (!driver) {
      return res.status(404).json({ error: 'Sürücü məlumatları tapılmadı' });
    }

    res.json({ driver });
  } catch (error) {
    console.error('Sürücü məlumatları alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücü məlumatlarını yenilə
router.put('/profile', auth, authorize('driver'), [
  body('vehicleInfo.make').optional().notEmpty().withMessage('Avtomobil markası boş ola bilməz'),
  body('vehicleInfo.model').optional().notEmpty().withMessage('Avtomobil modeli boş ola bilməz'),
  body('vehicleInfo.year').optional().isInt({ min: 1990, max: new Date().getFullYear() }).withMessage('Düzgün il daxil edin'),
  body('vehicleInfo.color').optional().notEmpty().withMessage('Avtomobil rəngi boş ola bilməz')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { vehicleInfo, documents } = req.body;
    const updates = {};

    if (vehicleInfo) {
      updates.vehicleInfo = vehicleInfo;
    }

    if (documents) {
      updates.documents = documents;
    }

    const driver = await Driver.findOne({ 
      where: { userId: req.user.id },
      include: [{ model: User, attributes: ['name', 'phone', 'email'] }]
    });
    
    if (driver) {
      await driver.update(updates);
    }

    if (!driver) {
      return res.status(404).json({ error: 'Sürücü məlumatları tapılmadı' });
    }

    res.json({
      message: 'Sürücü məlumatları uğurla yeniləndi',
      driver
    });
  } catch (error) {
    console.error('Sürücü məlumatları yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Get driver status
router.get('/status', auth, authorize('driver'), async (req, res) => {
  try {
    const driver = await Driver.findOne({ where: { userId: req.user.id } });

    if (!driver) {
      return res.status(404).json({ error: 'Sürücü məlumatları tapılmadı' });
    }

    res.json({
      success: true,
      isOnline: driver.isOnline,
      isAvailable: driver.isAvailable,
      lastActive: driver.lastActive
    });
  } catch (error) {
    console.error('Sürücü status alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Online/Offline status
router.patch('/status', auth, authorize('driver'), [
  body('isOnline').isBoolean().withMessage('Online status boolean olmalıdır'),
  body('isAvailable').optional().isBoolean().withMessage('Available status boolean olmalıdır')
], async (req, res) => {
  try {
    console.log('Driver status update request:', {
      userId: req.user.id,
      body: req.body
    });

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('Validation errors:', errors.array());
      return res.status(400).json({ errors: errors.array() });
    }

    const { isOnline, isAvailable } = req.body;
    const updates = { isOnline };

    if (isAvailable !== undefined) {
      updates.isAvailable = isAvailable;
    }

    if (isOnline) {
      updates.lastActive = new Date();
    }

    console.log('Updating driver with:', updates);

    const driver = await Driver.findOne({ where: { userId: req.user.id } });
    
    if (!driver) {
      console.log('Driver not found for userId:', req.user.id);
      return res.status(404).json({ error: 'Sürücü məlumatları tapılmadı' });
    }

    await driver.update(updates);
    
    // Reload the driver to get updated values
    await driver.reload();

    console.log('Driver updated successfully:', {
      id: driver.id,
      isOnline: driver.isOnline,
      isAvailable: driver.isAvailable,
      lastActive: driver.lastActive
    });

    res.json({
      success: true,
      message: `Sürücü ${isOnline ? 'online' : 'offline'} oldu`,
      driver: {
        id: driver.id,
        isOnline: driver.isOnline,
        isAvailable: driver.isAvailable,
        lastActive: driver.lastActive
      }
    });
  } catch (error) {
    console.error('Status yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Mövcud yeri yenilə
router.patch('/location', auth, authorize('driver'), [
  body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Düzgün enlik daxil edin'),
  body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Düzgün uzunluq daxil edin'),
  body('address').optional().isString().withMessage('Ünvan string olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { latitude, longitude, address } = req.body;

    const driver = await Driver.findOne({ where: { userId: req.user.id } });
    
    if (driver) {
      await driver.update({
        currentLocation: {
          type: 'Point',
          coordinates: [longitude, latitude],
          address: address || ''
        },
        lastActive: new Date()
      });
    }

    if (!driver) {
      return res.status(404).json({ error: 'Sürücü məlumatları tapılmadı' });
    }

    res.json({
      message: 'Yer uğurla yeniləndi',
      location: driver.currentLocation
    });
  } catch (error) {
    console.error('Yer yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Yaxın sifarişləri al
router.get('/nearby-orders', auth, authorize('driver'), async (req, res) => {
  try {
    const { latitude, longitude, maxDistance = 5 } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({ error: 'Koordinatlar tələb olunur' });
    }

    // Sürücünün məlumatlarını al
    const driver = await Driver.findOne({ userId: req.user.id });
    if (!driver || !driver.isOnline || !driver.isAvailable) {
      return res.status(400).json({ error: 'Sürücü online və available olmalıdır' });
    }

    // Yaxın sifarişləri tap
    const orders = await Order.find({
      status: 'pending',
      'pickup.location': {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(longitude), parseFloat(latitude)]
          },
          $maxDistance: parseFloat(maxDistance) * 1000 // metrə çevir
        }
      }
    })
    .populate('customer', 'name phone')
    .sort({ createdAt: -1 })
    .limit(10);

    res.json({
      orders: orders.map(order => ({
        id: order._id,
        orderNumber: order.orderNumber,
        pickup: order.pickup,
        destination: order.destination,
        estimatedTime: order.estimatedTime,
        estimatedDistance: order.estimatedDistance,
        fare: order.fare,
        customer: order.customer,
        createdAt: order.createdAt
      }))
    });
  } catch (error) {
    console.error('Yaxın sifarişlər alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifarişi qəbul et
router.post('/orders/:orderId/accept', auth, authorize('driver'), async (req, res) => {
  try {
    console.log('Accept order request:', {
      orderId: req.params.orderId,
      userId: req.user.id,
      userRole: req.user.role
    });
    
    const order = await Order.findByPk(req.params.orderId);
    console.log('Found order:', order ? { id: order.id, status: order.status } : 'Not found');
    
    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    if (order.status !== 'pending') {
      return res.status(400).json({ error: 'Bu sifariş artıq qəbul edilib və ya ləğv edilib' });
    }

    // Sürücünün məlumatlarını al
    const driver = await Driver.findOne({ where: { userId: req.user.id } });
    console.log('Found driver:', driver ? { id: driver.id, isOnline: driver.isOnline, isAvailable: driver.isAvailable } : 'Not found');
    
    if (!driver || !driver.isOnline || !driver.isAvailable) {
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

    console.log('Order accepted successfully:', {
      orderId: order.id,
      driverId: driver.id,
      status: order.status
    });

    // Socket event emit et - digər sürücülərdən broadcast sifarişi sil
    const io = req.app.get('io');
    if (io) {
      console.log('Driver: Emitting order accepted, removing from other drivers');
      
      // Bütün sürücülərə bildir ki, bu sifariş artıq mövcud deyil
      io.to('drivers').emit('order_accepted_by_other', {
        orderId: order.id,
        orderNumber: order.orderNumber,
        acceptedBy: {
          driverId: driver.id,
          driverName: driver.user?.name || 'Sürücü'
        }
      });

      // Müştəriyə bildir
      io.to(`user_${order.customerId}`).emit('driver_assigned', {
        orderId: order.id,
        orderNumber: order.orderNumber,
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
      message: 'Sifariş uğurla qəbul edildi',
      order: {
        id: order.id,
        orderNumber: order.orderNumber,
        status: order.status,
        customer: order.customer,
        pickup: order.pickup,
        destination: order.destination
      }
    });
  } catch (error) {
    console.error('Sifariş qəbul etmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifarişi imtina et
router.post('/orders/:orderId/reject', auth, authorize('driver'), async (req, res) => {
  try {
    console.log('Reject order request:', {
      orderId: req.params.orderId,
      userId: req.user.id,
      userRole: req.user.role
    });
    
    const order = await Order.findByPk(req.params.orderId);
    console.log('Found order for rejection:', order ? { id: order.id, status: order.status } : 'Not found');
    
    if (!order) {
      return res.status(404).json({ error: 'Sifariş tapılmadı' });
    }

    if (order.status !== 'pending') {
      return res.status(400).json({ error: 'Bu sifariş artıq qəbul edilib və ya ləğv edilib' });
    }

    console.log('Order rejected successfully:', {
      orderId: order.id,
      status: order.status
    });

    res.json({
      message: 'Sifariş imtina edildi'
    });
  } catch (error) {
    console.error('Sifariş imtina etmə xətası:', error);
    console.error('Error details:', error.message);
    console.error('Stack trace:', error.stack);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücünün sifarişləri
router.get('/orders', auth, authorize('driver'), async (req, res) => {
  try {
    console.log('Driver orders request:', {
      userId: req.user.id,
      userRole: req.user.role
    });

    const driver = await Driver.findOne({ where: { userId: req.user.id } });
    if (!driver) {
      return res.status(404).json({ error: 'Sürücü məlumatları tapılmadı' });
    }

    console.log('Found driver:', { id: driver.id, userId: driver.userId });

    const { page = 1, limit = 50, status } = req.query;
    const offset = (page - 1) * limit;

    const whereClause = { driverId: driver.id };
    
    if (status) {
      whereClause.status = status;
    }

    console.log('Query where clause:', whereClause);

    const { count, rows: orders } = await Order.findAndCountAll({
      where: whereClause,
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['name', 'phone']
        }
      ],
      order: [['createdAt', 'DESC']],
      offset: parseInt(offset),
      limit: parseInt(limit)
    });

    console.log('Found orders:', {
      count: count,
      ordersCount: orders.length,
      sampleOrder: orders.length > 0 ? {
        id: orders[0].id,
        orderNumber: orders[0].orderNumber,
        status: orders[0].status
      } : null
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
    console.error('Sürücü sifarişləri alma xətası:', error);
    console.error('Error details:', error.message);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücünün qazanc məlumatları
router.get('/earnings', auth, authorize('driver'), async (req, res) => {
  try {
    console.log('Driver earnings request:', {
      userId: req.user.id,
      userRole: req.user.role,
      period: req.query.period
    });

    const { period = 'today' } = req.query;
    const driver = await Driver.findOne({ where: { userId: req.user.id } });

    console.log('Found driver for earnings:', driver ? { id: driver.id, commission: driver.commission } : 'Not found');

    if (!driver) {
      return res.status(404).json({ error: 'Sürücü məlumatları tapılmadı' });
    }

    // Müxtəlif dövrlər üçün qazanc hesabla
    const now = new Date();
    let startDate, endDate;

    switch (period) {
      case 'today':
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
        break;
      case 'week':
        const dayOfWeek = now.getDay();
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - dayOfWeek);
        endDate = new Date(startDate.getTime() + 7 * 24 * 60 * 60 * 1000);
        break;
      case 'month':
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        endDate = new Date(now.getFullYear(), now.getMonth() + 1, 1);
        break;
      default:
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
    }

    // Tamamlanmış sifarişləri al
    console.log('Looking for completed orders:', {
      driverId: driver.id,
      status: 'completed',
      startDate,
      endDate
    });

    const completedOrders = await Order.findAll({
      where: {
        driverId: driver.id,
        status: 'completed',
        createdAt: {
          [Op.gte]: startDate,
          [Op.lt]: endDate
        }
      }
    });

    console.log('Found completed orders:', {
      count: completedOrders.length,
      orders: completedOrders.map(order => ({
        id: order.id,
        fare: order.fare,
        status: order.status
      }))
    });

    const totalEarnings = completedOrders.reduce((sum, order) => sum + parseFloat(order.fare?.total || 0), 0);
    const commission = totalEarnings * (driver.commission / 100);
    const netEarnings = totalEarnings - commission;

    console.log('Earnings calculation:', {
      completedOrdersCount: completedOrders.length,
      totalEarnings,
      commission,
      netEarnings,
      driverCommission: driver.commission
    });

    const earningsData = {
      earnings: {
        period,
        totalOrders: completedOrders.length,
        totalEarnings,
        commission,
        netEarnings,
        orders: completedOrders.map(order => ({
          id: order.id,
          orderNumber: order.orderNumber,
          fare: order.fare,
          createdAt: order.createdAt
        }))
      }
    };

    console.log('Sending earnings response:', earningsData);
    res.json(earningsData);
  } catch (error) {
    console.error('Qazanc məlumatları alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Admin üçün bütün sürücüləri al
router.get('/', auth, authorize('admin', 'dispatcher'), async (req, res) => {
  try {
    const { page = 1, limit = 10, status, isOnline } = req.query;
    const skip = (page - 1) * limit;

    const filter = {};
    if (status) filter.status = status;
    if (isOnline !== undefined) filter.isOnline = isOnline === 'true';

    const { count, rows: drivers } = await Driver.findAndCountAll({
      where: filter,
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['name', 'phone', 'email']
        }
      ],
      order: [['createdAt', 'DESC']],
      offset: skip,
      limit: parseInt(limit)
    });

    const total = count;

    res.json({
      drivers,
      pagination: {
        current: parseInt(page),
        total: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('Sürücülər alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Onlayn sürücüləri GPS məlumatları ilə alma
router.get('/online', auth, authorize('operator'), async (req, res) => {
  try {
    const drivers = await Driver.findAll({
      where: {
        isOnline: true
      },
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'phone']
        }
      ],
      attributes: [
        'id',
        'userId',
        'isOnline',
        'isAvailable',
        'currentLocation',
        'lastLocationUpdate',
        'vehicleInfo'
      ]
    });

    // GPS məlumatları olan sürücüləri filtrlə
    const driversWithLocation = drivers.filter(driver => 
      driver.currentLocation && 
      driver.currentLocation.coordinates &&
      driver.currentLocation.coordinates.length >= 2
    );

    res.json({
      success: true,
      drivers: driversWithLocation.map(driver => ({
        id: driver.id,
        name: driver.user?.name || 'Sürücü',
        phone: driver.user?.phone,
        isOnline: driver.isOnline,
        isAvailable: driver.isAvailable,
        currentLocation: driver.currentLocation,
        lastLocationUpdate: driver.lastLocationUpdate,
        vehicleInfo: driver.vehicleInfo
      }))
    });
  } catch (error) {
    console.error('Onlayn sürücülər alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücü GPS məlumatlarını yenilə
router.patch('/location', auth, authorize('driver'), [
  body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Düzgün enlik daxil edin'),
  body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Düzgün uzunluq daxil edin')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { latitude, longitude } = req.body;

    // Sürücünü tap
    const driver = await Driver.findOne({ where: { userId: req.user.id } });
    if (!driver) {
      return res.status(404).json({ error: 'Sürücü tapılmadı' });
    }

    // GPS məlumatlarını yenilə
    await driver.update({
      currentLocation: {
        type: 'Point',
        coordinates: [longitude, latitude]
      },
      lastLocationUpdate: new Date()
    });

    res.json({
      success: true,
      message: 'GPS məlumatları yeniləndi'
    });
  } catch (error) {
    console.error('GPS yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

module.exports = router; 