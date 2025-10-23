require('dotenv').config();
const { Sequelize } = require('sequelize');
const fs = require('fs');
const path = require('path');

// Database configuration
const sequelize = new Sequelize(process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/ayiqsurucu', {
  logging: false,
});

async function runAddressesMigration() {
  try {
    console.log('🚀 Starting addresses table migration...');
    
    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
    // Read the SQL migration file
    const migrationPath = path.join(__dirname, 'migrations', 'create_addresses_table.sql');
    const sqlContent = fs.readFileSync(migrationPath, 'utf8');
    
    console.log('📄 Reading migration file:', migrationPath);
    
    // Execute the SQL migration
    await sequelize.query(sqlContent);
    console.log('✅ Addresses table migration completed successfully');
    
    // Verify the table was created
    const [results] = await sequelize.query(`
      SELECT COUNT(*) as count FROM addresses;
    `);
    
    console.log(`📊 Addresses table created with ${results[0].count} sample records`);
    
    // Test search functionality
    console.log('🔍 Testing search functionality...');
    const [searchResults] = await sequelize.query(`
      SELECT address_text, formatted_address, city, district 
      FROM addresses 
      WHERE search_keywords && ARRAY['metro'] 
      ORDER BY popularity_score DESC 
      LIMIT 3;
    `);
    
    console.log('📍 Sample search results for "metro":');
    searchResults.forEach((result, index) => {
      console.log(`  ${index + 1}. ${result.address_text} (${result.city}, ${result.district})`);
    });
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await sequelize.close();
    console.log('🔌 Database connection closed');
  }
}

// Run the migration
runAddressesMigration();
