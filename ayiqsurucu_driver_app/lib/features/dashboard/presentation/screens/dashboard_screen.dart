import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/screens/earnings_screen.dart';
import '../providers/dashboard_provider.dart';

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
          HomeTabScreen(),
          OrdersTabScreen(),
          EarningsTabScreen(),
          ProfileTabScreen(),
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

// Home screen with provider
class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider()..loadDashboardData(),
      child: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<DashboardProvider, AuthProvider>(
        builder: (context, dashboardProvider, authProvider, child) {
          if (dashboardProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = dashboardProvider.stats ?? {};
          final user = authProvider.user;
          final isOnline = stats['isOnline'] ?? false;
          final isAvailable = stats['isAvailable'] ?? false;

          return SafeArea(
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
                          Text(
                            'Xoş gəlmisiniz, ${user?['name']?.split(' ').first ?? 'Sürücü'}!',
                            style: AppTheme.heading2,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            isOnline
                                ? 'Onlayn və hazırsınız'
                                : 'Hazır olduğunuzda işə başlaya bilərsiniz',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      // Profile Avatar
                      GestureDetector(
                        onTap: () {
                          // Navigate to profile tab
                          DefaultTabController.of(context).animateTo(3);
                        },
                        child: CircleAvatar(
                          radius: 25.r,
                          backgroundColor: AppColors.primary,
                          backgroundImage:
                              user?['profileImage'] != null
                                  ? NetworkImage(user!['profileImage'])
                                  : null,
                          child:
                              user?['profileImage'] == null
                                  ? Text(
                                    (user?['name'] ?? 'A')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: AppColors.textOnPrimary,
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : null,
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
                      color: isOnline ? AppColors.success : AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isOnline ? AppColors.success : AppColors.border,
                        width: 2.w,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isOnline ? Icons.check_circle : Icons.cancel,
                          size: 60.sp,
                          color:
                              isOnline
                                  ? AppColors.textOnPrimary
                                  : AppColors.textSecondary,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          isOnline ? 'Onlayn' : 'Oflayn',
                          style: AppTheme.heading2.copyWith(
                            color:
                                isOnline
                                    ? AppColors.textOnPrimary
                                    : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          isOnline
                              ? isAvailable
                                  ? 'Yeni sifarişlər alırsınız'
                                  : 'Onlayn amma məşğulsunuz'
                              : 'İşə başlamaq üçün düyməyə basın',
                          style: AppTheme.bodyMedium.copyWith(
                            color:
                                isOnline
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
                            onPressed:
                                () => _toggleOnlineStatus(
                                  dashboardProvider,
                                  isOnline,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isOnline
                                      ? AppColors.textOnPrimary
                                      : AppColors.primary,
                              foregroundColor:
                                  isOnline
                                      ? AppColors.success
                                      : AppColors.textOnPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child:
                                dashboardProvider.isLoading
                                    ? SizedBox(
                                      width: 20.w,
                                      height: 20.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.w,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              isOnline
                                                  ? AppColors.success
                                                  : AppColors.textOnPrimary,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      isOnline ? 'Oflayn Ol' : 'Onlayn Ol',
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
                          '${stats['todayOrders'] ?? 0}',
                          Icons.assignment,
                          AppColors.info,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildStatCard(
                          'Bugünkü Qazanc',
                          '${(stats['todayEarnings'] ?? 0.0).toStringAsFixed(2)} ₼',
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Son Sifarişlər', style: AppTheme.heading3),
                              IconButton(
                                onPressed: () => dashboardProvider.refresh(),
                                icon: Icon(
                                  Icons.refresh,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Expanded(
                            child:
                                dashboardProvider.recentOrders.isEmpty
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.assignment_outlined,
                                            size: 48.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                          SizedBox(height: 12.h),
                                          Text(
                                            'Hələ sifariş yoxdur',
                                            style: AppTheme.bodyMedium.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            'Onlayn olduqda yeni sifarişlər görünəcək',
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                    : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemCount:
                                          dashboardProvider.recentOrders.length,
                                      itemBuilder: (context, index) {
                                        final order =
                                            dashboardProvider
                                                .recentOrders[index];
                                        return Container(
                                          margin: EdgeInsets.only(bottom: 8.h),
                                          padding: EdgeInsets.all(12.w),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 36.w,
                                                height: 36.w,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        18.r,
                                                      ),
                                                ),
                                                child: Icon(
                                                  Icons.person,
                                                  color: AppColors.primary,
                                                  size: 18.sp,
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Sifariş #${order['orderNumber'] ?? 'N/A'}',
                                                      style: AppTheme.bodyMedium
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    Text(
                                                      '${order['pickup']?['address'] ?? 'Məlumat yoxdur'}',
                                                      style: AppTheme.bodySmall,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '${(order['fare'] ?? 0.0).toStringAsFixed(2)} ₼',
                                                style: AppTheme.bodyMedium
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
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
          );
        },
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

  Future<void> _toggleOnlineStatus(
    DashboardProvider dashboardProvider,
    bool isOnline,
  ) async {
    await dashboardProvider.updateDriverStatus(
      isOnline: !isOnline,
      isAvailable: !isOnline,
    );
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

// Earnings screen with provider
class EarningsTabScreen extends StatelessWidget {
  const EarningsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider(),
      child: const EarningsScreen(),
    );
  }
}

// Profile screen with provider
class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider(),
      child: const ProfileScreen(),
    );
  }
}
