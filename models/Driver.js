const mongoose = require('mongoose');

const driverSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  licenseNumber: {
    type: String,
    required: true,
    unique: true
  },
  vehicleInfo: {
    make: String,
    model: String,
    year: Number,
    color: String,
    plateNumber: {
      type: String,
      required: true,
      unique: true
    }
  },
  documents: {
    license: String,
    insurance: String,
    registration: String,
    vehiclePhoto: String
  },
  isOnline: {
    type: Boolean,
    default: false
  },
  currentLocation: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number],
      default: [0, 0]
    },
    address: String
  },
  rating: {
    average: {
      type: Number,
      default: 0,
      min: 0,
      max: 5
    },
    count: {
      type: Number,
      default: 0
    }
  },
  earnings: {
    total: {
      type: Number,
      default: 0
    },
    today: {
      type: Number,
      default: 0
    },
    thisWeek: {
      type: Number,
      default: 0
    },
    thisMonth: {
      type: Number,
      default: 0
    }
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'suspended'],
    default: 'pending'
  },
  isAvailable: {
    type: Boolean,
    default: false
  },
  lastActive: {
    type: Date,
    default: Date.now
  },
  commission: {
    type: Number,
    default: 20 // percentage
  }
}, {
  timestamps: true
});

// Geospatial index for location queries
driverSchema.index({ currentLocation: '2dsphere' });
driverSchema.index({ userId: 1 });
driverSchema.index({ isOnline: 1, isAvailable: 1 });

module.exports = mongoose.model('Driver', driverSchema); 