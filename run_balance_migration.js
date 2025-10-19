const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🔄 Running balance migration for drivers...');

try {
  // Read the migration SQL file
  const migrationPath = path.join(__dirname, 'add_balance_to_drivers.sql');
  const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
  
  console.log('📄 Migration SQL:');
  console.log(migrationSQL);
  
  // Execute the migration
  execSync(`psql -d ayiqsurucu -c "${migrationSQL}"`, { 
    stdio: 'inherit',
    env: { ...process.env, PGPASSWORD: 'password' }
  });
  
  console.log('✅ Balance migration completed successfully!');
  console.log('💰 All drivers now have a balance field initialized to 0.00');
  
} catch (error) {
  console.error('❌ Migration failed:', error.message);
  process.exit(1);
}
