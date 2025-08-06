const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const User = require('../models/User');
const Driver = require('../models/Driver');
const Order = require('../models/Order');
const { Op } = require('sequelize');

const router = express.Router();

// Admin dashboard
router.get('/dashboard', auth, authorize('admin'), async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Ümumi statistika
    const totalUsers = await User.count({ where: { role: 'customer' } });
    const totalDrivers = await Driver.count();
    const totalOrders = await Order.count();
    const totalCompletedOrders = await Order.count({ where: { status: 'completed' } });

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

    // Bugünkü gəlir (Sequelize-də aggregate əvəzinə)
    const todayCompletedOrders = await Order.findAll({
      where: {
        status: 'completed',
        createdAt: {
          [Op.gte]: today,
          [Op.lt]: tomorrow
        }
      },
      attributes: ['fare']
    });

    const todayRevenue = todayCompletedOrders.reduce((sum, order) => {
      return sum + (order.fare?.total || 0);
    }, 0);

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

    // Son qeydiyyatdan keçən sürücülər
    const recentDrivers = await Driver.findAll({
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['name', 'phone']
        }
      ],
      order: [['createdAt', 'DESC']],
      limit: 5
    });

    res.json({
      stats: {
        totalUsers,
        totalDrivers,
        totalOrders,
        totalCompletedOrders,
        todayOrders,
        todayCompleted,
        todayRevenue,
        onlineDrivers
      },
      recentOrders,
      recentDrivers
    });
  } catch (error) {
    console.error('Admin dashboard xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// İstifadəçiləri idarə et
router.get('/users', auth, authorize('admin'), async (req, res) => {
  try {
    const { page = 1, limit = 20, role, search } = req.query;
    const skip = (page - 1) * limit;

    const filter = {};
    if (role) filter.role = role;
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }

    const users = await User.find(filter)
      .select('-__v')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await User.countDocuments(filter);

    res.json({
      users,
      pagination: {
        current: parseInt(page),
        total: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('İstifadəçilər alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// İstifadəçi məlumatlarını yenilə
router.put('/users/:userId', auth, authorize('admin'), [
  body('name').optional().isLength({ min: 2 }).withMessage('Ad minimum 2 simvol olmalıdır'),
  body('email').optional().isEmail().withMessage('Düzgün email daxil edin'),
  body('role').optional().isIn(['customer', 'driver', 'operator', 'dispatcher', 'admin']).withMessage('Düzgün rol seçin'),
  body('isActive').optional().isBoolean().withMessage('Active status boolean olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, email, role, isActive } = req.body;
    const updates = {};

    if (name) updates.name = name;
    if (email) updates.email = email;
    if (role) updates.role = role;
    if (isActive !== undefined) updates.isActive = isActive;

    const user = await User.findByIdAndUpdate(
      req.params.userId,
      updates,
      { new: true, runValidators: true }
    ).select('-__v');

    if (!user) {
      return res.status(404).json({ error: 'İstifadəçi tapılmadı' });
    }

    res.json({
      message: 'İstifadəçi uğurla yeniləndi',
      user
    });
  } catch (error) {
    console.error('İstifadəçi yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücüləri idarə et
router.get('/drivers', auth, authorize('admin'), async (req, res) => {
  try {
    const { page = 1, limit = 20, status, isOnline } = req.query;
    const skip = (page - 1) * limit;

    const filter = {};
    if (status) filter.status = status;
    if (isOnline !== undefined) filter.isOnline = isOnline === 'true';

    const drivers = await Driver.find(filter)
      .populate('userId', 'name phone email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Driver.countDocuments(filter);

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

// Sürücü statusunu yenilə
router.put('/drivers/:driverId', auth, authorize('admin'), [
  body('status').isIn(['pending', 'approved', 'rejected', 'suspended']).withMessage('Düzgün status seçin'),
  body('commission').optional().isFloat({ min: 0, max: 100 }).withMessage('Komissiya 0-100 arasında olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { status, commission } = req.body;
    const updates = { status };

    if (commission !== undefined) {
      updates.commission = commission;
    }

    const driver = await Driver.findByIdAndUpdate(
      req.params.driverId,
      updates,
      { new: true, runValidators: true }
    ).populate('userId', 'name phone email');

    if (!driver) {
      return res.status(404).json({ error: 'Sürücü tapılmadı' });
    }

    res.json({
      message: 'Sürücü uğurla yeniləndi',
      driver
    });
  } catch (error) {
    console.error('Sürücü yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifarişlər statistikası
router.get('/orders/stats', auth, authorize('admin'), async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const filter = {};

    if (startDate && endDate) {
      filter.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    // Status-a görə qruplaşdır
    const statusStats = await Order.aggregate([
      { $match: filter },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);

    // Günlük qazanc
    const completedOrders = await Order.findAll({
      where: {
        ...filter,
        status: 'completed'
      },
      attributes: [
        'createdAt',
        'fare'
      ],
      order: [['createdAt', 'DESC']],
      limit: 1000 // Get more data for grouping
    });

    // Group by date and calculate daily revenue
    const dailyRevenueMap = {};
    completedOrders.forEach(order => {
      const date = order.createdAt.toISOString().split('T')[0];
      if (!dailyRevenueMap[date]) {
        dailyRevenueMap[date] = { revenue: 0, count: 0 };
      }
      dailyRevenueMap[date].revenue += parseFloat(order.fare?.total || 0);
      dailyRevenueMap[date].count += 1;
    });

    const dailyRevenue = Object.entries(dailyRevenueMap)
      .map(([date, data]) => ({
        _id: date,
        revenue: data.revenue,
        count: data.count
      }))
      .sort((a, b) => b._id.localeCompare(a._id))
      .slice(0, 30);

    // Ümumi qazanc
    const totalRevenueData = completedOrders.reduce((acc, order) => {
      acc.total += parseFloat(order.fare?.total || 0);
      acc.count += 1;
      return acc;
    }, { total: 0, count: 0 });

    const totalRevenue = [totalRevenueData];

    res.json({
      statusStats,
      dailyRevenue,
      totalRevenue: totalRevenue[0] || { total: 0, count: 0 }
    });
  } catch (error) {
    console.error('Sifariş statistikası xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sürücü qazanc statistikası
router.get('/drivers/earnings', auth, authorize('admin'), async (req, res) => {
  try {
    const { startDate, endDate, driverId } = req.query;
    const filter = { status: 'completed' };

    if (startDate && endDate) {
      filter.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    if (driverId) {
      filter.driver = driverId;
    }

    const completedOrders = await Order.findAll({
      where: filter,
      include: [
        {
          model: Driver,
          as: 'driver',
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['name']
            }
          ]
        }
      ],
      attributes: ['fare', 'driverId']
    });

    // Group by driver and calculate earnings
    const earningsMap = {};
    completedOrders.forEach(order => {
      const driverId = order.driverId;
      if (!earningsMap[driverId]) {
        earningsMap[driverId] = {
          _id: driverId,
          driverName: order.driver?.user?.name || 'Unknown',
          totalOrders: 0,
          totalRevenue: 0,
          commission: 0,
          netEarnings: 0
        };
      }
      
      const fareTotal = parseFloat(order.fare?.total || 0);
      const commissionRate = order.driver?.commission || 20; // Default 20%
      const commission = fareTotal * (commissionRate / 100);
      
      earningsMap[driverId].totalOrders += 1;
      earningsMap[driverId].totalRevenue += fareTotal;
      earningsMap[driverId].commission += commission;
      earningsMap[driverId].netEarnings += (fareTotal - commission);
    });

    const earnings = Object.values(earningsMap)
      .sort((a, b) => b.totalRevenue - a.totalRevenue);

    res.json({ earnings });
  } catch (error) {
    console.error('Sürücü qazanc statistikası xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sistem parametrlərini idarə et
router.get('/settings', auth, authorize('admin'), async (req, res) => {
  try {
    // Sistem parametrləri (sadə versiya)
    const settings = {
      baseFare: 2,
      perKmRate: 0.5,
      perMinuteRate: 0.1,
      defaultCommission: 20,
      maxDistance: 5,
      orderTimeout: 300 // 5 dəqiqə
    };

    res.json({ settings });
  } catch (error) {
    console.error('Parametrlər alma xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sistem parametrlərini yenilə
router.put('/settings', auth, authorize('admin'), [
  body('baseFare').optional().isFloat({ min: 0 }).withMessage('Əsas qiymət müsbət olmalıdır'),
  body('perKmRate').optional().isFloat({ min: 0 }).withMessage('Km başına qiymət müsbət olmalıdır'),
  body('perMinuteRate').optional().isFloat({ min: 0 }).withMessage('Dəqiqə başına qiymət müsbət olmalıdır'),
  body('defaultCommission').optional().isFloat({ min: 0, max: 100 }).withMessage('Komissiya 0-100 arasında olmalıdır'),
  body('maxDistance').optional().isFloat({ min: 0 }).withMessage('Maksimum məsafə müsbət olmalıdır'),
  body('orderTimeout').optional().isInt({ min: 60 }).withMessage('Sifariş vaxtı minimum 60 saniyə olmalıdır')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    // Burada parametrləri database-də saxlayıb yeniləyə bilərsiniz
    // Sadəlik üçün yalnız response qaytarırıq

    res.json({
      message: 'Sistem parametrləri uğurla yeniləndi',
      settings: req.body
    });
  } catch (error) {
    console.error('Parametrlər yeniləmə xətası:', error);
    res.status(500).json({ error: 'Server xətası' });
  }
});

// Sifarişlər siyahısı (admin üçün)
router.get('/orders', auth, authorize('admin'), async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      status, 
      startDate, 
      endDate,
      customerPhone,
      driverPhone
    } = req.query;
    
    const skip = (page - 1) * limit;
    const filter = {};

    if (status) filter.status = status;
    if (startDate && endDate) {
      filter.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    if (customerPhone) {
      const customer = await User.findOne({ phone: customerPhone });
      if (customer) {
        filter.customer = customer._id;
      }
    }

    if (driverPhone) {
      const driver = await Driver.findOne().populate({
        path: 'userId',
        match: { phone: driverPhone }
      });
      if (driver) {
        filter.driver = driver._id;
      }
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

module.exports = router; 