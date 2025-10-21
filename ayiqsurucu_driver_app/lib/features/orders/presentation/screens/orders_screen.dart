import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/animated_order_card.dart';
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
          final ordersCubit = context.read<OrdersCubit>();
          final isUpdating =
              ordersCubit.state is OrdersLoaded &&
              (ordersCubit.state as OrdersLoaded).updatingOrderId == order.id;
          final updatingStatus =
              ordersCubit.state is OrdersLoaded
                  ? (ordersCubit.state as OrdersLoaded).updatingStatus
                  : null;

          return AnimatedOrderCard(
            order: order,
            isUpdating: isUpdating,
            updatingStatus: updatingStatus,
            onTap: () => _navigateToOrderDetails(order),
            actions: isPending ? _buildOrderActions(order) : null,
          );
        },
      ),
    );
  }

  List<Widget> _buildOrderActions(Order order) {
    return [
      ElevatedButton(
        onPressed: () => _acceptOrder(order.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text('Qəbul et'),
      ),
      SizedBox(width: 8.w),
      ElevatedButton(
        onPressed: () => _rejectOrder(order.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text('Rədd et'),
      ),
    ];
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
