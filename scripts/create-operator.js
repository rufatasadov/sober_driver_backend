const { sequelize } = require('../config/database');
const User = require('../models/User');

async function createDefaultOperator() {
  try {
    await sequelize.authenticate();
    console.log('Database connection established.');

    // Check if operator already exists
    const existingOperator = await User.findOne({
      where: { username: 'operator' }
    });

    if (existingOperator) {
      console.log('Operator user already exists.');
      return;
    }

    // Create default operator
    const operator = await User.create({
      username: 'operator',
      password: 'operator123', // This will be hashed by the beforeCreate hook
      name: 'Operator User',
      phone: '+994501234567',
      role: 'operator',
      isVerified: true,
      isActive: true
    });

    console.log('Default operator created successfully:');
    console.log('Username: operator');
    console.log('Password: operator123');
    console.log('User ID:', operator.id);

  } catch (error) {
    console.error('Error creating operator:', error);
  } finally {
    await sequelize.close();
  }
}

createDefaultOperator(); 