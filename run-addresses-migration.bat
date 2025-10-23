@echo off
echo Starting addresses table migration...
echo.

REM Set environment variables
set DATABASE_URL=postgresql://postgres:password@localhost:5432/ayiqsurucu
set PORT=14122
set NODE_ENV=development
set JWT_SECRET=test-secret

echo Environment variables set:
echo DATABASE_URL=%DATABASE_URL%
echo PORT=%PORT%
echo NODE_ENV=%NODE_ENV%
echo.

echo Running addresses migration...
node run_addresses_migration.js

echo.
echo Migration completed!
pause
