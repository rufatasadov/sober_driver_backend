const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');
const User = require('./User');

const Driver = sequelize.define('Driver', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  licenseNumber: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  vehicleInfo: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: null
  },
  documents: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: {}
  },
  isOnline: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  isAvailable: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  currentLocation: {
    type: DataTypes.JSONB,
    allowNull: true
  },
  rating: {
    type: DataTypes.JSONB,
    defaultValue: {
      average: 0,
      count: 0
    }
  },
  earnings: {
    type: DataTypes.JSONB,
    defaultValue: {
      total: 0,
      today: 0,
      thisWeek: 0,
      thisMonth: 0
    }
  },
  status: {
    type: DataTypes.ENUM('pending', 'approved', 'rejected', 'suspended'),
    defaultValue: 'pending'
  },
  commission: {
    type: DataTypes.DECIMAL(5, 2),
    defaultValue: 20.00
  },
  lastActive: {
    type: DataTypes.DATE,
    allowNull: true
  },
  lastLocationUpdate: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  tableName: 'drivers',
  timestamps: true
});

// Associations
Driver.belongsTo(User, { foreignKey: 'userId', as: 'user' });
User.hasOne(Driver, { foreignKey: 'userId', as: 'driver' });

// Instance methods
Driver.prototype.toJSON = function() {
  const values = Object.assign({}, this.get());
  delete values.createdAt;
  delete values.updatedAt;
  return values;
};

module.exports = Driver; 