const { Sequelize, Op } = require('sequelize');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Database connection
const sequelize = new Sequelize(process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/ayiqsurucu');

// User model definition
const User = sequelize.define('User', {
  id: {
    type: Sequelize.UUID,
    defaultValue: Sequelize.UUIDV4,
    primaryKey: true
  },
  name: {
    type: Sequelize.STRING,
    allowNull: false
  },
  phone: {
    type: Sequelize.STRING,
    allowNull: false,
    unique: true
  },
  email: {
    type: Sequelize.STRING,
    allowNull: true,
    unique: true
  },
  username: {
    type: Sequelize.STRING,
    allowNull: false,
    unique: true
  },
  password: {
    type: Sequelize.STRING,
    allowNull: false
  },
  role: {
    type: Sequelize.STRING,
    allowNull: false,
    defaultValue: 'operator'
  },
  isActive: {
    type: Sequelize.BOOLEAN,
    defaultValue: true
  }
}, {
  tableName: 'users',
  timestamps: true
});

async function createOperatorUsers() {
  try {
    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connection established successfully.');

    // Define users to create
    const users = [
      {
        name: 'Admin User',
        phone: '+994501234567',
        email: 'admin@ayiqsurucu.com',
        username: 'admin',
        password: 'admin123',
        role: 'admin'
      },
      {
        name: 'Dispatcher User',
        phone: '+994501234568',
        email: 'dispatcher@ayiqsurucu.com',
        username: 'dispatcher',
        password: 'dispatcher123',
        role: 'dispatcher'
      },
      {
        name: 'Operator User',
        phone: '+994501234569',
        email: 'operator@ayiqsurucu.com',
        username: 'operator',
        password: 'operator123',
        role: 'operator'
      }
    ];

    console.log('🚀 Creating operator users...\n');

    for (const userData of users) {
      try {
        // Check if user already exists (simplified approach)
        const existingUserByUsername = await User.findOne({
          where: { username: userData.username }
        });
        
        const existingUserByPhone = await User.findOne({
          where: { phone: userData.phone }
        });
        
        const existingUserByEmail = await User.findOne({
          where: { email: userData.email }
        });

        if (existingUserByUsername || existingUserByPhone || existingUserByEmail) {
          console.log(`⚠️  User "${userData.username}" already exists. Skipping...`);
          continue;
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(userData.password, 10);

        // Create user
        const user = await User.create({
          name: userData.name,
          phone: userData.phone,
          email: userData.email,
          username: userData.username,
          password: hashedPassword,
          role: userData.role,
          isActive: true
        });

        console.log(`✅ Created ${userData.role}: ${userData.username}`);
        console.log(`   Name: ${userData.name}`);
        console.log(`   Phone: ${userData.phone}`);
        console.log(`   Email: ${userData.email}`);
        console.log(`   Password: ${userData.password}`);
        console.log(`   ID: ${user.id}\n`);

      } catch (error) {
        console.error(`❌ Error creating user "${userData.username}":`, error.message);
      }
    }

    console.log('🎉 Operator users creation completed!');
    console.log('\n📋 Summary:');
    console.log('┌─────────────┬──────────────┬──────────────┬──────────────┐');
    console.log('│ Role        │ Username     │ Password     │ Email        │');
    console.log('├─────────────┼──────────────┼──────────────┼──────────────┤');
    console.log('│ Admin       │ admin        │ admin123     │ admin@...    │');
    console.log('│ Dispatcher  │ dispatcher   │ dispatcher123│ dispatcher@..│');
    console.log('│ Operator    │ operator     │ operator123  │ operator@... │');
    console.log('└─────────────┴──────────────┴──────────────┴──────────────┘');

  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    console.log('\n🔧 Troubleshooting:');
    console.log('1. Make sure PostgreSQL is running');
    console.log('2. Check DATABASE_URL in .env file');
    console.log('3. Verify database credentials');
    console.log('4. Ensure database "ayiqsurucu" exists');
  } finally {
    await sequelize.close();
  }
}

// Run the script
if (require.main === module) {
  createOperatorUsers();
}

module.exports = { createOperatorUsers };
