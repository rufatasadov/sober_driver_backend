@echo off
echo Starting PostgreSQL service...
net start postgresql-x64-13
if %errorlevel% equ 0 (
    echo ✅ PostgreSQL service started successfully
    echo.
    echo 🚀 Now you can run the operator users creation script:
    echo    node scripts/create-operator-users.js
    echo.
) else (
    echo ❌ Failed to start PostgreSQL service
    echo.
    echo 🔧 Troubleshooting:
    echo 1. Make sure PostgreSQL is installed
    echo 2. Check if service name is correct
    echo 3. Run as Administrator
    echo.
)
pause
