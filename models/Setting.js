const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Setting = sequelize.define('Setting', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  key: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true
  },
  value: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  tableName: 'settings',
  timestamps: true,
  underscored: true
});

// Static method to get a setting value
Setting.getValue = async function(key, defaultValue = null) {
  try {
    const setting = await Setting.findOne({ where: { key } });
    return setting ? setting.value : defaultValue;
  } catch (error) {
    console.error(`Error getting setting ${key}:`, error);
    return defaultValue;
  }
};

// Static method to set a setting value
Setting.setValue = async function(key, value, description = null) {
  try {
    const [setting, created] = await Setting.findOrCreate({
      where: { key },
      defaults: { value, description }
    });
    
    if (!created && setting.value !== value) {
      setting.value = value;
      if (description) {
        setting.description = description;
      }
      await setting.save();
    }
    
    return setting;
  } catch (error) {
    console.error(`Error setting value for ${key}:`, error);
    throw error;
  }
};

// Static method to get all settings as a key-value object
Setting.getAll = async function() {
  try {
    const settings = await Setting.findAll();
    const result = {};
    settings.forEach(setting => {
      result[setting.key] = setting.value;
    });
    return result;
  } catch (error) {
    console.error('Error getting all settings:', error);
    return {};
  }
};

module.exports = Setting;

