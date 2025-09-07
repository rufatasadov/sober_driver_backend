const { sequelize } = require('./config/database');
const bcrypt = require('bcryptjs');

async function setupAdminSystem() {
  try {
    console.log('🚀 Setting up admin system...');

    // 1. Connect to database
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');

    // 2. Check if admin role exists
    const [adminRoles] = await sequelize.query('SELECT id FROM roles WHERE name = ?', {
      replacements: ['admin'],
      type: sequelize.QueryTypes.SELECT
    });
    
    if (adminRoles.length === 0) {
      console.log('❌ Admin role not found. Please run admin_database_setup.sql first.');
      return;
    }

    const adminRoleId = adminRoles[0].id;
    console.log('✅ Admin role found with ID:', adminRoleId);

    // 3. Check if there are any users without role_id
    const [usersWithoutRole] = await sequelize.query('SELECT id, name, email, phone FROM users WHERE role_id IS NULL', {
      type: sequelize.QueryTypes.SELECT
    });
    
    if (usersWithoutRole.length > 0) {
      console.log('👥 Found users without role_id:', usersWithoutRole.length);
      
      // Assign admin role to the first user (you can modify this logic)
      const firstUser = usersWithoutRole[0];
      await sequelize.query('UPDATE users SET role_id = ? WHERE id = ?', {
        replacements: [adminRoleId, firstUser.id],
        type: sequelize.QueryTypes.UPDATE
      });
      console.log(`✅ Assigned admin role to user: ${firstUser.name} (${firstUser.email || firstUser.phone})`);
      
      // Assign operator role to other users
      const [operatorRoles] = await sequelize.query('SELECT id FROM roles WHERE name = ?', {
        replacements: ['operator'],
        type: sequelize.QueryTypes.SELECT
      });
      if (operatorRoles.length > 0) {
        const operatorRoleId = operatorRoles[0].id;
        for (let i = 1; i < usersWithoutRole.length; i++) {
          const user = usersWithoutRole[i];
          await sequelize.query('UPDATE users SET role_id = ? WHERE id = ?', {
            replacements: [operatorRoleId, user.id],
            type: sequelize.QueryTypes.UPDATE
          });
          console.log(`✅ Assigned operator role to user: ${user.name} (${user.email || user.phone})`);
        }
      }
    } else {
      console.log('✅ All users already have roles assigned');
    }

    // 4. Create a test admin user if none exists
    const [adminUsers] = await sequelize.query(`
      SELECT u.id FROM users u 
      JOIN roles r ON u.role_id = r.id 
      WHERE r.name = 'admin'
    `, {
      type: sequelize.QueryTypes.SELECT
    });
    
    if (adminUsers.length === 0) {
      console.log('👤 Creating test admin user...');
      const hashedPassword = await bcrypt.hash('admin123', 12);
      
      const [result] = await sequelize.query(`
        INSERT INTO users (name, email, phone, password, role_id, "isActive") 
        VALUES (?, ?, ?, ?, ?, ?)
      `, {
        replacements: ['Admin User', 'admin@example.com', '+1234567890', hashedPassword, adminRoleId, true],
        type: sequelize.QueryTypes.INSERT
      });
      
      console.log('✅ Test admin user created:');
      console.log('   Email: admin@example.com');
      console.log('   Password: admin123');
      console.log('   User ID:', result[0]);
    } else {
      console.log('✅ Admin users already exist');
    }

    console.log('🎉 Admin system setup completed!');
    console.log('\n📋 Next steps:');
    console.log('1. Run admin_database_setup.sql in your database');
    console.log('2. Login with admin credentials in your Flutter app');
    console.log('3. Access the admin panel to manage roles and users');

  } catch (error) {
    console.error('❌ Error setting up admin system:', error);
  } finally {
    await sequelize.close();
    process.exit(0);
  }
}

setupAdminSystem();
