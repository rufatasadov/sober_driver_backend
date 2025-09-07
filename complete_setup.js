require('dotenv').config();
const { sequelize } = require('./config/database');
const bcrypt = require('bcryptjs');

async function completeSetup() {
  try {
    console.log('🚀 Starting complete setup for PostgreSQL + Role-based Access Control...');

    // 1. Connect to database
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');

    // 2. Check if roles table exists
    const tableExists = await sequelize.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'roles'
      );
    `, {
      type: sequelize.QueryTypes.SELECT
    });
    
    if (!tableExists[0].exists) {
      console.log('❌ Roles table not found. Please run admin_database_setup_postgresql.sql first.');
      console.log('\n📋 To fix this, run:');
      console.log('psql -U your_username -d ayiqsurucu -f admin_database_setup_postgresql.sql');
      return;
    }

    console.log('✅ Roles table exists');

    // 3. Check if role_id column exists in users table
    const columnExists = await sequelize.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'role_id'
      );
    `, {
      type: sequelize.QueryTypes.SELECT
    });

    if (!columnExists[0].exists) {
      console.log('🔧 Adding role_id column to users table...');
      
      // Add role_id column
      await sequelize.query(`
        ALTER TABLE users 
        ADD COLUMN role_id INTEGER REFERENCES roles(id);
      `, {
        type: sequelize.QueryTypes.RAW
      });

      console.log('✅ Added role_id column to users table');
    } else {
      console.log('✅ role_id column already exists');
    }

    // 4. Get existing roles
    const roles = await sequelize.query('SELECT id, name FROM roles', {
      type: sequelize.QueryTypes.SELECT
    });

    console.log('📋 Available roles:', roles.map(r => `${r.name} (ID: ${r.id})`));

    // 5. Update existing users with role_id based on their role field
    const usersWithoutRole = await sequelize.query('SELECT id, name, email, phone, role FROM users WHERE role_id IS NULL', {
      type: sequelize.QueryTypes.SELECT
    });

    if (usersWithoutRole.length > 0) {
      console.log('👥 Found users without role_id:', usersWithoutRole.length);
      
      const roleMap = {};
      roles.forEach(role => {
        roleMap[role.name] = role.id;
      });
      
      // Assign roles based on existing role field
      for (const user of usersWithoutRole) {
        let roleId = null;
        
        if (user.role && roleMap[user.role]) {
          roleId = roleMap[user.role];
        } else if (user.role === 'admin' || user.role === 'operator') {
          // For admin/operator users, assign admin role
          roleId = roleMap['admin'];
        } else {
          // For other users, assign operator role if available
          roleId = roleMap['operator'] || roleMap['admin'];
        }
        
        if (roleId) {
          await sequelize.query('UPDATE users SET role_id = $1 WHERE id = $2', {
            replacements: [roleId, user.id],
            type: sequelize.QueryTypes.UPDATE
          });
          console.log(`✅ Assigned role_id ${roleId} to user: ${user.name} (${user.email || user.phone}) - role: ${user.role}`);
        }
      }
    } else {
      console.log('✅ All users already have roles assigned');
    }

    // 6. Create test admin user if none exists
    const adminUsers = await sequelize.query(`
      SELECT u.id FROM users u 
      JOIN roles r ON u.role_id = r.id 
      WHERE r.name = $1
    `, {
      replacements: ['admin'],
      type: sequelize.QueryTypes.SELECT
    });
    
    if (adminUsers.length === 0) {
      console.log('👤 Creating test admin user...');
      const hashedPassword = await bcrypt.hash('admin123', 12);
      
      const adminRoleId = roles.find(r => r.name === 'admin')?.id;
      if (adminRoleId) {
        const result = await sequelize.query(`
          INSERT INTO users (name, email, phone, password, role_id, "isActive", role) 
          VALUES ($1, $2, $3, $4, $5, $6, $7)
          RETURNING id
        `, {
          replacements: ['Admin User', 'admin@example.com', '+1234567890', hashedPassword, adminRoleId, true, 'admin'],
          type: sequelize.QueryTypes.INSERT
        });
        
        console.log('✅ Test admin user created:');
        console.log('   Email: admin@example.com');
        console.log('   Password: admin123');
        console.log('   User ID:', result[0].id);
      }
    } else {
      console.log('✅ Admin users already exist');
    }

    // 7. Create test dispatcher user if none exists
    const dispatcherUsers = await sequelize.query(`
      SELECT u.id FROM users u 
      JOIN roles r ON u.role_id = r.id 
      WHERE r.name = $1
    `, {
      replacements: ['dispatcher'],
      type: sequelize.QueryTypes.SELECT
    });
    
    if (dispatcherUsers.length === 0) {
      console.log('👤 Creating test dispatcher user...');
      const hashedPassword = await bcrypt.hash('dispatcher123', 12);
      
      const dispatcherRoleId = roles.find(r => r.name === 'dispatcher')?.id;
      if (dispatcherRoleId) {
        const result = await sequelize.query(`
          INSERT INTO users (name, email, phone, password, role_id, "isActive", role) 
          VALUES ($1, $2, $3, $4, $5, $6, $7)
          RETURNING id
        `, {
          replacements: ['Dispatcher User', 'dispatcher@example.com', '+1234567891', hashedPassword, dispatcherRoleId, true, 'dispatcher'],
          type: sequelize.QueryTypes.INSERT
        });
        
        console.log('✅ Test dispatcher user created:');
        console.log('   Email: dispatcher@example.com');
        console.log('   Password: dispatcher123');
        console.log('   User ID:', result[0].id);
      }
    } else {
      console.log('✅ Dispatcher users already exist');
    }

    // 8. Show final summary
    const userCounts = await sequelize.query(`
      SELECT 
        r.name as role_name,
        COUNT(u.id) as user_count
      FROM roles r
      LEFT JOIN users u ON r.id = u.role_id
      GROUP BY r.id, r.name
      ORDER BY r.name
    `, {
      type: sequelize.QueryTypes.SELECT
    });

    console.log('\n📊 Final user role distribution:');
    userCounts.forEach(stat => {
      console.log(`   ${stat.role_name}: ${stat.user_count} users`);
    });

    console.log('\n🎉 Complete setup finished successfully!');
    console.log('\n🔑 Test Credentials:');
    console.log('   Admin: admin@example.com / admin123');
    console.log('   Dispatcher: dispatcher@example.com / dispatcher123');
    console.log('\n📋 Next steps:');
    console.log('1. Test your login endpoints');
    console.log('2. Test the Flutter app login screen');

  } catch (error) {
    console.error('❌ Setup failed:', error.message);
    console.error('Stack trace:', error.stack);
  } finally {
    await sequelize.close();
    process.exit(0);
  }
}

completeSetup();
