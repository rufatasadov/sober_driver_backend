import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/syncfusion_customers_datagrid.dart';
import 'package:intl/intl.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.customers,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                CustomButton(
                  onPressed: () => _showAddCustomerDialog(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add),
                      const SizedBox(width: AppSizes.paddingSmall),
                      Text(AppStrings.addCustomer),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingLarge),

            // Search
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: CustomTextField(
                  controller: _searchController,
                  hintText: AppStrings.searchCustomers,
                  prefixIconData: Icons.search,
                  onChanged: (value) {
                    Provider.of<OrderProvider>(context, listen: false)
                        .searchCustomers(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLarge),

            // Customers Table
            Expanded(
              child: Consumer<OrderProvider>(
                builder: (context, orderProvider, child) {
                  if (orderProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (orderProvider.customers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSizes.padding),
                          Text(
                            AppStrings.noCustomers,
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SyncfusionCustomersDataGrid(
                    customers: orderProvider.customers,
                    onCustomerTap: _showCustomerDetails,
                    onEditCustomer: _editCustomer,
                    onDeleteCustomer: _deleteCustomer,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddCustomerDialog(),
    );
  }

  void _showCustomerDetails(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerDetailsDialog(customer: customer),
    );
  }

  void _editCustomer(Map<String, dynamic> customer) {
    // TODO: Implement edit customer functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redaktə funksiyası tezliklə əlavə ediləcək'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _deleteCustomer(Map<String, dynamic> customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Müştərini sil'),
        content: Text('Bu müştərini silmək istədiyinizə əminsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Ləğv et'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Bəli, sil'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);
        await orderProvider.deleteCustomer(customer['_id']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Müştəri uğurla silindi'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.addCustomer),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: AppStrings.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.padding),
              CustomTextField(
                controller: _phoneController,
                labelText: AppStrings.phone,
                hintText: '+994501234567',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.padding),
              CustomTextField(
                controller: _emailController,
                labelText: AppStrings.email,
                hintText: 'example@email.com',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        CustomButton(
          onPressed: _submitCustomer,
          child: Text(AppStrings.add),
        ),
      ],
    );
  }

  void _submitCustomer() async {
    if (_formKey.currentState!.validate()) {
      try {
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);
        await orderProvider.createCustomer({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        });

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Müştəri uğurla əlavə edildi'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class CustomerDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailsDialog({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailsDialog> createState() => _CustomerDetailsDialogState();
}

class _CustomerDetailsDialogState extends State<CustomerDetailsDialog> {
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic> _orderStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      final ordersData =
          await orderProvider.getCustomerOrders(widget.customer['id']);
      final stats =
          await orderProvider.getCustomerOrderCount(widget.customer['id']);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(ordersData['orders'] ?? []);
        _orderStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Müştəri Detalları',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingLarge),

            // Customer Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Müştəri Məlumatları',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSizes.padding),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                              'Ad', widget.customer['name'] ?? ''),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                              'Telefon', widget.customer['phone'] ?? ''),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                              'Email', widget.customer['email'] ?? ''),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.padding),

            // Order Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sifariş Statistika',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSizes.padding),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Ümumi Sifariş',
                            _orderStats['totalOrders']?.toString() ?? '0',
                            Icons.shopping_cart,
                            AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Tamamlanmış',
                            _orderStats['completedOrders']?.toString() ?? '0',
                            Icons.check_circle,
                            AppColors.success,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Ləğv Edilmiş',
                            _orderStats['cancelledOrders']?.toString() ?? '0',
                            Icons.cancel,
                            AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.padding),

            // Orders List
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sifariş Tarixçəsi',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: AppSizes.padding),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _orders.isEmpty
                                ? Center(
                                    child: Text(
                                      'Sifariş yoxdur',
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _orders.length,
                                    itemBuilder: (context, index) {
                                      final order = _orders[index];
                                      return _buildOrderItem(order);
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final status = order['status'] ?? '';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final createdAt = DateTime.tryParse(order['createdAt'] ?? '');
    final fare = order['fare']?['total'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['orderNumber'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'G: ${order['pickup']?['address'] ?? ''}',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'T: ${order['destination']?['address'] ?? ''}',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${fare.toStringAsFixed(2)} AZN',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return AppStrings.pending;
      case 'accepted':
        return AppStrings.accepted;
      case 'driver_assigned':
        return AppStrings.driverAssigned;
      case 'driver_arrived':
        return AppStrings.driverArrived;
      case 'in_progress':
        return AppStrings.inProgress;
      case 'completed':
        return AppStrings.completed;
      case 'cancelled':
        return AppStrings.cancelled;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
      case 'driver_assigned':
      case 'driver_arrived':
        return AppColors.primary;
      case 'in_progress':
        return AppColors.secondary;
      case 'completed':
        return Colors.black; // Completed -> black
      case 'cancelled':
        return AppColors.error; // Cancelled -> red
      default:
        return AppColors.textSecondary;
    }
  }
}

class CustomerOrdersDialog extends StatelessWidget {
  final Map<String, dynamic> customer;

  const CustomerOrdersDialog({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${customer['name']} - Sifarişlər'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            if (orderProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final customerOrders = orderProvider.orders
                .where((order) => order['customer']?['_id'] == customer['_id'])
                .toList();

            if (customerOrders.isEmpty) {
              return Center(
                child: Text(
                  AppStrings.noOrders,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return ListView.builder(
              itemCount: customerOrders.length,
              itemBuilder: (context, index) {
                final order = customerOrders[index];
                return ListTile(
                  title: Text('Sifariş #${order['orderNumber']}'),
                  subtitle: Text(order['pickup']['address']),
                  trailing: Text('${order['fare']['total']} ₼'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Show order details
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.close),
        ),
      ],
    );
  }
}
