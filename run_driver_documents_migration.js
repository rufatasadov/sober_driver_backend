require('dotenv').config();
const { sequelize } = require('./config/database');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  try {
    console.log('🚀 Starting driver documents migration...');
    
    // Read migration SQL file
    const migrationPath = path.join(__dirname, 'migrations/add_driver_documents_fields.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    
    // Execute migration
    await sequelize.query(migrationSQL);
    
    console.log('✅ Driver documents migration completed successfully!');
    console.log('📋 Added fields:');
    console.log('   - identity_card_front (VARCHAR)');
    console.log('   - identity_card_back (VARCHAR)');
    console.log('   - license_front (VARCHAR)');
    console.log('   - license_back (VARCHAR)');
    console.log('   - actual_address (TEXT)');
    console.log('   - license_expiry_date (TIMESTAMP)');
    console.log('   - is_active (BOOLEAN)');
    console.log('   - Performance indexes created');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

// Run migration if called directly
if (require.main === module) {
  runMigration();
}

module.exports = runMigration;
