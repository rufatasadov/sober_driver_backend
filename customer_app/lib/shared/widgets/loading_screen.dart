import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class LoadingScreen extends StatelessWidget {
  final String? message;

  const LoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Icon(Icons.local_taxi, size: 80.sp, color: Colors.white),
            SizedBox(height: 24.h),

            // App Name
            Text(
              'Peregon hayda',
              style: AppTheme.headlineLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),

            Text(
              'Customer App',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
            ),
            SizedBox(height: 40.h),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
            SizedBox(height: 24.h),

            // Loading Message
            if (message != null) ...[
              Text(
                message!,
                style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                'Yüklənir...',
                style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
