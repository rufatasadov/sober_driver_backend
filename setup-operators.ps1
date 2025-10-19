# PostgreSQL Service Starter Script
# This script starts PostgreSQL service and runs operator users creation

Write-Host "🚀 AyiqSurucu Operator Users Setup" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

# Check if PostgreSQL service exists
$serviceName = "postgresql-x64-13"
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service) {
    Write-Host "📋 Found PostgreSQL service: $serviceName" -ForegroundColor Yellow
    
    if ($service.Status -eq "Running") {
        Write-Host "✅ PostgreSQL is already running!" -ForegroundColor Green
    } else {
        Write-Host "🔄 Starting PostgreSQL service..." -ForegroundColor Yellow
        Start-Service -Name $serviceName
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ PostgreSQL service started successfully!" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to start PostgreSQL service" -ForegroundColor Red
            Write-Host "🔧 Try running as Administrator" -ForegroundColor Yellow
            exit 1
        }
    }
} else {
    Write-Host "❌ PostgreSQL service not found!" -ForegroundColor Red
    Write-Host "🔧 Available PostgreSQL services:" -ForegroundColor Yellow
    
    $postgresServices = Get-Service | Where-Object { $_.Name -like "*postgres*" }
    if ($postgresServices) {
        $postgresServices | ForEach-Object { Write-Host "   - $($_.Name)" -ForegroundColor Cyan }
    } else {
        Write-Host "   No PostgreSQL services found" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "💡 Please install PostgreSQL or update service name in script" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🎯 Creating operator users..." -ForegroundColor Green
Write-Host ""

# Run the operator users creation script
try {
    node scripts/create-operator-users.js
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Created users:" -ForegroundColor Yellow
        Write-Host "   👑 Admin: admin / admin123" -ForegroundColor Cyan
        Write-Host "   🚗 Dispatcher: dispatcher / dispatcher123" -ForegroundColor Cyan  
        Write-Host "   📞 Operator: operator / operator123" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "⚠️  Remember to change passwords in production!" -ForegroundColor Red
    } else {
        Write-Host "❌ Script execution failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error running script: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
