import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/orders_cubit.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize orders cubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ordersCubit = context.read<OrdersCubit>();
      ordersCubit.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sifarişlər'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textOnPrimary,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Gözləyən'),
            Tab(text: 'Aktiv'),
            Tab(text: 'Tamamlanan'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final ordersCubit = context.read<OrdersCubit>();
              ordersCubit.getDriverOrders();
            },
          ),
        ],
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrdersLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                // Pending Orders
                _buildOrdersList(
                  state.pendingOrders,
                  'Gözləyən sifariş yoxdur',
                  true,
                ),

                // Active Orders
                _buildOrdersList(
                  state.activeOrders,
                  'Aktiv sifariş yoxdur',
                  false,
                ),

                // Completed Orders
                _buildOrdersList(
                  state.completedOrders,
                  'Tamamlanan sifariş yoxdur',
                  false,
                ),
              ],
            );
          }

          if (state is OrdersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.sp,
                    color: AppColors.error,
                  ),
                  SizedBox(height: 16.h),
                  Text('Xəta baş verdi', style: AppTheme.heading3),
                  SizedBox(height: 8.h),
                  Text(
                    state.message,
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      context.read<OrdersCubit>().getDriverOrders();
                    },
                    child: const Text('Yenidən cəhd et'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildOrdersList(
    List<Order> orders,
    String emptyMessage,
    bool isPending,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              emptyMessage,
              style: AppTheme.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final ordersCubit = context.read<OrdersCubit>();
        await ordersCubit.getDriverOrders();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, isPending);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order, bool isPending) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToOrderDetails(order),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sifariş #${order.orderNumber}',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: AppTheme.bodySmall.copyWith(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Pickup location
              Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Qalxış: ${order.pickup['address'] ?? 'Məlumat yoxdur'}',
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              // Destination
              Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Məqsəd: ${order.destination['address'] ?? 'Məlumat yoxdur'}',
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.fare.toStringAsFixed(2)} ₼',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),

                  if (isPending) ...[
                    Row(
                      children: [
                        SizedBox(
                          height: 32.h,
                          child: OutlinedButton(
                            onPressed: () => _rejectOrder(order.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(color: AppColors.error),
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                            ),
                            child: Text(
                              'Rədd Et',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        SizedBox(
                          height: 32.h,
                          child: ElevatedButton(
                            onPressed: () => _acceptOrder(order.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.textOnPrimary,
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                            ),
                            child: Text(
                              'Qəbul Et',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      _formatDate(order.createdAt),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.info;
      case 'driver_assigned':
        return AppColors.primary;
      case 'driver_arrived':
        return AppColors.success;
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Gözləyir';
      case 'accepted':
        return 'Qəbul edildi';
      case 'driver_assigned':
        return 'Sürücü təyin edildi';
      case 'driver_arrived':
        return 'Sürücü gəldi';
      case 'in_progress':
        return 'Hərəkətdə';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'Ləğv edildi';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order)),
    );
  }

  Future<void> _acceptOrder(String orderId) async {
    final ordersCubit = context.read<OrdersCubit>();
    final success = await ordersCubit.acceptOrder(orderId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sifariş qəbul edildi'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ordersCubit.error ?? 'Xəta baş verdi'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    final ordersCubit = context.read<OrdersCubit>();
    final success = await ordersCubit.rejectOrder(orderId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sifariş rədd edildi'),
          backgroundColor: AppColors.warning,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ordersCubit.error ?? 'Xəta baş verdi'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
