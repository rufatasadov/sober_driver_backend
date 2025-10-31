import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/driver_provider.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/advanced_table_view.dart';
import '../widgets/syncfusion_orders_datagrid.dart';
import '../widgets/smart_address_search_field.dart';
import './customers_screen.dart' show CustomerDetailsDialog;
import 'orders/order_card.dart';
// order_details_dialog is imported where used in show dialog
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String _viewMode =
      'list'; // 'list', 'grid', 'table', 'advanced_table', 'syncfusion'

  // SharedPreferences key for saving view mode
  static const String _viewModeKey = 'orders_view_mode';

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadOrders();
    });
  }

  Future<void> _loadViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedViewMode = prefs.getString(_viewModeKey);
      if (savedViewMode != null &&
          ['list', 'grid', 'table', 'advanced_table', 'syncfusion']
              .contains(savedViewMode)) {
        setState(() {
          _viewMode = savedViewMode;
        });
      }
    } catch (e) {
      // If there's an error loading, use default 'list' view
      print('Error loading view mode: $e');
    }
  }

  Future<void> _saveViewMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_viewModeKey, mode);
    } catch (e) {
      print('Error saving view mode: $e');
    }
  }

  Future<void> _resetViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_viewModeKey);
      setState(() {
        _viewMode = 'list';
      });
    } catch (e) {
      print('Error resetting view mode: $e');
    }
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
                  AppStrings.orders,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    // View mode toggle
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Sətir görünüşü',
                            icon: const Icon(Icons.view_list),
                            color: _viewMode == 'list'
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.textSecondary,
                            onPressed: () {
                              setState(() => _viewMode = 'list');
                              _saveViewMode('list');
                            },
                          ),
                          IconButton(
                            tooltip: 'Şəbəkə görünüşü',
                            icon: const Icon(Icons.grid_view),
                            color: _viewMode == 'grid'
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.textSecondary,
                            onPressed: () {
                              setState(() => _viewMode = 'grid');
                              _saveViewMode('grid');
                            },
                          ),
                          IconButton(
                            tooltip: 'Cədvəl görünüşü',
                            icon: const Icon(Icons.table_chart),
                            color: _viewMode == 'table'
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.textSecondary,
                            onPressed: () {
                              setState(() => _viewMode = 'table');
                              _saveViewMode('table');
                            },
                          ),
                          IconButton(
                            tooltip: 'Təkmilləşdirilmiş cədvəl',
                            icon: const Icon(Icons.table_view),
                            color: _viewMode == 'advanced_table'
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.textSecondary,
                            onPressed: () {
                              setState(() => _viewMode = 'advanced_table');
                              _saveViewMode('advanced_table');
                            },
                          ),
                          IconButton(
                            tooltip: 'Syncfusion DataGrid',
                            icon: const Icon(Icons.table_rows),
                            color: _viewMode == 'syncfusion'
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.textSecondary,
                            onPressed: () {
                              setState(() => _viewMode = 'syncfusion');
                              _saveViewMode('syncfusion');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _resetViewMode,
                      tooltip: 'Görünüşü sıfırla',
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.padding),
                    CustomButton(
                      onPressed: () => _showAddOrderDialog(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add),
                          const SizedBox(width: AppSizes.paddingSmall),
                          Text(AppStrings.addOrder),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingLarge),

            // Filters
            _buildFilters(),
            const SizedBox(height: AppSizes.paddingLarge),

            // Orders List
            Expanded(
              child: Consumer<OrderProvider>(
                builder: (context, orderProvider, child) {
                  if (orderProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (orderProvider.orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSizes.padding),
                          Text(
                            AppStrings.noOrders,
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final orders = orderProvider.orders;
                  if (_viewMode == 'grid') {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width < 720
                            ? 1
                            : width < 1100
                                ? 2
                                : 3;
                        // Use fixed tile height to avoid overflow in cards
                        final double tileHeight = width < 720
                            ? 270
                            : width < 1100
                                ? 240
                                : 220;
                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: tileHeight,
                          ),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return OrderCard(
                              order: order,
                              onShowDetails: () => _showOrderDetails(order),
                              onAssignDriver: order['status'] == 'pending'
                                  ? () => _assignDriver(order)
                                  : null,
                            );
                          },
                        );
                      },
                    );
                  }

                  // if (_viewMode == 'table') {
                  //   return _buildTableView(orders);
                  // }

                  // if (_viewMode == 'advanced_table') {
                  //   return _buildAdvancedTableView(orders);
                  // }

                  if (_viewMode == 'syncfusion') {
                    return SyncfusionOrdersDataGrid(
                      orders: orders,
                      onOrderTap: _showOrderDetails,
                      onAssignDriver: _assignDriver,
                      onCancelOrder: _cancelOrder,
                    );
                  }

                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return OrderCard(
                        order: order,
                        onShowDetails: () => _showOrderDetails(order),
                        onAssignDriver: order['status'] == 'pending'
                            ? () => _assignDriver(order)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Row(
          children: [
            // Search
            Expanded(
              flex: 2,
              child: CustomTextField(
                controller: _searchController,
                hintText: AppStrings.searchOrders,
                prefixIconData: Icons.search,
                onChanged: (value) {
                  Provider.of<OrderProvider>(context, listen: false)
                      .searchOrders(value);
                },
              ),
            ),
            const SizedBox(width: AppSizes.padding),

            // Status Filter
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: AppStrings.status,
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'all', child: Text(AppStrings.all)),
                  DropdownMenuItem(
                      value: 'pending', child: Text(AppStrings.pending)),
                  DropdownMenuItem(
                      value: 'accepted', child: Text(AppStrings.accepted)),
                  DropdownMenuItem(
                      value: 'in_progress', child: Text(AppStrings.inProgress)),
                  DropdownMenuItem(
                      value: 'completed', child: Text(AppStrings.completed)),
                  DropdownMenuItem(
                      value: 'cancelled', child: Text(AppStrings.cancelled)),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                  Provider.of<OrderProvider>(context, listen: false)
                      .filterOrdersByStatus(value!);
                },
              ),
            ),
            const SizedBox(width: AppSizes.padding),

            // Date Range
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _startDate == null
                              ? AppStrings.startDate
                              : _formatDate(_startDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _endDate == null
                              ? AppStrings.endDate
                              : _formatDate(_endDate!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedTableView(List<Map<String, dynamic>> orders) {
    // Transform orders data to include computed fields
    final transformedOrders = orders.map((order) {
      final transformed = Map<String, dynamic>.from(order);

      // Add computed fields for better display
      transformed['customerName'] = order['customer']?['name'] ?? 'N/A';
      transformed['customerPhone'] = order['customer']?['phone'] ?? 'N/A';
      transformed['pickupAddress'] = order['pickup']?['address'] ?? 'N/A';
      transformed['destinationAddress'] =
          order['destination']?['address'] ?? 'N/A';
      transformed['orderDate'] = order['createdAt'] ?? order['date'] ?? 'N/A';
      transformed['totalFare'] = order['fare']?['total'] ?? order['fare'] ?? 0;

      return transformed;
    }).toList();

    return AdvancedTableView<Map<String, dynamic>>(
      data: transformedOrders,
      title: 'Sifarişlər (Təkmilləşdirilmiş)',
      columns: [
        TableColumn<Map<String, dynamic>>(
          key: 'orderNumber',
          title: 'Sifariş №',
          width: 120,
        ),
        TableColumn<Map<String, dynamic>>(
          key: 'customerName',
          title: 'Müştəri',
          width: 150,
        ),
        TableColumn<Map<String, dynamic>>(
          key: 'customerPhone',
          title: 'Telefon',
          width: 130,
        ),
        TableColumn<Map<String, dynamic>>(
          key: 'pickupAddress',
          title: 'Pickup',
          width: 200,
        ),
        TableColumn<Map<String, dynamic>>(
          key: 'destinationAddress',
          title: 'Təyinat',
          width: 200,
        ),
        TableColumn<Map<String, dynamic>>(
          key: 'status',
          title: 'Status',
          width: 120,
        ),
        TableColumn<Map<String, dynamic>>(
          key: 'totalFare',
          title: 'Qiymət',
          width: 100,
        ),
        TableColumn<Map<String, dynamic>>(
          key: 'orderDate',
          title: 'Tarix',
          width: 130,
        ),
        TableColumn<Map<String, dynamic>>(
          key: 'actions',
          title: 'Əməliyyatlar',
          width: 150,
        ),
      ],
      onRefresh: () {
        Provider.of<OrderProvider>(context, listen: false).loadOrders();
      },
      autoSizeColumns: true,
      cellBuilder: (item, column) {
        return _buildAdvancedOrderCell(column, item);
      },
      valueExtractor: (item, columnKey) =>
          _getOrderValueForFilter(item, columnKey),
      uniqueValuesExtractor: (columnKey) =>
          _getUniqueValuesForAdvancedTable(columnKey, transformedOrders),
    );
  }

  Widget _buildAdvancedOrderCell(
      TableColumn<Map<String, dynamic>> column, Map<String, dynamic> item) {
    switch (column.key) {
      case 'orderNumber':
        return Text(
          item['orderNumber']?.toString() ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
      case 'customerName':
        return Text(item['customerName']?.toString() ?? 'N/A');
      case 'customerPhone':
        return Text(item['customerPhone']?.toString() ?? 'N/A');
      case 'pickupAddress':
        return Text(
          item['pickupAddress']?.toString() ?? 'N/A',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      case 'destinationAddress':
        return Text(
          item['destinationAddress']?.toString() ?? 'N/A',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      case 'status':
        return _buildStatusChip(item['status']);
      case 'totalFare':
        return Text(
          '₼${item['totalFare']?.toString() ?? '0'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
      case 'orderDate':
        return Text(_formatOrderDate(item['orderDate']));
      case 'actions':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 18),
              onPressed: () => _showOrderDetails(item),
              tooltip: 'Detalları göstər',
            ),
            if (item['status'] == 'pending')
              IconButton(
                icon: const Icon(Icons.person_add, size: 18),
                onPressed: () => _assignDriver(item),
                tooltip: 'Sürücü təyin et',
              ),
          ],
        );
      default:
        return Text(item[column.key]?.toString() ?? '');
    }
  }

  String _getOrderValueForFilter(Map<String, dynamic> order, String columnKey) {
    switch (columnKey) {
      case 'orderNumber':
        return _safeString(order['orderNumber']);
      case 'customer':
        return _safeString(order['customer']?['name']);
      case 'phone':
        return _safeString(order['customer']?['phone']);
      case 'pickup':
        return _safeString(order['pickup']?['address']);
      case 'destination':
        return _safeString(order['destination']?['address']);
      case 'status':
        return _safeString(order['status']);
      case 'fare':
        return _formatFare(order['fare']?['total']);
      case 'date':
        return _formatOrderDate(order['createdAt']);
      default:
        return '';
    }
  }

  List<String> _getUniqueValuesForColumn(
      String columnKey, List<Map<String, dynamic>> orders) {
    final values = <String>{};

    // Handle transformed data fields for advanced table view
    final fieldMapping = {
      'pickupAddress': 'pickup',
      'destinationAddress': 'destination',
      'customerName': 'customer',
      'customerPhone': 'phone',
      'totalFare': 'fare',
      'orderDate': 'date',
    };

    for (final order in orders) {
      String value;

      // Check if this is a transformed field
      if (fieldMapping.containsKey(columnKey)) {
        // Use the original field structure
        final originalField = fieldMapping[columnKey]!;
        value = _getOrderValueForFilter(order, originalField);
      } else {
        // Use the direct field value
        value = _getOrderValueForFilter(order, columnKey);
      }

      if (value.isNotEmpty && value != 'N/A') {
        values.add(value);
      }
    }
    return values.toList()..sort();
  }

  List<String> _getUniqueValuesForAdvancedTable(
      String columnKey, List<Map<String, dynamic>> transformedOrders) {
    final values = <String>{};

    for (final order in transformedOrders) {
      String? value;

      switch (columnKey) {
        case 'orderNumber':
          value = order['orderNumber']?.toString();
          break;
        case 'customerName':
          value = order['customerName']?.toString();
          break;
        case 'customerPhone':
          value = order['customerPhone']?.toString();
          break;
        case 'pickupAddress':
          value = order['pickupAddress']?.toString();
          break;
        case 'destinationAddress':
          value = order['destinationAddress']?.toString();
          break;
        case 'status':
          value = order['status']?.toString();
          break;
        case 'totalFare':
          value = order['totalFare']?.toString();
          break;
        case 'orderDate':
          value = order['orderDate']?.toString();
          break;
        default:
          value = order[columnKey]?.toString();
      }

      if (value != null && value.isNotEmpty && value != 'N/A') {
        values.add(value);
      }
    }
    return values.toList()..sort();
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Gözləyir';
        break;
      case 'accepted':
        color = Colors.blue;
        text = 'Qəbul edildi';
        break;
      case 'in_progress':
        color = Colors.green;
        text = 'Davam edir';
        break;
      case 'completed':
        color = Colors.green;
        text = 'Tamamlandı';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Ləğv edildi';
        break;
      default:
        color = Colors.grey;
        text = 'Naməlum';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatOrderDate(dynamic date) {
    if (date == null) return 'N/A';

    try {
      if (date is String) {
        return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(date));
      } else if (date is DateTime) {
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatFare(dynamic fare) {
    if (fare == null) return 'N/A ₼';

    try {
      if (fare is num) {
        return '${fare.toStringAsFixed(2)} ₼';
      } else if (fare is String) {
        final numValue = double.tryParse(fare);
        if (numValue != null) {
          return '${numValue.toStringAsFixed(2)} ₼';
        }
      }
      return 'N/A ₼';
    } catch (e) {
      return 'N/A ₼';
    }
  }

  String _safeString(dynamic value) {
    if (value == null) return 'N/A';
    if (value is String) return value.isEmpty ? 'N/A' : value;
    return value.toString();
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailsDialog(order: order),
    );
  }

  void _assignDriver(Map<String, dynamic> order) async {
    try {
      // Show driver selection dialog
      final selectedDriver = await _showDriverSelectionDialog();
      if (selectedDriver != null) {
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);
        await orderProvider.assignDriver(order['id'], selectedDriver['id']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sürücü uğurla təyin edildi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _cancelOrder(Map<String, dynamic> order) async {
    try {
      String? reason;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Sifarişi ləğv et'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bu sifarişi ləğv etmək istədiyinizə əminsiniz?'),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Ləğv səbəbi',
                  hintText: 'Ləğv səbəbini daxil edin',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => reason = value,
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Ləğv et'),
            ),
            TextButton(
              onPressed: () {
                if (reason != null && reason!.isNotEmpty) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ləğv səbəbini daxil edin'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: Text('Bəli, ləğv et'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ],
        ),
      );

      if (confirmed == true && reason != null) {
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);
        await orderProvider.cancelOrder(order['id'], reason!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sifariş uğurla ləğv edildi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _showDriverSelectionDialog() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.loadDrivers();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sürücü Seçin'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Consumer<DriverProvider>(
            builder: (context, driverProvider, child) {
              if (driverProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final availableDrivers = driverProvider.drivers
                  .where((driver) =>
                      driver['isOnline'] == true &&
                      driver['isAvailable'] == true)
                  .toList();

              if (availableDrivers.isEmpty) {
                return Center(
                  child: Text(
                    'Mövcud sürücü yoxdur',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                itemCount: availableDrivers.length,
                itemBuilder: (context, index) {
                  final driver = availableDrivers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                          driver['user']?['name']?[0]?.toUpperCase() ?? '?'),
                    ),
                    title: Text(driver['user']?['name'] ?? 'Ad yoxdur'),
                    subtitle: Text(
                        '${driver['vehicleInfo']?['make'] ?? ''} ${driver['vehicleInfo']?['model'] ?? ''} - ${driver['vehicleInfo']?['plateNumber'] ?? ''}'),
                    onTap: () => Navigator.of(context).pop(driver),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }

  void _showAddOrderDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddOrderDialog(),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // order card moved to orders/order_card.dart
}

class AddOrderDialog extends StatefulWidget {
  const AddOrderDialog({super.key});

  @override
  State<AddOrderDialog> createState() => _AddOrderDialogState();
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format: XX XXX XX XX
    String formatted = '';
    for (int i = 0; i < digits.length && i < 9; i++) {
      if (i == 2 || i == 5 || i == 7) {
        formatted += ' ';
      }
      formatted += digits[i];
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _AddOrderDialogState extends State<AddOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _phonePrefixController = TextEditingController(text: '+994');
  final _pickupAddressController = TextEditingController();
  final _destinationAddressController = TextEditingController();
  final List<TextEditingController> _stopAddressControllers = [];
  final _notesController = TextEditingController();
  final _manualFareController = TextEditingController();
  // Coordinates state (lat, lon)
  List<double>? _pickupLatLon = const [40.3777, 49.8920];
  List<double>? _destLatLon = const [40.4093, 49.8671];
  final List<List<double>?> _stopLatLons = [];

  String _selectedPaymentMethod = 'cash'; // Fixed to cash
  DateTime? _scheduledTime;
  bool _isScheduled = false;
  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _customerAddresses = [];
  Map<String, dynamic>? _calculatedFare;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customerPhoneController.addListener(_onPhoneChanged);
    // Set default customer name
    _customerNameController.text = 'Müştəri';
    // Load phone prefix from admin settings
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final adminProvider =
            Provider.of<AdminProvider>(context, listen: false);
        final prefix = await adminProvider.getSetting('phone_prefix');
        if (prefix != null && prefix.isNotEmpty) {
          _phonePrefixController.text = prefix;
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _customerPhoneController.removeListener(_onPhoneChanged);
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _pickupAddressController.dispose();
    _destinationAddressController.dispose();
    for (final c in _stopAddressControllers) {
      c.dispose();
    }
    _notesController.dispose();
    _manualFareController.dispose();
    super.dispose();
  }

  void _addStopField() {
    setState(() {
      _stopAddressControllers.add(TextEditingController());
      _stopLatLons.add(null);
    });
  }

  void _removeStopField(int index) {
    setState(() {
      _stopAddressControllers[index].dispose();
      _stopAddressControllers.removeAt(index);
      _stopLatLons.removeAt(index);
    });
  }

  void _onPhoneChanged() async {
    final phone =
        '${_phonePrefixController.text.trim()}${_customerPhoneController.text.trim().replaceAll(RegExp(r'[^\\d]'), '')}';
    if (phone.length >= 13) {
      // prefix + 9 digits
      final customer = await Provider.of<OrderProvider>(context, listen: false)
          .getCustomerByPhone(phone);

      print("phone: $phone");

      if (customer != null) {
        setState(() {
          _selectedCustomer = customer;
          _customerNameController.text = customer['name'] ?? '';
        });

        // Load customer addresses
        _loadCustomerAddresses(customer['id']);
      } else {
        setState(() {
          _selectedCustomer = null;
          _customerAddresses = [];
        });
      }
    }
  }

  Future<void> _loadCustomerAddresses(String customerId) async {
    try {
      final addresses = await Provider.of<OrderProvider>(context, listen: false)
          .getCustomerAddresses(customerId);
      setState(() {
        _customerAddresses = addresses;
      });
    } catch (e) {
      print('Load addresses error: $e');
    }
  }

  Future<void> _calculateFare() async {
    if (_pickupAddressController.text.isEmpty ||
        _destinationAddressController.text.isEmpty) {
      return;
    }

    // Use actual coordinates from map picker
    final pickupCoords = _pickupLatLon ?? const [40.3777, 49.8920];
    final destCoords = _destLatLon ?? const [40.4093, 49.8671];
    final stopCoords = _stopAddressControllers
        .where((c) => c.text.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((entry) => _stopLatLons[entry.key] ?? const [40.3900, 49.8800])
        .toList();

    // Calculate distance and fare
    // Multi-leg distance
    double distance = 0;
    final legs = [pickupCoords, ...stopCoords, destCoords];
    for (int i = 0; i < legs.length - 1; i++) {
      final a = legs[i];
      final b = legs[i + 1];
      distance += _calculateDistance(a[0], a[1], b[0], b[1]);
    }
    final baseFare = distance * 5.0; // 5 AZN per km

    setState(() {
      _calculatedFare = {
        'distance': distance,
        'baseFare': baseFare,
        'estimatedTime': (distance / 30 * 60).round(), // 30 km/h average speed
      };
      _manualFareController.text = baseFare.toStringAsFixed(2);
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  void _selectAddress(Map<String, dynamic> address) {
    if (address['type'] == 'pickup') {
      _pickupAddressController.text = address['address'];
      final coords = address['coordinates'];
      if (coords is List && coords.length >= 2) {
        // Backend provides [lng, lat]
        final lng = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        setState(() {
          _pickupLatLon = [lat, lng];
        });
      }
    } else {
      _destinationAddressController.text = address['address'];
      final coords = address['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lng = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        setState(() {
          _destLatLon = [lat, lng];
        });
      }
    }
    _calculateFare();
  }

  String _formatLatLon(List<double> latlon) {
    return '${latlon[0].toStringAsFixed(6)}, ${latlon[1].toStringAsFixed(6)}';
  }

  // Map picker placeholder (OpenStreetMap via flutter_map)
  Future<List<double>?> _pickOnMap({required List<double> initial}) async {
    final result = await Navigator.of(context).push<List<double>>(
      MaterialPageRoute(
        builder: (context) => MapPickerDialog(initial: initial),
        fullscreenDialog: true,
      ),
    );
    return result;
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1');
      final resp = await http.get(uri, headers: {
        'User-Agent': 'AyiqSurucuOperator/1.0 (contact@example.com)'
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final name = data['display_name']?.toString();
        if (name != null && name.isNotEmpty) return name;
      }
    } catch (_) {}
    return _formatLatLon([lat, lon]);
  }

  Future<void> _selectScheduledTime() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );

    if (selected != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            selected.year,
            selected.month,
            selected.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);

        // Prepare order data
        final orderData = {
          'customerPhone':
              '+994${_customerPhoneController.text.trim().replaceAll(RegExp(r'[^\d]'), '')}',
          'customerName': _customerNameController.text.trim().isEmpty
              ? 'Müştəri'
              : _customerNameController.text.trim(),
          'pickup': {
            'address': _pickupAddressController.text.trim(),
            'coordinates': [
              (_pickupLatLon ?? const [40.3777, 49.8920])[1],
              (_pickupLatLon ?? const [40.3777, 49.8920])[0]
            ],
            'instructions': '',
          },
          'destination': {
            'address': _destinationAddressController.text.trim(),
            'coordinates': [
              (_destLatLon ?? const [40.4093, 49.8671])[1],
              (_destLatLon ?? const [40.4093, 49.8671])[0]
            ],
            'instructions': '',
          },
          'stops': _stopAddressControllers
              .where((c) => c.text.trim().isNotEmpty)
              .toList()
              .asMap()
              .entries
              .map((entry) => {
                    return {
                      'address': entry.value.text.trim(),
                      'coordinates': [
                        (_stopLatLons[entry.key] ?? const [40.3900, 49.8800])[1],
                        (_stopLatLons[entry.key] ?? const [40.3900, 49.8800])[0]
                      ],
                      'instructions': ''
                    };
                  })
              .toList(),
          'payment': {
            'method': _selectedPaymentMethod,
          },
          'notes': _notesController.text.trim(),
        };

        // Add scheduled time if selected
        if (_isScheduled && _scheduledTime != null) {
          orderData['scheduledTime'] = _scheduledTime!.toIso8601String();
        }

        // Add manual fare if provided
        if (_manualFareController.text.isNotEmpty) {
          orderData['manualFare'] = double.parse(_manualFareController.text);
        }

        await orderProvider.createEnhancedOrder(orderData);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sifariş uğurla yaradıldı'),
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
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Yeni Sifariş',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Bağla',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.padding),

              // Customer Information
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Editable phone prefix
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  controller: _phonePrefixController,
                                  decoration: const InputDecoration(
                                    hintText: '+994',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[+\d]')),
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  onChanged: (_) => _onPhoneChanged(),
                                ),
                              ),
                              // Phone number input
                              Expanded(
                                child: TextFormField(
                                  controller: _customerPhoneController,
                                  decoration: const InputDecoration(
                                    hintText: '50 123 45 67',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  autofocus: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(9),
                                    _PhoneNumberFormatter(),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Telefon nömrəsi tələb olunur';
                                    }
                                    if (value.length < 9) {
                                      return 'Tam telefon nömrəsi daxil edin';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    // Remove any non-digit characters for validation
                                    final cleanValue =
                                        value.replaceAll(RegExp(r'[^\d]'), '');
                                    if (cleanValue.length >= 10) {
                                      _onPhoneChanged();
                                    }
                                  },
                                ),
                              ),
                              // History button
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: IconButton(
                                  tooltip: 'Sifariş tarixçəsinə bax',
                                  icon: const Icon(Icons.history),
                                  onPressed: () async {
                                    final phone =
                                        '${_phonePrefixController.text.trim()}${_customerPhoneController.text.trim()}';
                                    if (phone.length < 13) return;
                                    final customer =
                                        await Provider.of<OrderProvider>(
                                                context,
                                                listen: false)
                                            .getCustomerByPhone(phone);
                                    if (customer == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Bu nömrə üzrə müştəri tapılmadı'),
                                          backgroundColor: AppColors.warning,
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      _selectedCustomer = customer;
                                    });
                                    // Open customer details dialog
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (_) => CustomerDetailsDialog(
                                            customer: customer),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.padding),
                  Expanded(
                    child: CustomTextField(
                      controller: _customerNameController,
                      labelText: 'Müştəri adı',
                      hintText: 'Ad və soyad',
                      validator: (value) {
                        // Customer name is now optional
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              // Customer order count display
              if (_selectedCustomer != null) ...[
                const SizedBox(height: AppSizes.padding),
                FutureBuilder<Map<String, dynamic>>(
                  future: Provider.of<OrderProvider>(context, listen: false)
                      .getCustomerOrderCount(_selectedCustomer!['id']),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final data = snapshot.data!;
                      return Container(
                        padding: const EdgeInsets.all(AppSizes.paddingSmall),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radius),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: AppSizes.paddingSmall),
                            Text(
                              'Bu müştərinin ${data['totalOrders']} sifarişi var (${data['completedOrders']} tamamlanmış, ${data['cancelledOrders']} ləğv edilmiş)',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],

              const SizedBox(height: AppSizes.padding),

              // Address Information
              Text(
                'Ünvan Məlumatları',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.padding),

              // Previous addresses
              if (_customerAddresses.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Əvvəlki ünvanlar:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      Wrap(
                        spacing: AppSizes.paddingSmall,
                        runSpacing: AppSizes.paddingSmall,
                        children: _customerAddresses.map((address) {
                          return ActionChip(
                            label: Text(
                              address['address'],
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _selectAddress(address),
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppColors.primary),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.padding),
              ],

              SmartAddressSearchField(
                controller: _pickupAddressController,
                labelText: 'Götürülmə ünvanı',
                hintText: 'Götürülmə ünvanını daxil edin və ya axtarın',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Götürülmə ünvanı tələb olunur';
                  }
                  return null;
                },
                onChanged: (value) => _calculateFare(),
                onCoordinatesSelected: (lat, lng) {
                  setState(() {
                    _pickupLatLon = [lat, lng];
                  });
                  _calculateFare();
                },
                onAddressSelected: (address) {
                  _calculateFare();
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final coords = await _pickOnMap(
                        initial: _pickupLatLon ?? const [40.3777, 49.8920]);
                    if (coords != null) {
                      final addr = await _reverseGeocode(coords[0], coords[1]);
                      setState(() {
                        _pickupLatLon = coords;
                        _pickupAddressController.text = addr;
                      });
                      _calculateFare();
                    }
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Xəritədən seç (OSM)'),
                ),
              ),

              const SizedBox(height: AppSizes.padding),

              // Dynamic Stops
              if (_stopAddressControllers.isNotEmpty)
                Column(
                  children:
                      List.generate(_stopAddressControllers.length, (index) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSizes.paddingSmall),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _stopAddressControllers[index],
                              labelText: 'Ara dayanacaq ${index + 1}',
                              hintText: 'Ünvan daxil edin',
                              onChanged: (value) => _calculateFare(),
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          TextButton.icon(
                            onPressed: () async {
                              final coords = await _pickOnMap(
                                  initial: _stopLatLons[index] ??
                                      const [40.3900, 49.8800]);
                              if (coords != null) {
                                final addr =
                                    await _reverseGeocode(coords[0], coords[1]);
                                setState(() {
                                  _stopLatLons[index] = coords;
                                  _stopAddressControllers[index].text = addr;
                                });
                                _calculateFare();
                              }
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('Xəritə'),
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          IconButton(
                            onPressed: () => _removeStopField(index),
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                          )
                        ],
                      ),
                    );
                  }),
                ),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addStopField,
                  icon: const Icon(Icons.add),
                  label: const Text('Ara dayanacaq əlavə et'),
                ),
              ),

              const SizedBox(height: AppSizes.padding),

              SmartAddressSearchField(
                controller: _destinationAddressController,
                labelText: 'Təyinat ünvanı',
                hintText: 'Təyinat ünvanını daxil edin və ya axtarın',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Təyinat ünvanı tələb olunur';
                  }
                  return null;
                },
                onChanged: (value) => _calculateFare(),
                onCoordinatesSelected: (lat, lng) {
                  setState(() {
                    _destLatLon = [lat, lng];
                  });
                  _calculateFare();
                },
                onAddressSelected: (address) {
                  _calculateFare();
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final coords = await _pickOnMap(
                        initial: _destLatLon ?? const [40.4093, 49.8671]);
                    if (coords != null) {
                      final addr = await _reverseGeocode(coords[0], coords[1]);
                      setState(() {
                        _destLatLon = coords;
                        _destinationAddressController.text = addr;
                      });
                      _calculateFare();
                    }
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Xəritədən seç (OSM)'),
                ),
              ),

              const SizedBox(height: AppSizes.padding),

              // Fare Information
              if (_calculatedFare != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hesablanmış qiymət:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      Row(
                        children: [
                          Text(
                            'Məsafə: ${_calculatedFare!['distance'].toStringAsFixed(1)} km',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: AppSizes.padding),
                          Text(
                            'Təxmini vaxt: ${_calculatedFare!['estimatedTime']} dəqiqə',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.padding),
              ],

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _manualFareController,
                      labelText: 'Qiymət (AZN)',
                      hintText: '0.00',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Qiymət tələb olunur';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Düzgün qiymət daxil edin';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.padding),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Ödəniş üsulu',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'cash', child: Text(AppStrings.cash)),
                      ],
                      onChanged: null, // Disabled
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.padding),

              // Scheduling (Disabled)
              Row(
                children: [
                  Checkbox(
                    value: _isScheduled,
                    onChanged: null, // Disabled
                  ),
                  Text(
                    'Gələcək vaxt üçün təyin et',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: null, // Disabled
                    icon: const Icon(Icons.schedule),
                    label: const Text('Vaxt seç'),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.padding),

              CustomTextField(
                controller: _notesController,
                labelText: 'Qeydlər',
                hintText: 'Əlavə qeydlər...',
                maxLines: 3,
              ),

              const SizedBox(height: AppSizes.padding),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppStrings.cancel),
                  ),
                  const SizedBox(width: AppSizes.padding),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitOrder,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppStrings.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sifariş #${order['orderNumber']}'),
      content: OrderEditorDialog(order: order),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.close),
        ),
      ],
    );
  }
}

class OrderEditorDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderEditorDialog({super.key, required this.order});

  @override
  State<OrderEditorDialog> createState() => _OrderEditorDialogState();
}

class _OrderEditorDialogState extends State<OrderEditorDialog> {
  late String _status;
  late TextEditingController _pickupController;
  late TextEditingController _destinationController;
  late TextEditingController _notesController;
  List<double>? _pickupLatLon;
  List<double>? _destLatLon;
  Map<String, dynamic>? _selectedDriver;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _status = o['status'] ?? 'pending';
    _pickupController =
        TextEditingController(text: o['pickup']?['address'] ?? '');
    _destinationController =
        TextEditingController(text: o['destination']?['address'] ?? '');
    _notesController =
        TextEditingController(text: o['notes']?.toString() ?? '');
    final p = o['pickup']?['location']?['coordinates'];
    final d = o['destination']?['location']?['coordinates'];
    if (p is List && p.length >= 2) {
      _pickupLatLon = [(p[1] as num).toDouble(), (p[0] as num).toDouble()];
    }
    if (d is List && d.length >= 2) {
      _destLatLon = [(d[1] as num).toDouble(), (d[0] as num).toDouble()];
    }
    _selectedDriver = o['driver'] as Map<String, dynamic>?;
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final theme = Theme.of(context);
    final customer = order['customer'] as Map<String, dynamic>?;
    final paymentMethod =
        order['payment']?['method']?.toString().toUpperCase() ?? 'N/A';
    final fare = order['fare']?['total'];
    final fareText = fare == null
        ? '-'
        : (fare is num
            ? fare.toStringAsFixed(2)
            : (double.tryParse(fare.toString())?.toStringAsFixed(2) ?? '-'));

    return SizedBox(
      width: 860,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: order number + status chip
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sifariş #${order['orderNumber'] ?? ''}',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                // Save button in header
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(AppStrings.save),
                  ),
                ),
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: _statusColor(_status).withOpacity(0.15),
                    child: Icon(Icons.local_taxi, color: _statusColor(_status)),
                  ),
                  label: Text(_statusText(_status)),
                  backgroundColor: _statusColor(_status).withOpacity(0.08),
                  side: BorderSide(
                      color: _statusColor(_status).withOpacity(0.25)),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.padding),

            // Status timeline
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Status tarixçəsi',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSizes.padding),
                    ..._buildStatusTimeline(order),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.padding),

            // Status & driver controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'pending', child: Text('Gözləyir')),
                          DropdownMenuItem(
                              value: 'accepted', child: Text('Qəbul edildi')),
                          DropdownMenuItem(
                              value: 'driver_assigned',
                              child: Text('Sürücü təyin')),
                          DropdownMenuItem(
                              value: 'driver_arrived',
                              child: Text('Sürücü gəldi')),
                          DropdownMenuItem(
                              value: 'in_progress', child: Text('Yoldadır')),
                          DropdownMenuItem(
                              value: 'completed', child: Text('Tamamlandı')),
                          DropdownMenuItem(
                              value: 'cancelled', child: Text('Ləğv edildi')),
                        ],
                        onChanged: (v) =>
                            setState(() => _status = v ?? _status),
                      ),
                    ),
                    const SizedBox(width: AppSizes.padding),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.person, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDriver != null
                                  ? (_selectedDriver!['user']?['name'] ??
                                      _selectedDriver!['name'] ??
                                      '')
                                  : 'Sürücü: təyin edilməyib',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          TextButton.icon(
                            onPressed: _changeDriver,
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Sürücünü dəyiş'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.padding),

            // General info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  children: [
                    _infoTile(Icons.person_outline, 'Müştəri',
                        customer?['name'] ?? 'N/A'),
                    const Divider(height: 16),
                    _infoTile(Icons.phone_outlined, 'Telefon',
                        customer?['phone'] ?? 'N/A'),
                    const Divider(height: 16),
                    _infoTile(Icons.payment, 'Ödəniş', paymentMethod),
                    const Divider(height: 16),
                    _infoTile(Icons.calendar_today_outlined, 'Yaradılma tarixi',
                        _formatDateTime(order['createdAt'])),
                    const Divider(height: 16),
                    _infoTile(Icons.schedule_outlined, 'Son yenilənmə',
                        _formatDateTime(order['updatedAt'])),
                    const Divider(height: 16),
                    _infoTile(Icons.straighten, 'Məsafə',
                        '${order['estimatedDistance']?.toString() ?? '-'} km'),
                    const Divider(height: 16),
                    _infoTile(Icons.timer_outlined, 'Vaxt',
                        '${order['estimatedTime']?.toString() ?? '-'} dəq'),
                    const Divider(height: 16),
                    _infoTile(Icons.attach_money, 'Qiymət', '$fareText ₼'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.padding),

            // Addresses with bolt-like stop points
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Ünvanlar', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSizes.padding),

                    // Pickup stop point
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Bolt-like pickup icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.electric_bolt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Pickup address
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Götürülmə ünvanı',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CustomTextField(
                                  controller: _pickupController,
                                  labelText: 'Ünvanı daxil edin',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Map picker button
                          TextButton.icon(
                            onPressed: () async {
                              final coords = await _openMapPicker(
                                _pickupLatLon ?? const [40.3777, 49.8920],
                              );
                              if (coords != null)
                                setState(() => _pickupLatLon = coords);
                            },
                            icon: const Icon(Icons.map, color: Colors.green),
                            label: const Text('Xəritə'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                              backgroundColor: Colors.green.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSizes.padding),

                    // Stops section
                    if (order['stops'] != null &&
                        (order['stops'] as List).isNotEmpty) ...[
                      ...(order['stops'] as List).asMap().entries.map((entry) {
                        final index = entry.key;
                        final stop = entry.value as Map<String, dynamic>;
                        final stopAddress =
                            stop['address']?.toString() ?? 'Ünvan yoxdur';

                        return Column(
                          children: [
                            // Stop point
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Bolt-like stop icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.electric_bolt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Stop address
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ara dayanacaq ${index + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          stopAddress,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.padding),

                            // Route line to next stop
                            if (index < (order['stops'] as List).length - 1)
                              Container(
                                height: 20,
                                child: Row(
                                  children: [
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.withOpacity(0.5),
                                              Colors.blue.withOpacity(0.5),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                  ],
                                ),
                              ),

                            if (index < (order['stops'] as List).length - 1)
                              const SizedBox(height: AppSizes.padding),
                          ],
                        );
                      }).toList(),

                      const SizedBox(height: AppSizes.padding),

                      // Route line to destination
                      Container(
                        height: 20,
                        child: Row(
                          children: [
                            const SizedBox(width: 24),
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.withOpacity(0.5),
                                      Colors.orange.withOpacity(0.5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSizes.padding),
                    ] else ...[
                      // Route line indicator (when no stops)
                      Container(
                        height: 40,
                        child: Row(
                          children: [
                            const SizedBox(width: 24),
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.withOpacity(0.5),
                                      Colors.orange.withOpacity(0.5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSizes.padding),
                    ],

                    const SizedBox(height: AppSizes.padding),

                    // Destination stop point
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Bolt-like destination icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.electric_bolt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Destination address
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Təyinat ünvanı',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CustomTextField(
                                  controller: _destinationController,
                                  labelText: 'Ünvanı daxil edin',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Map picker button
                          TextButton.icon(
                            onPressed: () async {
                              final coords = await _openMapPicker(
                                _destLatLon ?? const [40.4093, 49.8671],
                              );
                              if (coords != null)
                                setState(() => _destLatLon = coords);
                            },
                            icon: const Icon(Icons.map, color: Colors.orange),
                            label: const Text('Xəritə'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange,
                              backgroundColor: Colors.orange.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.padding),

            // Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: _notesController,
                      labelText: 'Qeydlər',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'driver_assigned':
      case 'driver_arrived':
        return Colors.blue;
      case 'in_progress':
        return Colors.deepPurple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Gözləyir';
      case 'accepted':
        return 'Qəbul edildi';
      case 'driver_assigned':
        return 'Sürücü təyin';
      case 'driver_arrived':
        return 'Sürücü gəldi';
      case 'in_progress':
        return 'Yoldadır';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'Ləğv edildi';
      default:
        return status;
    }
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  List<Widget> _buildStatusTimeline(Map<String, dynamic> order) {
    final List<dynamic> timeline =
        order['timeline'] is List ? (order['timeline'] as List) : [];
    if (timeline.isEmpty) {
      return [
        _timelineTile('Yaradıldı', order['createdAt']),
        _timelineTile(_statusText(order['status'] ?? ''), order['updatedAt']),
      ];
    }

    return timeline.map((e) {
      final status = e['status']?.toString() ?? '';
      final ts = e['timestamp'];
      return _timelineTile(_statusText(status), ts);
    }).toList();
  }

  Widget _timelineTile(String title, dynamic timestamp) {
    final when = _formatDateTime(timestamp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(when,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<List<double>?> _openMapPicker(List<double> initial) async {
    final result = await Navigator.of(context).push<List<double>>(
      MaterialPageRoute(
        builder: (context) => MapPickerDialog(initial: initial),
        fullscreenDialog: true,
      ),
    );
    return result;
  }

  // _readOnlyRow removed (replaced by _infoTile)

  Future<void> _changeDriver() async {
    final driver = await _showDriverPicker();
    if (driver != null) setState(() => _selectedDriver = driver);
  }

  Future<Map<String, dynamic>?> _showDriverPicker() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.loadDrivers();
    final drivers = driverProvider.drivers;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sürücü seçin'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final d = drivers[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(d['user']?['name'] ?? 'Ad yoxdur'),
                subtitle: Text(d['user']?['phone'] ?? ''),
                trailing: (d['isOnline'] == true && d['isAvailable'] == true)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.remove_circle, color: Colors.redAccent),
                onTap: () => Navigator.of(context).pop(d),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.cancel))
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final orderId = widget.order['id'] ?? widget.order['_id'];
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      if (_selectedDriver != null) {
        final currentDriverId =
            widget.order['driver']?['id'] ?? widget.order['driverId'];
        if (_selectedDriver!['id'] != currentDriverId) {
          await orderProvider.assignDriver(orderId, _selectedDriver!['id']);
        }
      }
      final updates = <String, dynamic>{
        'status': _status,
        'pickup': {
          'address': _pickupController.text.trim(),
          if (_pickupLatLon != null)
            'coordinates': [_pickupLatLon![1], _pickupLatLon![0]],
        },
        'destination': {
          'address': _destinationController.text.trim(),
          if (_destLatLon != null)
            'coordinates': [_destLatLon![1], _destLatLon![0]],
        },
        'notes': _notesController.text.trim(),
      };
      await orderProvider.updateOrder(orderId, updates);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? 'Sifariş yenilənmədi' : message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return 'N/A';
    if (value is DateTime) {
      return DateFormat('dd.MM.yyyy HH:mm').format(value);
    }
    if (value is num) {
      // Handle epoch seconds or milliseconds
      final int ms =
          value < 1000000000000 ? (value * 1000).toInt() : value.toInt();
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateFormat('dd.MM.yyyy HH:mm').format(d);
    }
    final s = value.toString();
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return 'N/A';
    return DateFormat('dd.MM.yyyy HH:mm').format(parsed);
  }
}

class MapPickerDialog extends StatefulWidget {
  final List<double> initial; // [lat, lon]
  const MapPickerDialog({super.key, required this.initial});

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  late LatLng _center;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.initial[0], widget.initial[1]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ünvan Seçin'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context)
                .pop([_center.latitude, _center.longitude]),
            icon: const Icon(Icons.check),
            tooltip: 'Seç',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Məkan adı ilə axtar...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _searchPlaces(value),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSearching
                      ? null
                      : () => _searchPlaces(_searchController.text.trim()),
                  icon: const Icon(Icons.search),
                  label: const Text('Axtar'),
                )
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 13,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _center = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _center,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_suggestions.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Card(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            final s = _suggestions[index];
                            return ListTile(
                              leading: const Icon(Icons.place),
                              title: Text(s['display_name'] ?? ''),
                              onTap: () {
                                final lat = double.tryParse(s['lat'] ?? '') ??
                                    _center.latitude;
                                final lon = double.tryParse(s['lon'] ?? '') ??
                                    _center.longitude;
                                setState(() {
                                  _center = LatLng(lat, lon);
                                  _suggestions = [];
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
    });
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5');
      final resp = await http.get(uri, headers: {
        'User-Agent': 'AyiqSurucuOperator/1.0 (contact@example.com)'
      });
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        setState(() {
          _suggestions = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }
}
