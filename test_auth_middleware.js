require('dotenv').config();
const { sequelize } = require('./config/database');

async function testAuthMiddleware() {
  try {
    console.log('🧪 Testing auth middleware and database connection...');

    // 1. Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');

    // 2. Test if roles table exists
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

    // 3. Test auth middleware query
    const users = await sequelize.query(`
      SELECT u.*, r.name as role_name, r.id as role_id,
             COALESCE(
               JSON_AGG(p.name) FILTER (WHERE p.name IS NOT NULL), 
               '[]'::json
             ) as privileges
      FROM users u
      LEFT JOIN roles r ON u.role_id = r.id
      LEFT JOIN role_privileges rp ON r.id = rp.role_id
      LEFT JOIN privileges p ON rp.privilege_id = p.id
      WHERE u.id = $1
      GROUP BY u.id, r.id, r.name
    `, {
      replacements: [1], // Test with user ID 1
      type: sequelize.QueryTypes.SELECT
    });

    console.log('✅ Auth middleware query works');
    console.log('📋 Found users:', users.length);

    // 4. Test admin routes query
    const roles = await sequelize.query(`
      SELECT r.*, 
             COALESCE(
               JSON_AGG(p.name) FILTER (WHERE p.name IS NOT NULL), 
               '[]'::json
             ) as privileges
      FROM roles r
      LEFT JOIN role_privileges rp ON r.id = rp.role_id
      LEFT JOIN privileges p ON rp.privilege_id = p.id
      GROUP BY r.id
    `, {
      type: sequelize.QueryTypes.SELECT
    });

    console.log('✅ Admin routes query works');
    console.log('📋 Found roles:', roles.length);

    console.log('\n🎉 All tests passed! Auth middleware is working correctly.');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error('Stack trace:', error.stack);
  } finally {
    await sequelize.close();
    process.exit(0);
  }
}

testAuthMiddleware();
