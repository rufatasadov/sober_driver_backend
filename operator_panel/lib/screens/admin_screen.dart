import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import '../widgets/admin/role_management_tab.dart';
import '../widgets/admin/user_management_tab.dart';
import '../widgets/admin/parametric_table_tab.dart';
import '../widgets/admin/settings_tab.dart';
import '../widgets/admin/balance_management_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AdminProvider _adminProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _adminProvider = Provider.of<AdminProvider>(context, listen: false);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adminProvider.loadRoles();
      _adminProvider.loadUsers();
      _adminProvider.loadParametricTables();
      _adminProvider.loadSettings();
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
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(
                  icon: Icon(Icons.security),
                  text: 'Role Management',
                ),
                Tab(
                  icon: Icon(Icons.people),
                  text: 'User Management',
                ),
                Tab(
                  icon: Icon(Icons.table_chart),
                  text: 'Parametric Tables',
                ),
                Tab(
                  icon: Icon(Icons.settings),
                  text: 'Parametrlər',
                ),
                Tab(
                  icon: Icon(Icons.account_balance_wallet),
                  text: 'Balans İdarəetmə',
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                RoleManagementTab(),
                UserManagementTab(),
                ParametricTableTab(),
                SettingsTab(),
                BalanceManagementTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
