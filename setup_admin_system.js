
require('dotenv').config();
const { sequelize } = require('./config/database');
const bcrypt = require('bcryptjs');

async function setupAdminSystem() {
  try {
    console.log('🚀 Setting up admin system...');

    // Check if DATABASE_URL is set
    if (!process.env.DATABASE_URL) {
      console.error('❌ DATABASE_URL environment variable is not set!');
      console.log('\n📋 Please create a .env file with the following content:');
      console.log('DATABASE_URL=postgresql://username:password@localhost:5432/ayiqsurucu');
      console.log('JWT_SECRET=your-super-secret-jwt-key-here');
      console.log('NODE_ENV=development');
      console.log('\nOr copy from env.example:');
      console.log('copy env.example .env');
      console.log('\nThen edit the .env file with your actual database credentials.');
      process.exit(1);
    }

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

    // 3. Check if admin role exists
    const adminRoles = await sequelize.query('SELECT id FROM roles WHERE name = \'admin\'', {
      
      type: sequelize.QueryTypes.SELECT
    });
    
    if (adminRoles.length === 0) {
      console.log('❌ Admin role not found. Please run admin_database_setup_postgresql.sql first.');
      return;
    }

    const adminRoleId = adminRoles[0].id;
    console.log('✅ Admin role found with ID:', adminRoleId);

    // 4. Check if there are any users without role_id
    const usersWithoutRole = await sequelize.query('SELECT id, name, email, phone FROM users WHERE role_id IS NULL', {
      type: sequelize.QueryTypes.SELECT
    });
    
    if (usersWithoutRole.length > 0) {
      console.log('👥 Found users without role_id:', usersWithoutRole.length);
      
      // Assign admin role to the first user (you can modify this logic)
      const firstUser = usersWithoutRole[0];
      await sequelize.query(`UPDATE users SET role_id = ${adminRoleId} WHERE id =${firstUser.id}`, {
        //replacements: [adminRoleId, firstUser.id],
        type: sequelize.QueryTypes.UPDATE
      });
      console.log(`✅ Assigned admin role to user: ${firstUser.name} (${firstUser.email || firstUser.phone})`);
      
      // Assign operator role to other users
      const operatorRoles = await sequelize.query('SELECT id FROM roles WHERE name = \'operator\'', {
        replacements: ['operator'],
        type: sequelize.QueryTypes.SELECT
      });
      if (operatorRoles.length > 0) {
        const operatorRoleId = operatorRoles[0].id;
        for (let i = 1; i < usersWithoutRole.length; i++) {
          const user = usersWithoutRole[i];
          await sequelize.query(`UPDATE users SET role_id = ${operatorRoleId} WHERE id = ${user.id}`, {
          //  replacements: [operatorRoleId, user.id],
            type: sequelize.QueryTypes.UPDATE
          });
          console.log(`✅ Assigned operator role to user: ${user.name} (${user.email || user.phone})`);
        }
      }
    } else {
      console.log('✅ All users already have roles assigned');
    }

    // 5. Create a test admin user if none exists
    const adminUsers = await sequelize.query(`
      SELECT u.id FROM users u 
      JOIN roles r ON u.role_id = r.id 
      WHERE r.name = \'admin\'
    `, {
    //  replacements: ['admin'],
      type: sequelize.QueryTypes.SELECT
    });
    
    if (adminUsers.length === 0) {
      console.log('👤 Creating test admin user...');
      const hashedPassword = await bcrypt.hash('admin123', 12);
      
      const result = await sequelize.query(`
        INSERT INTO users (name, email, phone, password, role_id, "isActive") 
        VALUES (\'Admin User\', \'admin@example.com\', \'+1234567890\', ${hashedPassword}, ${adminRoleId}, ${true})
        RETURNING id
      `, {
     //   replacements: ['Admin User', 'admin@example.com', '+1234567890', hashedPassword, adminRoleId, true],
        type: sequelize.QueryTypes.INSERT
      });
      
      console.log('✅ Test admin user created:');
      console.log('   Email: admin@example.com');
      console.log('   Password: admin123');
      console.log('   User ID:', result[0].id);
    } else {
      console.log('✅ Admin users already exist');
    }

    // 6. Create test dispatcher user if none exists
    const dispatcherUsers = await sequelize.query(`
      SELECT u.id FROM users u 
      JOIN roles r ON u.role_id = r.id 
      WHERE r.name = \'dispatcher\'
    `, {
    //  replacements: ['dispatcher'],
      type: sequelize.QueryTypes.SELECT
    });
    
    if (dispatcherUsers.length === 0) {
      console.log('👤 Creating test dispatcher user...');
      const hashedPassword = await bcrypt.hash('dispatcher123', 12);
      
      // Get dispatcher role ID
      const dispatcherRoles = await sequelize.query('SELECT id FROM roles WHERE name = \'dispatcher\'', {
       // replacements: ['dispatcher'],
        type: sequelize.QueryTypes.SELECT
      });
      
      if (dispatcherRoles.length > 0) {
        const dispatcherRoleId = dispatcherRoles[0].id;
        
        const result = await sequelize.query(`
          INSERT INTO users (name, email, phone, password, role_id, "isActive") 
          VALUES (\'Dispatcher User\', \'dispatcher@example.com\', \'+1234567891\', ${hashedPassword}, ${dispatcherRoleId}, ${true})
          RETURNING id
        `, {
          //replacements: ['Dispatcher User', 'dispatcher@example.com', '+1234567891', hashedPassword, dispatcherRoleId, true],
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

    console.log('🎉 Admin system setup completed!');
    console.log('\n📋 Next steps:');
    console.log('1. Run admin_database_setup_postgresql.sql in your PostgreSQL database');
    console.log('2. Login with admin credentials in your Flutter app');
    console.log('3. Access the admin panel to manage roles and users');
    console.log('\n🔑 Test Credentials:');
    console.log('   Admin: admin@example.com / admin123');
    console.log('   Dispatcher: dispatcher@example.com / dispatcher123');

  } catch (error) {
    console.error('❌ Error setting up admin system:', error);
  } finally {
    await sequelize.close();
    process.exit(0);
  }
}

setupAdminSystem();
