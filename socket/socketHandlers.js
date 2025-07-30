const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Driver = require('../models/Driver');
const Order = require('../models/Order');

const setupSocketHandlers = (io) => {
  // Authentication middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) {
        return next(new Error('Authentication error'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.userId);
      
      if (!user || !user.isActive) {
        return next(new Error('User not found or inactive'));
      }

      socket.userId = user._id;
      socket.userRole = user.role;
      next();
    } catch (error) {
      next(new Error('Authentication error'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`User connected: ${socket.userId} (${socket.userRole})`);

    // İstifadəçini müvafiq otağa qoş
    socket.join(`user_${socket.userId}`);
    
    if (socket.userRole === 'driver') {
      socket.join('drivers');
    }
    if (socket.userRole === 'operator') {
      socket.join('operators');
    }
    if (socket.userRole === 'dispatcher') {
      socket.join('dispatchers');
    }
    if (socket.userRole === 'admin') {
      socket.join('admins');
    }

    // Sürücü yerini yenilə
    socket.on('update_location', async (data) => {
      try {
        const { latitude, longitude, address } = data;
        
        await Driver.findOneAndUpdate(
          { userId: socket.userId },
          {
            currentLocation: {
              type: 'Point',
              coordinates: [longitude, latitude],
              address: address || ''
            },
            lastActive: new Date()
          }
        );

        // Digər sürücülərə yer yeniləməsini bildir
        socket.to('drivers').emit('driver_location_updated', {
          driverId: socket.userId,
          location: { latitude, longitude, address }
        });

        // Dispetçerlərə bildir
        socket.to('dispatchers').emit('driver_location_updated', {
          driverId: socket.userId,
          location: { latitude, longitude, address }
        });
      } catch (error) {
        console.error('Yer yeniləmə xətası:', error);
      }
    });

    // Sürücü statusunu yenilə
    socket.on('update_status', async (data) => {
      try {
        const { isOnline, isAvailable } = data;
        
        await Driver.findOneAndUpdate(
          { userId: socket.userId },
          { isOnline, isAvailable, lastActive: new Date() }
        );

        // Operator və dispetçerlərə bildir
        socket.to('operators').emit('driver_status_updated', {
          driverId: socket.userId,
          isOnline,
          isAvailable
        });

        socket.to('dispatchers').emit('driver_status_updated', {
          driverId: socket.userId,
          isOnline,
          isAvailable
        });
      } catch (error) {
        console.error('Status yeniləmə xətası:', error);
      }
    });

    // Yeni sifariş bildirişi
    socket.on('new_order', async (data) => {
      try {
        const { orderId } = data;
        const order = await Order.findById(orderId)
          .populate('customer', 'name phone')
          .populate('driver', 'userId');

        if (!order) return;

        // Yaxın sürücülərə bildir
        socket.to('drivers').emit('new_order_available', {
          order: {
            id: order._id,
            orderNumber: order.orderNumber,
            pickup: order.pickup,
            destination: order.destination,
            estimatedTime: order.estimatedTime,
            estimatedDistance: order.estimatedDistance,
            fare: order.fare,
            customer: order.customer
          }
        });

        // Operator və dispetçerlərə bildir
        socket.to('operators').emit('new_order_created', { order });
        socket.to('dispatchers').emit('new_order_created', { order });
      } catch (error) {
        console.error('Yeni sifariş bildirişi xətası:', error);
      }
    });

    // Sifariş statusu yeniləməsi
    socket.on('order_status_updated', async (data) => {
      try {
        const { orderId, status } = data;
        const order = await Order.findById(orderId)
          .populate('customer', 'name phone')
          .populate('driver', 'userId');

        if (!order) return;

        // Müştəriyə bildir
        socket.to(`user_${order.customer._id}`).emit('order_status_changed', {
          orderId: order._id,
          status,
          order
        });

        // Sürücüyə bildir (əgər varsa)
        if (order.driver) {
          socket.to(`user_${order.driver.userId._id}`).emit('order_status_changed', {
            orderId: order._id,
            status,
            order
          });
        }

        // Operator və dispetçerlərə bildir
        socket.to('operators').emit('order_status_updated', { order });
        socket.to('dispatchers').emit('order_status_updated', { order });
      } catch (error) {
        console.error('Sifariş statusu bildirişi xətası:', error);
      }
    });

    // Sürücü sifarişi qəbul etdi
    socket.on('order_accepted', async (data) => {
      try {
        const { orderId, driverId } = data;
        const order = await Order.findById(orderId)
          .populate('customer', 'name phone')
          .populate('driver', 'userId');

        if (!order) return;

        // Müştəriyə bildir
        socket.to(`user_${order.customer._id}`).emit('driver_assigned', {
          orderId: order._id,
          driver: order.driver,
          order
        });

        // Operator və dispetçerlərə bildir
        socket.to('operators').emit('driver_assigned_to_order', { order });
        socket.to('dispatchers').emit('driver_assigned_to_order', { order });
      } catch (error) {
        console.error('Sürücü təyin etmə bildirişi xətası:', error);
      }
    });

    // Sürücü sifarişi imtina etdi
    socket.on('order_rejected', async (data) => {
      try {
        const { orderId, driverId, reason } = data;
        const order = await Order.findById(orderId)
          .populate('customer', 'name phone');

        if (!order) return;

        // Müştəriyə bildir
        socket.to(`user_${order.customer._id}`).emit('driver_rejected_order', {
          orderId: order._id,
          reason
        });

        // Operator və dispetçerlərə bildir
        socket.to('operators').emit('driver_rejected_order', { orderId, reason });
        socket.to('dispatchers').emit('driver_rejected_order', { orderId, reason });
      } catch (error) {
        console.error('Sifariş imtina bildirişi xətası:', error);
      }
    });

    // Sifariş ləğv edildi
    socket.on('order_cancelled', async (data) => {
      try {
        const { orderId, reason } = data;
        const order = await Order.findById(orderId)
          .populate('customer', 'name phone')
          .populate('driver', 'userId');

        if (!order) return;

        // Sürücüyə bildir (əgər varsa)
        if (order.driver) {
          socket.to(`user_${order.driver.userId._id}`).emit('order_cancelled', {
            orderId: order._id,
            reason
          });
        }

        // Operator və dispetçerlərə bildir
        socket.to('operators').emit('order_cancelled', { orderId, reason });
        socket.to('dispatchers').emit('order_cancelled', { orderId, reason });
      } catch (error) {
        console.error('Sifariş ləğv bildirişi xətası:', error);
      }
    });

    // Sifariş tamamlandı
    socket.on('order_completed', async (data) => {
      try {
        const { orderId } = data;
        const order = await Order.findById(orderId)
          .populate('customer', 'name phone')
          .populate('driver', 'userId');

        if (!order) return;

        // Müştəriyə bildir
        socket.to(`user_${order.customer._id}`).emit('order_completed', {
          orderId: order._id,
          order
        });

        // Sürücüyə bildir
        if (order.driver) {
          socket.to(`user_${order.driver.userId._id}`).emit('order_completed', {
            orderId: order._id,
            order
          });
        }

        // Operator və dispetçerlərə bildir
        socket.to('operators').emit('order_completed', { order });
        socket.to('dispatchers').emit('order_completed', { order });
      } catch (error) {
        console.error('Sifariş tamamlama bildirişi xətası:', error);
      }
    });

    // Real-time tracking
    socket.on('track_order', async (data) => {
      try {
        const { orderId } = data;
        const order = await Order.findById(orderId);

        if (!order) return;

        // Tracking otağına qoş
        socket.join(`track_order_${orderId}`);

        // Mövcud tracking məlumatlarını göndər
        if (order.driver) {
          const driver = await Driver.findById(order.driver);
          if (driver && driver.currentLocation) {
            socket.emit('driver_location', {
              orderId,
              location: driver.currentLocation
            });
          }
        }
      } catch (error) {
        console.error('Tracking xətası:', error);
      }
    });

    // Tracking otağından çıx
    socket.on('stop_tracking', (data) => {
      const { orderId } = data;
      socket.leave(`track_order_${orderId}`);
    });

    // Disconnect
    socket.on('disconnect', async () => {
      console.log(`User disconnected: ${socket.userId}`);

      // Sürücü offline olduğunda statusu yenilə
      if (socket.userRole === 'driver') {
        try {
          await Driver.findOneAndUpdate(
            { userId: socket.userId },
            { isOnline: false, isAvailable: false }
          );

          // Operator və dispetçerlərə bildir
          socket.to('operators').emit('driver_offline', { driverId: socket.userId });
          socket.to('dispatchers').emit('driver_offline', { driverId: socket.userId });
        } catch (error) {
          console.error('Sürücü offline statusu yeniləmə xətası:', error);
        }
      }
    });
  });
};

module.exports = { setupSocketHandlers }; 