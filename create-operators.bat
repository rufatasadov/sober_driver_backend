@echo off
echo 🚀 Creating Operator Users for AyiqSurucu System
echo ================================================
echo.

echo 📋 This script will create 3 users:
echo    - Admin (admin/admin123)
echo    - Dispatcher (dispatcher/dispatcher123)  
echo    - Operator (operator/operator123)
echo.

set /p confirm="Do you want to continue? (y/n): "
if /i "%confirm%" neq "y" (
    echo Operation cancelled.
    pause
    exit /b
)

echo.
echo 🔄 Running user creation script...
node scripts/create-operator-users.js

echo.
echo ✅ Script completed!
echo.
echo 📝 Next steps:
echo 1. Test login with created users
echo 2. Change default passwords
echo 3. Configure permissions
echo.
pause
