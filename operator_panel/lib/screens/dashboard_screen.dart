import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/recent_orders_list.dart';
import 'orders_screen.dart';
import 'customers_screen.dart';
import 'drivers_screen.dart';
import 'drivers/drivers_map_screen.dart';
import 'admin_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 1;

  final List<Widget> _screens = [
    const DashboardContent(),
    const OrdersScreen(),
    const CustomersScreen(),
    const DriversScreen(),
    const DriversMapScreen(),
    const AdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayiq Sürücü - Operator Panel'),
        actions: [
          // Notifications
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          const SizedBox(width: 8),
          // Profile menu
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    authProvider.logout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Text(authProvider.user?['name'] ?? 'Operator'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: AppSizes.paddingSmall),
                        Text(AppStrings.logout),
                      ],
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(AppSizes.paddingSmall),
                  child: Icon(Icons.account_circle),
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: AppColors.surface,
            child: Column(
              children: [
                const SizedBox(height: AppSizes.padding),
                _buildNavItem(
                  icon: Icons.dashboard,
                  title: AppStrings.dashboard,
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.local_shipping,
                  title: AppStrings.orders,
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.people,
                  title: AppStrings.customers,
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.drive_eta,
                  title: AppStrings.drivers,
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.map,
                  title: 'Sürücü Xəritəsi',
                  index: 4,
                ),
                _buildNavItem(
                  icon: Icons.admin_panel_settings,
                  title: 'Admin Panel',
                  index: 5,
                ),
                const Spacer(),
                const Divider(),
                _buildNavItem(
                  icon: Icons.settings,
                  title: AppStrings.settings,
                  index: 5,
                ),
                const SizedBox(height: AppSizes.padding),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.padding,
        vertical: AppSizes.paddingSmall,
      ),
      child: Material(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(AppSizes.radius),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: AppSizes.iconSize,
                ),
                const SizedBox(width: AppSizes.padding),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive grid columns based on screen width
            final screenWidth = constraints.maxWidth;
            int crossAxisCount = 4;
            double childAspectRatio = 2.0; // Adjusted for fixed height

            if (screenWidth < 1200) {
              crossAxisCount = 3;
              childAspectRatio = 1.8;
            }
            if (screenWidth < 900) {
              crossAxisCount = 2;
              childAspectRatio = 1.6;
            }
            if (screenWidth < 600) {
              crossAxisCount = 1;
              childAspectRatio = 1.4;
            }
            if (screenWidth < 400) {
              crossAxisCount = 1;
              childAspectRatio = 1.2;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlıq
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),

                  // Statistika kartları
                  SizedBox(
                    height: 200, // Fixed height for statistics cards
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSizes.padding,
                      mainAxisSpacing: AppSizes.padding,
                      childAspectRatio: childAspectRatio,
                      children: [
                        DashboardCard(
                          title: AppStrings.todayOrders,
                          value:
                              orderProvider.stats['todayOrders']?.toString() ??
                                  '0',
                          icon: Icons.local_shipping,
                          color: AppColors.primary,
                        ),
                        DashboardCard(
                          title: AppStrings.completedOrders,
                          value: orderProvider.stats['todayCompleted']
                                  ?.toString() ??
                              '0',
                          icon: Icons.check_circle,
                          color: AppColors.success,
                        ),
                        DashboardCard(
                          title: AppStrings.pendingOrders,
                          value:
                              orderProvider.stats['todayPending']?.toString() ??
                                  '0',
                          icon: Icons.pending,
                          color: AppColors.warning,
                        ),
                        DashboardCard(
                          title: AppStrings.onlineDrivers,
                          value: orderProvider.stats['onlineDrivers']
                                  ?.toString() ??
                              '0',
                          icon: Icons.drive_eta,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingLarge),

                  // Son sifarişlər
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Son sifarişlər',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Orders səhifəsinə keç
                        },
                        child: Text(
                          'Hamısına bax',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.padding),

                  // Son sifarişlər siyahısı
                  SizedBox(
                    height: 300, // Fixed height for recent orders
                    child: RecentOrdersList(orders: orderProvider.recentOrders),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
