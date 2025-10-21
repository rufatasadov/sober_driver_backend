# Admin Panel - Peregon hayda

## Overview

The Admin Panel provides comprehensive system administration capabilities for the Peregon hayda application, including role-based access control, user management, and parametric table management.

## Features

### 1. Role Management
- **Create Roles**: Define new roles with custom names and descriptions
- **Assign Privileges**: Grant specific permissions to each role
- **Update Roles**: Modify existing roles and their privileges
- **Delete Roles**: Remove roles (only if not assigned to users)

**Available Privileges:**
- `users.*` - User management operations
- `roles.*` - Role management operations
- `orders.*` - Order management operations
- `drivers.*` - Driver management operations
- `customers.*` - Customer management operations
- `payments.*` - Payment management operations
- `reports.read` - Access to reports
- `settings.*` - System settings management
- `parametric_tables.*` - Parametric table management

### 2. User Management
- **Create Users**: Add new users with role assignment
- **Update Users**: Modify user information and roles
- **Delete Users**: Remove users from the system
- **Role Assignment**: Assign users to specific roles

**User Fields:**
- Full Name
- Email Address
- Phone Number
- Role Assignment
- Password (for new users)

### 3. Parametric Table Management
- **Create Tables**: Define dynamic tables with custom columns
- **Column Types**: Support for text, number, boolean, date, email, phone, and select
- **Column Properties**: Set required, unique, and options for select fields
- **Update Tables**: Modify table structure and columns
- **Delete Tables**: Remove parametric tables

**Column Types:**
- `text` - Plain text input
- `number` - Numeric input
- `boolean` - True/False checkbox
- `date` - Date picker
- `email` - Email validation
- `phone` - Phone number input
- `select` - Dropdown with custom options

## Setup Instructions

### 1. Database Setup
Run the SQL script to create the necessary database tables:

```bash
mysql -u your_username -p your_database < admin_database_setup.sql
```

### 2. Backend Configuration
The admin routes are already configured in `routes/admin.js` and registered in `server.js`.

### 3. Flutter App Integration
The admin panel is integrated into the main dashboard with the following components:

- `AdminScreen` - Main admin interface
- `AdminProvider` - State management for admin operations
- `RoleManagementTab` - Role management interface
- `UserManagementTab` - User management interface
- `ParametricTableTab` - Parametric table management interface

## Usage

### Accessing the Admin Panel
1. Navigate to the dashboard
2. Click on "Admin Panel" in the sidebar
3. Use the tabbed interface to manage different aspects

### Creating a New Role
1. Go to the "Role Management" tab
2. Click "Create Role"
3. Enter role name and description
4. Select privileges from the checklist
5. Click "Create"

### Managing Users
1. Go to the "User Management" tab
2. Click "Create User" to add new users
3. Use edit/delete buttons to modify existing users
4. Assign appropriate roles to users

### Creating Parametric Tables
1. Go to the "Parametric Tables" tab
2. Click "Create Table"
3. Define table name and description
4. Add columns with appropriate types and properties
5. Save the table structure

## Security Features

- **Role-based Access Control**: Users can only access features based on their assigned role
- **Admin Privilege Check**: Admin panel access requires specific privileges
- **Input Validation**: All inputs are validated on both frontend and backend
- **Authentication Required**: All admin operations require valid authentication

## API Endpoints

### Roles
- `GET /api/admin/roles` - Get all roles
- `POST /api/admin/roles` - Create new role
- `PUT /api/admin/roles/:id` - Update role
- `DELETE /api/admin/roles/:id` - Delete role

### Users
- `GET /api/admin/users` - Get all users
- `POST /api/admin/users` - Create new user
- `PUT /api/admin/users/:id` - Update user
- `DELETE /api/admin/users/:id` - Delete user

### Parametric Tables
- `GET /api/admin/parametric-tables` - Get all tables
- `POST /api/admin/parametric-tables` - Create new table
- `PUT /api/admin/parametric-tables/:id` - Update table
- `DELETE /api/admin/parametric-tables/:id` - Delete table

## Default Roles

The system comes with three pre-configured roles:

1. **Admin**: Full system access with all privileges
2. **Operator**: Limited access to orders, customers, and drivers
3. **Dispatcher**: Access to orders and drivers for dispatching

## Troubleshooting

### Common Issues

1. **"Admin access required" error**
   - Ensure the user has the `admin.access` privilege
   - Check if the user's role is properly assigned

2. **Role deletion fails**
   - Verify that no users are assigned to the role
   - Check for foreign key constraints

3. **Parametric table creation fails**
   - Ensure all column names are unique within the table
   - Verify column types are valid

### Database Issues

1. **Missing tables**
   - Run the database setup script
   - Check database connection

2. **Permission errors**
   - Verify database user has CREATE, INSERT, UPDATE, DELETE privileges
   - Check table ownership

## Development Notes

### Adding New Privileges
1. Add the privilege to the `privileges` table
2. Update the `_availablePrivileges` list in `RoleManagementTab`
3. Assign the privilege to appropriate roles

### Extending Parametric Tables
1. Add new column types to the `_columnTypes` list
2. Update the column creation logic in the backend
3. Modify the frontend column rendering as needed

### Custom Validation
1. Add validation rules in the backend routes
2. Implement frontend validation in the form widgets
3. Update error handling and user feedback

## Support

For technical support or feature requests, please contact the development team or create an issue in the project repository.
