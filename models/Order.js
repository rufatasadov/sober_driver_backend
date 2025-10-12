const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');
const User = require('./User');
const Driver = require('./Driver');
const Setting = require('./Setting');

const Order = sequelize.define('Order', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  orderNumber: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  customerId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  driverId: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'drivers',
      key: 'id'
    }
  },
  pickup: {
    type: DataTypes.JSONB,
    allowNull: false
  },
  destination: {
    type: DataTypes.JSONB,
    allowNull: false
  },
  // Optional intermediate stops between pickup and destination
  stops: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: []
  },
  status: {
    type: DataTypes.ENUM(
      'pending', 
      'accepted', 
      'driver_assigned', 
      'driver_arrived', 
      'in_progress', 
      'completed', 
      'cancelled'
    ),
    defaultValue: 'pending'
  },
  estimatedTime: {
    type: DataTypes.INTEGER, // minutes
    allowNull: true
  },
  estimatedDistance: {
    type: DataTypes.DECIMAL(8, 2), // kilometers
    allowNull: true
  },
  fare: {
    type: DataTypes.JSONB,
    allowNull: false,
    defaultValue: {
      base: 0,
      distance: 0,
      time: 0,
      total: 0,
      currency: 'AZN'
    }
  },
  payment: {
    type: DataTypes.JSONB,
    defaultValue: {
      method: 'cash',
      status: 'pending',
      transactionId: null
    }
  },
  rating: {
    type: DataTypes.JSONB,
    allowNull: true
  },
  timeline: {
    type: DataTypes.JSONB,
    defaultValue: []
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  cancelledBy: {
    type: DataTypes.ENUM('customer', 'driver', 'operator', 'system'),
    allowNull: true
  },
  cancellationReason: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  tableName: 'orders',
  timestamps: true,
  hooks: {
    beforeCreate: async (order) => {
      try {
        // CustomerId yoxla
        if (!order.customerId) {
          throw new Error('customerId is required');
        }

        // Generate order number if not provided
        if (!order.orderNumber) {
          const prefix = await Setting.getValue('order_prefix', 'ORD');
          const date = new Date();
          const year = date.getFullYear();
          const month = String(date.getMonth() + 1).padStart(2, '0');
          const day = String(date.getDate()).padStart(2, '0');
          const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
          order.orderNumber = `${prefix}-${year}${month}${day}-${random}`;
        }
        
        console.log('Creating order with:', {
          orderNumber: order.orderNumber,
          customerId: order.customerId,
          status: order.status
        });
      } catch (error) {
        console.error('Order creation hook error:', error);
        throw error;
      }
    }
  }
});

// Associations
Order.belongsTo(User, { foreignKey: 'customerId', as: 'customer' });
Order.belongsTo(Driver, { foreignKey: 'driverId', as: 'driver' });
User.hasMany(Order, { foreignKey: 'customerId', as: 'orders' });
Driver.hasMany(Order, { foreignKey: 'driverId', as: 'orders' });

// Instance methods: keep createdAt/updatedAt so clients can display timestamps
Order.prototype.toJSON = function() {
  const values = Object.assign({}, this.get());
  if (values.createdAt instanceof Date) {
    values.createdAt = values.createdAt.toISOString();
  }
  if (values.updatedAt instanceof Date) {
    values.updatedAt = values.updatedAt.toISOString();
  }
  return values;
};

module.exports = Order; 