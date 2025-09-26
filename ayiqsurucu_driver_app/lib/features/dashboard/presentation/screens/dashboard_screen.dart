import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/presentation/screens/orders_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          OrdersTabScreen(),
          EarningsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Səhifə'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Sifarişlər',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Qazanc',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xoş gəlmisiniz!', style: AppTheme.heading2),
                      SizedBox(height: 4.h),
                      Text(
                        'Hazır olduğunuzda işə başlaya bilərsiniz',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Profile Avatar
                  CircleAvatar(
                    radius: 25.r,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              // Online/Offline Toggle
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: _isOnline ? AppColors.success : AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isOnline ? AppColors.success : AppColors.border,
                    width: 2.w,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isOnline ? Icons.check_circle : Icons.cancel,
                      size: 60.sp,
                      color:
                          _isOnline
                              ? AppColors.textOnPrimary
                              : AppColors.textSecondary,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      _isOnline ? 'Onlayn' : 'Oflayn',
                      style: AppTheme.heading2.copyWith(
                        color:
                            _isOnline
                                ? AppColors.textOnPrimary
                                : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _isOnline
                          ? 'Yeni sifarişlər alırsınız'
                          : 'İşə başlamaq üçün düyməyə basın',
                      style: AppTheme.bodyMedium.copyWith(
                        color:
                            _isOnline
                                ? AppColors.textOnPrimary
                                : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _toggleOnlineStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isOnline
                                  ? AppColors.textOnPrimary
                                  : AppColors.primary,
                          foregroundColor:
                              _isOnline
                                  ? AppColors.success
                                  : AppColors.textOnPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.w,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _isOnline
                                          ? AppColors.success
                                          : AppColors.textOnPrimary,
                                    ),
                                  ),
                                )
                                : Text(
                                  _isOnline ? 'Oflayn Ol' : 'Onlayn Ol',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Bugünkü Sifarişlər',
                      '12',
                      Icons.assignment,
                      AppColors.info,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildStatCard(
                      'Bugünkü Qazanc',
                      '45.50 ₼',
                      Icons.attach_money,
                      AppColors.success,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Recent Orders
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Son Sifarişlər', style: AppTheme.heading3),
                      SizedBox(height: 16.h),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40.w,
                                    height: 40.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: AppColors.primary,
                                      size: 20.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Müştəri ${index + 1}',
                                          style: AppTheme.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Bakı şəhəri, Nərimanov',
                                          style: AppTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '8.50 ₼',
                                    style: AppTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32.sp),
          SizedBox(height: 8.h),
          Text(value, style: AppTheme.heading3.copyWith(color: color)),
          Text(title, style: AppTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _toggleOnlineStatus() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateDriverStatus(
        isOnline: !_isOnline,
        isAvailable: !_isOnline,
      );

      if (success) {
        setState(() => _isOnline = !_isOnline);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Orders screen with provider
class OrdersTabScreen extends StatelessWidget {
  const OrdersTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrdersProvider(),
      child: const OrdersScreen(),
    );
  }
}

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qazanc'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: const Center(child: Text('Qazanc səhifəsi hazırlanır...')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: const Center(child: Text('Profil səhifəsi hazırlanır...')),
    );
  }
}
