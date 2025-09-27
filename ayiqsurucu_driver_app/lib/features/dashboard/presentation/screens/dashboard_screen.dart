import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/screens/earnings_screen.dart';
import '../../../orders/presentation/screens/order_history_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../orders/presentation/widgets/new_order_notification_widget.dart';
import '../../../orders/presentation/cubit/orders_cubit.dart';
import '../cubit/dashboard_cubit.dart';

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(Icons.home_rounded, 'Ana Səhifə', 0),
                _buildBottomNavItem(Icons.assignment_rounded, 'Sifarişlər', 1),
                _buildBottomNavItem(Icons.attach_money_rounded, 'Qazanc', 2),
                _buildBottomNavItem(Icons.person_rounded, 'Profil', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color:
                    isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
                size: 22.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Home screen with cubit
class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Load dashboard data when screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardCubit>().loadDashboardData();
    });

    return const HomeScreen();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Order? _newOrder;
  bool _showNewOrderNotification = false;

  @override
  void initState() {
    super.initState();
    // Listen for new orders
    _listenForNewOrders();
  }

  void _listenForNewOrders() {
    // Set callback for new order notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ordersCubit = context.read<OrdersCubit>();
      ordersCubit.setNewOrderCallback(_showNewOrder);
    });
  }

  void _showNewOrder(Order order) {
    setState(() {
      _newOrder = order;
      _showNewOrderNotification = true;
    });
  }

  void _dismissNewOrder() {
    setState(() {
      _showNewOrderNotification = false;
      _newOrder = null;
    });
  }

  Future<void> _acceptOrder(Order order) async {
    final ordersCubit = context.read<OrdersCubit>();
    final success = await ordersCubit.acceptOrder(order.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sifariş qəbul edildi ✅'),
            backgroundColor: AppColors.success,
          ),
        );
        _dismissNewOrder();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sifariş qəbul edilmədi ❌'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(Order order) async {
    final ordersCubit = context.read<OrdersCubit>();
    final success = await ordersCubit.rejectOrder(order.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sifariş rədd edildi'),
            backgroundColor: AppColors.warning,
          ),
        );
        _dismissNewOrder();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sifariş rədd edilmədi ❌'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return _buildLoadingState();
          }

          final stats = state is DashboardLoaded ? state.stats : {};
          final user = context.read<AuthCubit>().user;
          final isOnline = stats['isOnline'] ?? false;
          final isAvailable = stats['isAvailable'] ?? false;

          print(
            'UI: Current state - isOnline: $isOnline, isAvailable: $isAvailable',
          );

          return Stack(
            children: [
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await context.read<DashboardCubit>().refresh();
                  },
                  child: CustomScrollView(
                    slivers: [
                      // Header with balance
                      SliverToBoxAdapter(
                        child: _buildHeaderSection(
                          user,
                          stats,
                          isOnline,
                          isAvailable,
                        ),
                      ),

                      // Quick actions grid
                      SliverToBoxAdapter(child: _buildQuickActionsSection()),

                      // Stats section
                      SliverToBoxAdapter(child: _buildStatsSection(stats)),

                      // Recent orders section
                      SliverToBoxAdapter(
                        child: _buildRecentOrdersSection(state),
                      ),

                      // Bottom padding
                      SliverToBoxAdapter(
                        child: SizedBox(height: 100.h), // Space for bottom nav
                      ),
                    ],
                  ),
                ),
              ),

              // New Order Notification Overlay
              if (_showNewOrderNotification && _newOrder != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: NewOrderNotificationWidget(
                    order: _newOrder!,
                    onAccept: () => _acceptOrder(_newOrder!),
                    onReject: () => _rejectOrder(_newOrder!),
                    onDismiss: _dismissNewOrder,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16.h),
            Text(
              'Məlumatlar yüklənir...',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    Map<String, dynamic>? user,
    Map<dynamic, dynamic> stats,
    bool isOnline,
    bool isAvailable,
  ) {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balansınız',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.textOnPrimary.withOpacity(0.9),
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${stats['totalEarnings']?.toStringAsFixed(2) ?? '0.00'} AZN',
                          style: AppTheme.heading1.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 28.sp,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.textOnPrimary,
                        size: 28.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: AppColors.textOnPrimary,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Bugün: ${(stats['todayEarnings'] ?? 0.0).toStringAsFixed(2)} AZN',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Welcome Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salam, ${user?['name']?.split(' ').first ?? 'Sürücü'}! 👋',
                      style: AppTheme.heading2.copyWith(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
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
              ),
              // Profile Avatar with notification badge
              Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate to profile tab
                      DefaultTabController.of(context).animateTo(3);
                    },
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28.r,
                        backgroundColor: AppColors.surface,
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
                                    color: AppColors.primary,
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : null,
                      ),
                    ),
                  ),
                  // Online indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color:
                            isOnline
                                ? AppColors.success
                                : AppColors.textSecondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 2.w,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Online/Offline Status Card
          _buildOnlineStatusCard(isOnline, isAvailable),
        ],
      ),
    );
  }

  Widget _buildOnlineStatusCard(bool isOnline, bool isAvailable) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isOnline
                  ? [AppColors.success, AppColors.success.withOpacity(0.8)]
                  : [AppColors.surface, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isOnline ? AppColors.success : AppColors.border,
          width: 2.w,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isOnline
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Icon with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 70.w,
            height: 70.h,
            decoration: BoxDecoration(
              color:
                  isOnline
                      ? AppColors.textOnPrimary.withOpacity(0.2)
                      : AppColors.textSecondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline
                  ? Icons.check_circle_rounded
                  : Icons.pause_circle_outline_rounded,
              size: 40.sp,
              color:
                  isOnline ? AppColors.textOnPrimary : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            isOnline ? 'Onlayn' : 'Oflayn',
            style: AppTheme.heading2.copyWith(
              color: isOnline ? AppColors.textOnPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            isOnline
                ? isAvailable
                    ? 'Yeni sifarişlər alırsınız 🚗'
                    : 'Onlayn amma məşğulsunuz ⏸️'
                : 'İşə başlamaq üçün düyməyə basın ▶️',
            style: AppTheme.bodyMedium.copyWith(
              color:
                  isOnline ? AppColors.textOnPrimary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed:
                  () => _toggleOnlineStatus(
                    context.read<DashboardCubit>(),
                    isOnline,
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isOnline ? AppColors.textOnPrimary : AppColors.primary,
                foregroundColor:
                    isOnline ? AppColors.success : AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: isOnline ? 0 : 2,
              ),
              child: BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) {
                  final isLoading = state is DashboardLoading;

                  if (isLoading) {
                    return SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOnline
                              ? AppColors.success
                              : AppColors.textOnPrimary,
                        ),
                      ),
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isOnline
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        isOnline ? 'Oflayn Ol' : 'Onlayn Ol',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sürətli Əməliyyatlar',
            style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildModernActionCard(
                  'Sifariş Tarixçəsi',
                  Icons.history_rounded,
                  AppColors.info,
                  'Keçmiş sifarişlərinizi görün',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildModernActionCard(
                  'Gəlir Hesabatı',
                  Icons.analytics_rounded,
                  AppColors.success,
                  'Qazanclarınızı analiz edin',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EarningsTabScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildModernActionCard(
            'Bildirişlər',
            Icons.notifications_active_rounded,
            AppColors.warning,
            'Admin və dispatcher mesajları',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<dynamic, dynamic> stats) {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bugünkü Statistikalar',
            style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  'Sifarişlər',
                  '${stats['todayOrders'] ?? 0}',
                  Icons.assignment_rounded,
                  AppColors.info,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildModernStatCard(
                  'Qazanc',
                  '${(stats['todayEarnings'] ?? 0.0).toStringAsFixed(2)} ₼',
                  Icons.trending_up_rounded,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(DashboardState state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son Sifarişlər',
                style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => context.read<DashboardCubit>().refresh(),
                icon: Icon(Icons.refresh_rounded, size: 16.sp),
                label: Text('Yenilə'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            constraints: BoxConstraints(maxHeight: 280.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                (state is DashboardLoaded ? state.recentOrders : []).isEmpty
                    ? _buildEmptyOrdersWidget()
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          (state is DashboardLoaded ? state.recentOrders : [])
                              .length,
                      itemBuilder: (context, index) {
                        final order =
                            (state is DashboardLoaded
                                ? state.recentOrders
                                : [])[index];
                        return _buildModernOrderCard(order);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersWidget() {
    return Container(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64.sp,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'Hələ sifariş yoxdur',
            style: AppTheme.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Yeni sifarişlər burada görünəcək',
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: EdgeInsets.all(8.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.local_taxi_rounded,
              color: AppColors.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sifariş #${order['orderNumber'] ?? 'N/A'}',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${order['pickup']?['address'] ?? 'Məlumat yoxdur'}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '${(order['fare'] ?? 0.0).toStringAsFixed(2)} ₼',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.2), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(color: color.withOpacity(0.7)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            value,
            style: AppTheme.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleOnlineStatus(
    DashboardCubit dashboardCubit,
    bool isOnline,
  ) async {
    print('UI: Toggling online status from $isOnline to ${!isOnline}');
    final success = await dashboardCubit.updateDriverStatus(
      isOnline: !isOnline,
      isAvailable: !isOnline,
    );

    if (mounted) {
      if (success) {
        print('UI: Status update successful');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!isOnline ? 'Onlayn oldunuz ✅' : 'Oflayn oldunuz ⏸️'),
            backgroundColor: !isOnline ? AppColors.success : AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print('UI: Status update failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status yeniləməkdə xəta baş verdi ❌'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

// Orders screen with cubit
class OrdersTabScreen extends StatelessWidget {
  const OrdersTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrdersScreen();
  }
}

// Earnings screen with cubit
class EarningsTabScreen extends StatelessWidget {
  const EarningsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EarningsScreen();
  }
}

// Profile screen with cubit
class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
