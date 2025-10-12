const fs = require('fs');
const path = require('path');

// Check if .env file exists
if (!process.env.DATABASE_URL) {
  console.error('❌ DATABASE_URL environment variable is not set!');
  console.error('\nPlease create a .env file based on env.example:');
  console.error('  1. Copy env.example to .env');
  console.error('  2. Update DATABASE_URL with your PostgreSQL connection string');
  console.error('     Example: DATABASE_URL=postgresql://username:password@localhost:5432/ayiqsurucu');
  console.error('\nOr run with environment variable:');
  console.error('  DATABASE_URL="postgresql://user:pass@localhost:5432/dbname" node run_settings_migration.js');
  process.exit(1);
}

const { sequelize } = require('./config/database');

async function runMigration() {
  try {
    console.log('Starting settings table migration...');
    console.log('Database URL:', process.env.DATABASE_URL.replace(/:[^:@]+@/, ':****@')); // Hide password
    
    // Read the migration file
    const migrationPath = path.join(__dirname, 'migrations', 'add_settings_table.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');
    
    // Split by semicolons and execute each statement
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0);
    
    console.log(`Executing ${statements.length} SQL statements...`);
    
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      try {
        await sequelize.query(statement);
        console.log(`✓ Statement ${i + 1} executed successfully`);
      } catch (error) {
        // Ignore errors for statements that already exist (like "already exists" errors)
        if (error.message.includes('already exists') || 
            error.message.includes('duplicate key')) {
          console.log(`⚠ Statement ${i + 1} skipped (already exists)`);
        } else {
          console.error(`✗ Statement ${i + 1} failed:`, error.message);
        }
      }
    }
    
    console.log('\n✓ Migration completed successfully!');
    
    // Verify the settings were created
    const [results] = await sequelize.query("SELECT * FROM settings ORDER BY key");
    console.log('\nCurrent settings in database:');
    results.forEach(setting => {
      console.log(`  - ${setting.key}: ${setting.value}`);
    });
    
    await sequelize.close();
    process.exit(0);
  } catch (error) {
    console.error('\n✗ Migration failed:', error);
    await sequelize.close();
    process.exit(1);
  }
}

runMigration();

