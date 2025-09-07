require('dotenv').config();
const { sequelize } = require('./config/database');
const bcrypt = require('bcryptjs');

async function fixRoleIdSyntax() {
  try {
    console.log('🔧 Fixing role_id syntax issues...');

    // 1. Connect to database
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');

    // 2. Check if role_id column exists
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

    // 3. Get existing roles
    const roles = await sequelize.query('SELECT id, name FROM roles', {
      type: sequelize.QueryTypes.SELECT
    });

    console.log('📋 Available roles:', roles.map(r => `${r.name} (ID: ${r.id})`));

    // 4. Get users without role_id
    const usersWithoutRole = await sequelize.query(`
      SELECT id, name, email, phone, role 
      FROM users 
      WHERE role_id IS NULL
    `, {
      type: sequelize.QueryTypes.SELECT
    });

    if (usersWithoutRole.length > 0) {
      console.log('👥 Found users without role_id:', usersWithoutRole.length);
      
      const roleMap = {};
      roles.forEach(role => {
        roleMap[role.name] = role.id;
      });
      
      // Update users one by one using a simpler approach
      for (const user of usersWithoutRole) {
        let roleId = null;
        
        if (user.role && roleMap[user.role]) {
          roleId = roleMap[user.role];
        } else if (user.role === 'admin' || user.role === 'operator') {
          roleId = roleMap['admin'];
        } else {
          roleId = roleMap['operator'] || roleMap['admin'];
        }
        
        if (roleId) {
          // Use a simpler query approach
          const updateQuery = `
            UPDATE users 
            SET role_id = ${roleId} 
            WHERE id = '${user.id}'
          `;
          
          await sequelize.query(updateQuery, {
            type: sequelize.QueryTypes.UPDATE
          });
          
          console.log(`✅ Assigned role_id ${roleId} to user: ${user.name} (${user.email || user.phone}) - role: ${user.role}`);
        }
      }
    } else {
      console.log('✅ All users already have roles assigned');
    }

    // 5. Create test admin user if none exists
    const adminRoleId = roles.find(r => r.name === 'admin')?.id;
    if (adminRoleId) {
      const adminUsers = await sequelize.query(`
        SELECT u.id FROM users u 
        JOIN roles r ON u.role_id = r.id 
        WHERE r.name = 'admin'
      `, {
        type: sequelize.QueryTypes.SELECT
      });
      
      if (adminUsers.length === 0) {
        console.log('👤 Creating test admin user...');
        const hashedPassword = await bcrypt.hash('admin123', 12);
        
        const insertQuery = `
          INSERT INTO users (name, email, phone, password, role_id, "isActive", role) 
          VALUES ('Admin User', 'admin@example.com', '+1234567890', '${hashedPassword}', ${adminRoleId}, true, 'admin')
          RETURNING id
        `;
        
        const result = await sequelize.query(insertQuery, {
          type: sequelize.QueryTypes.INSERT
        });
        
        console.log('✅ Test admin user created:');
        console.log('   Email: admin@example.com');
        console.log('   Password: admin123');
        console.log('   User ID:', result[0].id);
      } else {
        console.log('✅ Admin users already exist');
      }
    }

    // 6. Create test dispatcher user if none exists
    const dispatcherRoleId = roles.find(r => r.name === 'dispatcher')?.id;
    if (dispatcherRoleId) {
      const dispatcherUsers = await sequelize.query(`
        SELECT u.id FROM users u 
        JOIN roles r ON u.role_id = r.id 
        WHERE r.name = 'dispatcher'
      `, {
        type: sequelize.QueryTypes.SELECT
      });
      
      if (dispatcherUsers.length === 0) {
        console.log('👤 Creating test dispatcher user...');
        const hashedPassword = await bcrypt.hash('dispatcher123', 12);
        
        const insertQuery = `
          INSERT INTO users (name, email, phone, password, role_id, "isActive", role) 
          VALUES ('Dispatcher User', 'dispatcher@example.com', '+1234567891', '${hashedPassword}', ${dispatcherRoleId}, true, 'dispatcher')
          RETURNING id
        `;
        
        const result = await sequelize.query(insertQuery, {
          type: sequelize.QueryTypes.INSERT
        });
        
        console.log('✅ Test dispatcher user created:');
        console.log('   Email: dispatcher@example.com');
        console.log('   Password: dispatcher123');
        console.log('   User ID:', result[0].id);
      } else {
        console.log('✅ Dispatcher users already exist');
      }
    }

    // 7. Show final summary
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

    console.log('\n🎉 Fix completed successfully!');
    console.log('\n🔑 Test Credentials:');
    console.log('   Admin: admin@example.com / admin123');
    console.log('   Dispatcher: dispatcher@example.com / dispatcher123');

  } catch (error) {
    console.error('❌ Fix failed:', error.message);
    console.error('Stack trace:', error.stack);
  } finally {
    await sequelize.close();
    process.exit(0);
  }
}

fixRoleIdSyntax();
