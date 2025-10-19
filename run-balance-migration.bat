@echo off
echo 🔄 Running balance migration for drivers...
echo.

REM Check if PostgreSQL is running
sc query postgresql-x64-13 >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ PostgreSQL service is not running. Starting it...
    net start postgresql-x64-13
    if %errorlevel% neq 0 (
        echo ❌ Failed to start PostgreSQL service
        pause
        exit /b 1
    )
    echo ✅ PostgreSQL service started successfully
)

echo 📄 Running migration...
node run_balance_migration.js

if %errorlevel% equ 0 (
    echo.
    echo ✅ Migration completed successfully!
    echo 💰 All drivers now have a balance field initialized to 0.00
) else (
    echo.
    echo ❌ Migration failed!
)

echo.
pause
