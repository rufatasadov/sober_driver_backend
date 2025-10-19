import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/screens/earnings_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../orders/presentation/widgets/new_order_notification_widget.dart';
import '../../../orders/presentation/widgets/broadcast_order_notification_widget.dart';
import '../../../orders/presentation/widgets/assigned_order_notification_widget.dart';
import '../../../orders/presentation/screens/order_details_screen.dart';
import '../../../orders/presentation/cubit/orders_cubit.dart';
import '../cubit/dashboard_cubit.dart';
import '../../../../core/services/location_tracking_service.dart';

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
      bottomNavigationBar: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, ordersState) {
          final hasActiveOrder =
              ordersState is OrdersLoaded &&
              ordersState.activeOrders.isNotEmpty;

          return Container(
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
                    _buildBottomNavItem(
                      Icons.home_rounded,
                      'Ana Səhifə',
                      0,
                      hasActiveOrder,
                    ),
                    _buildBottomNavItem(
                      Icons.assignment_rounded,
                      'Sifarişlər',
                      1,
                      hasActiveOrder,
                    ),
                    _buildBottomNavItem(
                      Icons.attach_money_rounded,
                      'Qazanc',
                      2,
                      hasActiveOrder,
                    ),
                    _buildBottomNavItem(
                      Icons.person_rounded,
                      'Profil',
                      3,
                      hasActiveOrder,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    int index,
    bool hasActiveOrder,
  ) {
    final isSelected = _currentIndex == index;
    final isDisabled =
        hasActiveOrder && index != 0; // Only allow home tab when active order

    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => _currentIndex = index),
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
                    isDisabled
                        ? AppColors.textSecondary.withOpacity(0.3)
                        : (isSelected
                            ? AppColors.textOnPrimary
                            : AppColors.textSecondary),
                size: 22.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color:
                    isDisabled
                        ? AppColors.textSecondary.withOpacity(0.3)
                        : (isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary),
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
  Order? _broadcastOrder;
  bool _showBroadcastOrderNotification = false;
  Order? _assignedOrder;
  bool _showAssignedOrderNotification = false;

  @override
  void initState() {
    super.initState();
    // Listen for new orders
    _listenForNewOrders();
    _listenForBroadcastOrders();
    _listenForAssignedOrders();
    // Start location tracking
    _startLocationTracking();
    // Check and auto-set online status
    _checkAutoOnlineStatus();
  }

  void _listenForNewOrders() {
    // Set callback for new order notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ordersCubit = context.read<OrdersCubit>();
      ordersCubit.setNewOrderCallback(_showNewOrder);
    });
  }

  void _listenForBroadcastOrders() {
    // Set callback for broadcast order notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ordersCubit = context.read<OrdersCubit>();
      ordersCubit.setBroadcastOrderCallback(_showBroadcastOrder);
    });
  }

  void _listenForAssignedOrders() {
    // Set callback for assigned order notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ordersCubit = context.read<OrdersCubit>();
      ordersCubit.setOrderAssignedCallback(_showAssignedOrder);
    });
  }

  void _checkAutoOnlineStatus() {
    // Check and auto-set online status after orders are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final ordersCubit = context.read<OrdersCubit>();
        final dashboardCubit = context.read<DashboardCubit>();

        // Wait a bit for orders to load
        await Future.delayed(const Duration(milliseconds: 500));

        // Check and auto-set online status
        await dashboardCubit.checkAndAutoSetOnlineStatus(ordersCubit);
      } catch (e) {
        print('DashboardScreen: Error checking auto-online status: $e');
      }
    });
  }

  Future<void> _startLocationTracking() async {
    try {
      // Check permissions first
      final hasPermission =
          await LocationTrackingService().checkLocationPermissions();
      if (!hasPermission) {
        final granted =
            await LocationTrackingService().requestLocationPermissions();
        if (!granted) {
          print('Location tracking: Permission denied');
          return;
        }
      }

      // Start location tracking service
      await LocationTrackingService().startTracking();
      print('Location tracking: Started successfully');
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  void _showNewOrder(Order order) {
    setState(() {
      _newOrder = order;
      _showNewOrderNotification = true;
    });
  }

  void _showBroadcastOrder(Order order) {
    setState(() {
      _broadcastOrder = order;
      _showBroadcastOrderNotification = true;
    });
  }

  void _dismissNewOrder() {
    setState(() {
      _showNewOrderNotification = false;
      _newOrder = null;
    });
  }

  void _dismissBroadcastOrder() {
    setState(() {
      _showBroadcastOrderNotification = false;
      _broadcastOrder = null;
    });
  }

  void _showAssignedOrder(Order order) {
    setState(() {
      _assignedOrder = order;
      _showAssignedOrderNotification = true;
    });
  }

  void _dismissAssignedOrder() {
    setState(() {
      _showAssignedOrderNotification = false;
      _assignedOrder = null;
    });
  }

  Future<void> _acceptOrder(Order order) async {
    final ordersCubit = context.read<OrdersCubit>();
    final dashboardCubit = context.read<DashboardCubit>();
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
        _dismissBroadcastOrder();
        _dismissAssignedOrder();

        // Check and auto-set online status after accepting order
        await dashboardCubit.checkAndAutoSetOnlineStatus(ordersCubit);
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
    final dashboardCubit = context.read<DashboardCubit>();
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
        _dismissBroadcastOrder();

        // Check and auto-set online status after rejecting order
        await dashboardCubit.checkAndAutoSetOnlineStatus(ordersCubit);
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Ayiq Sürücü',
          style: AppTheme.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Notifications
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                  size: 20.sp,
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.background,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                      // Header without balance
                      SliverToBoxAdapter(
                        child: _buildHeaderSection(
                          user,
                          stats,
                          isOnline,
                          isAvailable,
                        ),
                      ),

                      // Center Circle Status
                      SliverToBoxAdapter(
                        child: _buildCenterStatusCircle(state, isOnline),
                      ),

                      // Stats section
                      //     SliverToBoxAdapter(child: _buildStatsSection(stats)),

                      // Spacer to push balance to bottom
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          children: [
                            const Spacer(),
                            // Balance section at bottom
                            _buildBalanceSection(stats),
                            SizedBox(height: 12.h), // Small gap before nav
                          ],
                        ),
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

              // Broadcast Order Notification Overlay
              if (_showBroadcastOrderNotification && _broadcastOrder != null)
                Positioned(
                  top: _showNewOrderNotification ? 200.h : 0,
                  left: 0,
                  right: 0,
                  child: BroadcastOrderNotificationWidget(
                    order: _broadcastOrder!,
                    onAccept: () => _acceptOrder(_broadcastOrder!),
                    onReject: () => _rejectOrder(_broadcastOrder!),
                    onDismiss: _dismissBroadcastOrder,
                  ),
                ),

              // Assigned Order Notification Overlay
              if (_showAssignedOrderNotification && _assignedOrder != null)
                Positioned(
                  top:
                      (_showNewOrderNotification ? 200.h : 0) +
                      (_showBroadcastOrderNotification ? 200.h : 0),
                  left: 0,
                  right: 0,
                  child: AssignedOrderNotificationWidget(
                    order: _assignedOrder!,
                    onAccept: () => _acceptOrder(_assignedOrder!),
                    onReject: () => _rejectOrder(_assignedOrder!),
                    onDismiss: _dismissAssignedOrder,
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
          // Welcome Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Provider.of<LanguageProvider>(context)
                          .getString('welcomeDriver')
                          .replaceAll(
                            '{name}',
                            user?['name'] ??
                                Provider.of<LanguageProvider>(
                                  context,
                                ).getString('driver'),
                          ),
                      style: AppTheme.heading2.copyWith(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      isOnline
                          ? Provider.of<LanguageProvider>(
                            context,
                          ).getString('onlineReady')
                          : Provider.of<LanguageProvider>(
                            context,
                          ).getString('readyToStart'),
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
                      // Find the parent DashboardScreen and update its index
                      final dashboardState =
                          context
                              .findAncestorStateOfType<_DashboardScreenState>();
                      if (dashboardState != null) {
                        dashboardState.setState(() {
                          dashboardState._currentIndex = 3;
                        });
                      }
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
        ],
      ),
    );
  }

  Widget _buildCenterStatusCircle(DashboardState state, bool isOnline) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: Column(
        children: [
          // Dynamic Container - Circle or Rectangle based on active orders
          BlocBuilder<OrdersCubit, OrdersState>(
            builder: (context, ordersState) {
              final hasActiveOrder =
                  ordersState is OrdersLoaded &&
                  ordersState.activeOrders.isNotEmpty;

              if (hasActiveOrder) {
                // Rounded Rectangle for Active Order
                final activeOrder = ordersState.activeOrders.first;
                return Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: 200.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.primary, width: 3.w),
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildActiveOrderInRectangle(activeOrder),
                );
              } else {
                // Circle for No Active Order
                return Container(
                  width: 300.w,
                  height: 300.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isOnline
                              ? AppColors.success
                              : AppColors.textSecondary,
                      width: 4.w,
                    ),
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: (isOnline
                                ? AppColors.success
                                : AppColors.textSecondary)
                            .withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildStatusInCircle(isOnline),
                );
              }
            },
          ),

          SizedBox(height: 16.h),

          // Toggle Button
          BlocBuilder<OrdersCubit, OrdersState>(
            builder: (context, ordersState) {
              final hasActiveOrder =
                  ordersState is OrdersLoaded &&
                  ordersState.activeOrders.isNotEmpty;

              // Hide toggle button when there's an active order
              if (hasActiveOrder) {
                return const SizedBox.shrink();
              }

              return SizedBox(
                width: 80.w,
                height: 32.h,
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
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: isOnline ? 0 : 2,
                    padding: EdgeInsets.zero,
                  ),
                  child: BlocBuilder<DashboardCubit, DashboardState>(
                    builder: (context, state) {
                      final isLoading = state is DashboardLoading;

                      if (isLoading) {
                        return SizedBox(
                          width: 16.w,
                          height: 16.h,
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

                      return Icon(
                        isOnline
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 16.sp,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderInRectangle(Order order) {
    return AnimatedBorderContainer(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Header with order info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.local_shipping,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aktiv Sifariş',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                        Text(
                          'Sifariş #${order.orderNumber.toString().substring(order.orderNumber.toString().length - 4)}',
                          style: AppTheme.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 18.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Son status: ${_getElapsedTimeSinceLastUpdate(order)}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 100.w,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _getStatusColor(order.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: AppTheme.caption.copyWith(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Customer info
            if (order.customer != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        order.customer!['name'] ?? 'Müştəri',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                    if (order.customerPhone != null) ...[
                      SizedBox(width: 12.w),
                      GestureDetector(
                        onTap: () => _makePhoneCall(order.customerPhone!),
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.phone,
                            color: AppColors.success,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // Addresses
            Row(
              children: [
                // Pickup address
                Expanded(
                  child: GestureDetector(
                    onTap:
                        () => _shareLocation(order.pickup, 'Götürmə nöqtəsi'),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.my_location,
                                color: AppColors.success,
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Götürmə',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            order.pickup['address'] ?? 'Ünvan yoxdur',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Destination address
                Expanded(
                  child: GestureDetector(
                    onTap:
                        () =>
                            _shareLocation(order.destination, 'Təhvil nöqtəsi'),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Təhvil',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            order.destination['address'] ?? 'Ünvan yoxdur',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  flex: 1, // Make details button smaller
                  child: OutlinedButton.icon(
                    onPressed: () => _viewOrderDetails(order),
                    icon: Icon(Icons.visibility, size: 16.sp),
                    label: Text(
                      'Ətraflı',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: BorderSide(color: AppColors.info),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 12.w,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  flex: 2, // Make status button wider
                  child: ElevatedButton.icon(
                    onPressed:
                        () => _quickUpdateStatus(
                          order,
                          _getNextStatus(order.status),
                        ),
                    icon: Icon(_getNextStatusIcon(order.status), size: 18.sp),
                    label: Text(
                      _getNextStatusText(order.status),
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: AppTheme.textOnPrimaryColor,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getNextStatusColor(order.status),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 16.w,
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderInCircle(Order order) {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Order icon and number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_shipping,
                  color: AppColors.primary,
                  size: 12.sp,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                '#${order.orderNumber.toString().substring(order.orderNumber.toString().length - 4)}',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Customer info
          if (order.customer != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, color: AppColors.textSecondary, size: 12.sp),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    order.customer!['name'] ?? 'Müştəri',
                    style: AppTheme.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (order.customerPhone != null) ...[
                  SizedBox(width: 4.w),
                  GestureDetector(
                    onTap: () => _makePhoneCall(order.customerPhone!),
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Icon(
                        Icons.phone,
                        color: AppColors.success,
                        size: 10.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 6.h),
          ],

          // Pickup address
          GestureDetector(
            onTap: () => _shareLocation(order.pickup, 'Götürmə nöqtəsi'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.my_location,
                    color: AppColors.success,
                    size: 10.sp,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      order.pickup['address'] ?? 'Ünvan yoxdur',
                      style: AppTheme.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 9.sp,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 4.h),

          // Destination address
          GestureDetector(
            onTap: () => _shareLocation(order.destination, 'Təhvil nöqtəsi'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 10.sp,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      order.destination['address'] ?? 'Ünvan yoxdur',
                      style: AppTheme.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 9.sp,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 6.h),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () => _viewOrderDetails(order),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Icon(
                    Icons.visibility,
                    color: AppColors.info,
                    size: 10.sp,
                  ),
                ),
              ),
              GestureDetector(
                onTap:
                    () =>
                        _quickUpdateStatus(order, _getNextStatus(order.status)),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Icon(
                    Icons.check,
                    color: AppColors.success,
                    size: 10.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInCircle(bool isOnline) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Status icon
        Container(
          width: 60.w,
          height: 60.h,
          decoration: BoxDecoration(
            color: (isOnline ? AppColors.success : AppColors.textSecondary)
                .withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOnline
                ? Icons.check_circle_rounded
                : Icons.pause_circle_outline_rounded,
            size: 32.sp,
            color: isOnline ? AppColors.success : AppColors.textSecondary,
          ),
        ),

        SizedBox(height: 12.h),

        // Status text
        Text(
          isOnline ? 'Onlayn' : 'Oflayn',
          style: AppTheme.heading3.copyWith(
            color: isOnline ? AppColors.success : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 4.h),

        // Status description
        Text(
          isOnline
              ? 'Yeni sifarişlər alırsınız'
              : 'İşə başlamaq üçün düyməyə basın',
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
      case 'driver_assigned':
        return AppColors.info;
      case 'driver_arrived':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Qəbul Edildi';
      case 'driver_assigned':
        return 'Sürücü Təyin Edildi';
      case 'driver_arrived':
        return 'Çatdı';
      case 'in_progress':
        return 'Gedişdə';
      default:
        return status;
    }
  }

  String _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'accepted':
      case 'driver_assigned':
        return 'driver_arrived';
      case 'driver_arrived':
        return 'in_progress';
      case 'in_progress':
        return 'completed';
      default:
        return currentStatus;
    }
  }

  String _getNextStatusText(String currentStatus) {
    final nextStatus = _getNextStatus(currentStatus);
    switch (nextStatus) {
      case 'driver_arrived':
        return 'Çatdı';
      case 'in_progress':
        return 'Gedişdə';
      case 'completed':
        return 'Tamamlandı';
      default:
        return nextStatus;
    }
  }

  IconData _getNextStatusIcon(String currentStatus) {
    final nextStatus = _getNextStatus(currentStatus);
    switch (nextStatus) {
      case 'driver_arrived':
        return Icons.location_on;
      case 'in_progress':
        return Icons.directions_car;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.check;
    }
  }

  Color _getNextStatusColor(String currentStatus) {
    final nextStatus = _getNextStatus(currentStatus);
    switch (nextStatus) {
      case 'driver_arrived':
        return const Color(0xFF4CAF50); // Green - arrived
      case 'in_progress':
        return const Color(0xFF2196F3); // Blue - in progress
      case 'completed':
        return const Color(0xFF8BC34A); // Light green - completed
      default:
        return AppColors.success;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Telefon zəngi başlatmaq mümkün olmadı'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('Phone call error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Telefon zəngi xətası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareLocation(
    Map<String, dynamic> location,
    String label,
  ) async {
    try {
      final address = location['address'] ?? 'Ünvan yoxdur';
      final coordinates = location['location']?['coordinates'];

      if (coordinates != null &&
          coordinates is List &&
          coordinates.length >= 2) {
        final lat = coordinates[1];
        final lng = coordinates[0];

        // Create location sharing text
        final locationText = '$label: $address\nKoordinatlar: $lat, $lng';

        // Try to open with Google Maps first
        final googleMapsUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        );

        if (await canLaunchUrl(googleMapsUri)) {
          await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback to sharing text
          await _shareText(locationText);
        }
      } else {
        // If no coordinates, just share the address
        await _shareText('$label: $address');
      }
    } catch (e) {
      print('Location sharing error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ünvan paylaşma xətası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareText(String text) async {
    try {
      // Copy to clipboard as fallback
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LanguageProvider>(context).getString('addressCopied'),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Text sharing error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${Provider.of<LanguageProvider>(context).getString('textShareError')}: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildStatsSection(Map<dynamic, dynamic> stats) {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Provider.of<LanguageProvider>(context).getString('todayStats'),
            style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  Provider.of<LanguageProvider>(context).getString('orders'),
                  '${stats['todayOrders'] ?? 0}',
                  Icons.assignment_rounded,
                  AppColors.info,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildModernStatCard(
                  Provider.of<LanguageProvider>(context).getString('earnings'),
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

    // If going offline, check for active orders first
    if (isOnline) {
      // Check if there are active orders
      final ordersState = context.read<OrdersCubit>().state;
      final hasActiveOrder =
          ordersState is OrdersLoaded && ordersState.activeOrders.isNotEmpty;

      if (hasActiveOrder) {
        // Show error message - cannot go offline with active order
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Aktiv sifarişiniz olduğu üçün oflayn ola bilməzsiniz ❌',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // If no active orders, show confirmation dialog
      final confirmed = await _showOfflineConfirmationDialog();
      if (!confirmed) return;
    }

    final success = await dashboardCubit.updateDriverStatus(
      isOnline: !isOnline,
      isAvailable: !isOnline,
    );

    if (mounted) {
      if (success) {
        print('UI: Status update successful');

        // Manage location tracking based on online status
        if (!isOnline) {
          // Going online - start location tracking
          await LocationTrackingService().startTracking();
        } else {
          // Going offline - stop location tracking
          LocationTrackingService().stopTracking();
        }

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

  Future<bool> _showOfflineConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Text(
                'Oflayn Olmaq',
                style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Oflayn olmaq istədiyinizdən əminsiniz? Yeni sifarişlər almayacaqsınız.',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Ləğv Et',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Oflayn Ol',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _viewOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BlocProvider.value(
              value: context.read<OrdersCubit>(),
              child: OrderDetailsScreen(order: order),
            ),
      ),
    );
  }

  Future<void> _quickUpdateStatus(Order order, String status) async {
    final ordersCubit = context.read<OrdersCubit>();
    final dashboardCubit = context.read<DashboardCubit>();
    final success = await ordersCubit.updateOrderStatus(
      orderId: order.id,
      status: status,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Status uğurla yeniləndi ✅' : 'Status yenilənmədi ❌',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );

      // Check and auto-set online status after updating order status
      if (success) {
        await dashboardCubit.checkAndAutoSetOnlineStatus(ordersCubit);
      }
    }
  }

  Widget _buildBalanceSection(Map<dynamic, dynamic> stats) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 0),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.primary.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.primary,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        Provider.of<LanguageProvider>(
                          context,
                        ).getString('balance'),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '${stats['balance']?.toStringAsFixed(2) ?? '0.00'} ₼',
                    style: AppTheme.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${Provider.of<LanguageProvider>(context).getString('today')}: ${(stats['todayEarnings'] ?? 0.0).toStringAsFixed(2)} ₼',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.trending_up_rounded,
                color: AppColors.primary,
                size: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getElapsedTimeSinceLastUpdate(Order order) {
    final now = DateTime.now();
    // Use updatedAt if available (last status update), otherwise use createdAt
    final referenceTime = order.updatedAt ?? order.createdAt;
    final difference = now.difference(referenceTime);

    if (difference.inMinutes < 1) {
      return 'İndi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dəqiqə əvvəl';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat əvvəl';
    } else {
      return '${difference.inDays} gün əvvəl';
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

// Animated border container for active orders
class AnimatedBorderContainer extends StatefulWidget {
  final Widget child;

  const AnimatedBorderContainer({super.key, required this.child});

  @override
  State<AnimatedBorderContainer> createState() =>
      _AnimatedBorderContainerState();
}

class _AnimatedBorderContainerState extends State<AnimatedBorderContainer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Subtle breathing effect
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Gentle opacity pulse
    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 200.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: AppColors.surface,
              border: Border.all(
                color: AppColors.primary.withOpacity(_opacityAnimation.value),
                width: 2.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(
                    _opacityAnimation.value * 0.3,
                  ),
                  blurRadius: 15 + (_opacityAnimation.value * 10),
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
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
