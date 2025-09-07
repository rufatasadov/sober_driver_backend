# Admin System Setup Instructions

## Prerequisites
1. PostgreSQL database running
2. Node.js and npm installed
3. Environment variables configured

## Setup Steps

### 1. Create Environment File
Copy `env.example` to `.env` and update the database connection details:

```bash
cp env.example .env
```

Edit `.env` file and update:
```
DATABASE_URL=postgresql://username:password@localhost:5432/ayiqsurucu
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Run Database Setup
Execute the PostgreSQL version of the admin database setup:

```bash
psql -U username -d ayiqsurucu -f admin_database_setup_postgresql.sql
```

Or if you have a different PostgreSQL setup, run the SQL file in your preferred database client.

**Note:** Make sure your PostgreSQL database is running and accessible before running the setup script.

### 4. Run Migration (if you have existing users)
```bash
node migrate_add_role_id.js
```

### 5. Run Admin System Setup
```bash
node setup_admin_system.js
```

## What the Setup Does

1. **Connects to PostgreSQL database** using Sequelize
2. **Checks for admin role** - ensures the roles table exists
3. **Assigns roles to existing users** - gives admin role to first user, operator role to others
4. **Creates test users** if none exist:
   - **Admin User**: admin@example.com / admin123
   - **Dispatcher User**: dispatcher@example.com / dispatcher123

## Troubleshooting

- **Database connection error**: Check your DATABASE_URL in .env file
- **Admin role not found**: Run the PostgreSQL SQL file first
- **Permission errors**: Ensure your database user has CREATE/INSERT/UPDATE permissions

## Next Steps

After successful setup:
1. Login with admin credentials in your Flutter app
2. Access the admin panel to manage roles and users
3. Configure additional privileges as needed
