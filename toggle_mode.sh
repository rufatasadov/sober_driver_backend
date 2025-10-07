#!/bin/bash

# Script to toggle between TEST MODE and PRODUCTION MODE
# Usage: ./toggle_mode.sh test|prod

MODE=$1

if [ "$MODE" = "test" ]; then
    echo "🟡 Enabling TEST MODE..."
    
    # Replace OTP verification with mock
    sed -i '' 's/\/\/ TEMPORARY: Skip OTP verification for testing/\/\/ TEMPORARY: Skip OTP verification for testing/' customer_app/lib/features/auth/presentation/cubit/auth_cubit.dart
    sed -i '' 's/\/\/ Original OTP verification code (commented out for now):/\/\/ Original OTP verification code (commented out for now):/' customer_app/lib/features/auth/presentation/cubit/auth_cubit.dart
    
    echo "✅ TEST MODE enabled - OTP verification bypassed"
    
elif [ "$MODE" = "prod" ]; then
    echo "🟢 Enabling PRODUCTION MODE..."
    
    # Restore original OTP verification
    sed -i '' 's/\/\/ TEMPORARY: Skip OTP verification for testing/\/\/ TEMPORARY: Skip OTP verification for testing/' customer_app/lib/features/auth/presentation/cubit/auth_cubit.dart
    sed -i '' 's/\/\/ Original OTP verification code (commented out for now):/\/\/ Original OTP verification code (commented out for now):/' customer_app/lib/features/auth/presentation/cubit/auth_cubit.dart
    
    echo "✅ PRODUCTION MODE enabled - OTP verification active"
    
else
    echo "❌ Usage: $0 [test|prod]"
    echo "   test  - Enable test mode (skip OTP)"
    echo "   prod  - Enable production mode (real OTP)"
    exit 1
fi

echo "🔄 Run 'flutter pub get' to ensure dependencies are updated"
echo "🚀 Run 'flutter run' to test the app"
