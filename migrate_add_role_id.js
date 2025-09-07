require('dotenv').config();
const { sequelize } = require('./config/database');

async function migrateAddRoleId() {
  try {
    console.log('🔄 Starting migration: Adding role_id column to users table...');

    // 1. Connect to database
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');

    // 2. Check if role_id column already exists
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

    if (columnExists[0].exists) {
      console.log('✅ role_id column already exists');
      return;
    }

    // 3. Add role_id column
    await sequelize.query(`
      ALTER TABLE users 
      ADD COLUMN role_id INTEGER REFERENCES roles(id);
    `, {
      type: sequelize.QueryTypes.RAW
    });

    console.log('✅ Added role_id column to users table');

    // 4. Check if roles table exists and has data
    const rolesExist = await sequelize.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'roles'
      );
    `, {
      type: sequelize.QueryTypes.SELECT
    });

    if (!rolesExist[0].exists) {
      console.log('⚠️  Roles table does not exist. Please run admin_database_setup_postgresql.sql first.');
      return;
    }

    // 5. Get existing roles
    const roles = await sequelize.query('SELECT id, name FROM roles', {
      type: sequelize.QueryTypes.SELECT
    });

    console.log('📋 Found roles:', roles.map(r => `${r.name} (ID: ${r.id})`));

    // 6. Update existing users with role_id based on their role field
    for (const role of roles) {
      const result = await sequelize.query(`
        UPDATE users 
        SET role_id = $1 
        WHERE role = $2 AND role_id IS NULL
      `, {
        replacements: [role.id, role.name],
        type: sequelize.QueryTypes.UPDATE
      });

      console.log(`✅ Updated ${result[1]} users with role: ${role.name}`);
    }

    // 7. Show summary
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

    console.log('\n📊 User role distribution:');
    userCounts.forEach(stat => {
      console.log(`   ${stat.role_name}: ${stat.user_count} users`);
    });

    console.log('\n🎉 Migration completed successfully!');
    console.log('\n📋 Next steps:');
    console.log('1. Run: node setup_admin_system.js');
    console.log('2. Test your admin and dispatcher login endpoints');

  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error('Stack trace:', error.stack);
  } finally {
    await sequelize.close();
    process.exit(0);
  }
}

migrateAddRoleId();
