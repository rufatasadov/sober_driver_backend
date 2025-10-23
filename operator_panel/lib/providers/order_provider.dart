import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class OrderProvider with ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _customers = [];

  bool get isLoading => _isLoading;
  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get orders => _orders;
  List<Map<String, dynamic>> get recentOrders => _recentOrders;
  List<Map<String, dynamic>> get customers => _customers;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.operator}/dashboard'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _stats = data['stats'] ?? {};
        _recentOrders =
            List<Map<String, dynamic>>.from(data['recentOrders'] ?? []);
      } else {
        // If dashboard endpoint doesn't exist, load basic data
        _stats = {
          'todayOrders': 0,
          'todayCompleted': 0,
          'todayPending': 0,
          'onlineDrivers': 0,
        };
        _recentOrders = [];
      }
    } catch (e) {
      print('Dashboard data load error: $e');
      // Set default values on error
      _stats = {
        'todayOrders': 0,
        'todayCompleted': 0,
        'todayPending': 0,
        'onlineDrivers': 0,
      };
      _recentOrders = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadOrders({
    int page = 1,
    int limit = 20,
    String? status,
    String? startDate,
    String? endDate,
    String? customerPhone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (customerPhone != null) 'customerPhone': customerPhone,
      };

      final uri = Uri.parse('${ApiEndpoints.operator}/orders')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _orders = List<Map<String, dynamic>>.from(data['orders'] ?? []);
      }
    } catch (e) {
      print('Orders load error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.operator}/customers'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _customers = List<Map<String, dynamic>>.from(data['customers'] ?? []);
      }
    } catch (e) {
      print('Customers load error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchCustomers(String query) async {
    if (query.isEmpty) {
      await loadCustomers();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.operator}/customers/search?search=$query'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _customers = List<Map<String, dynamic>>.from(data['customers'] ?? []);
      }
    } catch (e) {
      print('Customer search error: $e');
      // Fallback to client-side search
      _customers = _customers.where((customer) {
        final name = customer['name']?.toString().toLowerCase() ?? '';
        final phone = customer['phone']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) || phone.contains(searchQuery);
      }).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  void searchOrders(String query) {
    if (query.isEmpty) {
      loadOrders();
      return;
    }

    _orders = _orders.where((order) {
      final orderNumber = order['orderNumber']?.toString().toLowerCase() ?? '';
      final customerName =
          order['customer']?['name']?.toString().toLowerCase() ?? '';
      final pickupAddress =
          order['pickup']?['address']?.toString().toLowerCase() ?? '';
      final destinationAddress =
          order['destination']?['address']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return orderNumber.contains(searchQuery) ||
          customerName.contains(searchQuery) ||
          pickupAddress.contains(searchQuery) ||
          destinationAddress.contains(searchQuery);
    }).toList();

    notifyListeners();
  }

  void filterOrdersByStatus(String status) {
    if (status == 'all') {
      loadOrders();
      return;
    }

    _orders = _orders.where((order) {
      return order['status'] == status;
    }).toList();

    notifyListeners();
  }

  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.operator}/orders'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode(orderData),
      );

      if (response.statusCode == 201) {
        await loadDashboardData();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Sifariş yaradılmadı');
      }
    } catch (e) {
      print('Create order error: $e');
      rethrow;
    }
  }

  Future<bool> assignDriver(String orderId, String driverId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.operator}/orders/$orderId/assign-driver'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'driverId': driverId}),
      );

      if (response.statusCode == 200) {
        await loadDashboardData();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Sürücü təyin edilmədi');
      }
    } catch (e) {
      print('Assign driver error: $e');
      rethrow;
    }
  }

  Future<bool> updateOrder(String orderId, Map<String, dynamic> updates) async {
    try {
      // If updating status, use the dedicated status endpoint
      if (updates.containsKey('status')) {
        final statusResponse = await http.patch(
          Uri.parse('${ApiEndpoints.orders}/$orderId/status'),
          headers: {
            'Authorization': 'Bearer ${await _getToken()}',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'status': updates['status'],
            if (updates.containsKey('notes')) 'notes': updates['notes'],
          }),
        );

        if (statusResponse.statusCode == 200) {
          // If there are other updates besides status, update them separately
          final otherUpdates = Map<String, dynamic>.from(updates);
          otherUpdates.remove('status');
          otherUpdates.remove('notes');

          if (otherUpdates.isNotEmpty) {
            await _updateOrderDetails(orderId, otherUpdates);
          }

          await loadDashboardData();
          await loadOrders();
          return true;
        } else {
          final data = json.decode(statusResponse.body);
          throw Exception(data['error'] ?? 'Status yenilənmədi');
        }
      } else {
        // For non-status updates, use the operator endpoint
        return await _updateOrderDetails(orderId, updates);
      }
    } catch (e) {
      print('Update order error: $e');
      rethrow;
    }
  }

  Future<bool> _updateOrderDetails(
      String orderId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.operator}/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        await loadDashboardData();
        await loadOrders();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Sifariş yenilənmədi');
      }
    } catch (e) {
      print('Update order details error: $e');
      rethrow;
    }
  }

  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.operator}/orders/$orderId/cancel'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        await loadDashboardData();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Sifariş ləğv edilmədi');
      }
    } catch (e) {
      print('Cancel order error: $e');
      rethrow;
    }
  }

  Future<bool> createCustomer(Map<String, dynamic> customerData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.operator}/customers'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode(customerData),
      );

      if (response.statusCode == 201) {
        await loadCustomers();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Müştəri yaradılmadı');
      }
    } catch (e) {
      print('Create customer error: $e');
      rethrow;
    }
  }

  Future<bool> updateCustomer(
      String customerId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.operator}/customers/$customerId'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        await loadCustomers();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Müştəri yenilənmədi');
      }
    } catch (e) {
      print('Update customer error: $e');
      rethrow;
    }
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Token get error: $e');
      return null;
    }
  }

  String getStatusText(String status) {
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

  Color getStatusColor(String status) {
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
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String getPaymentMethodText(String method) {
    switch (method) {
      case 'cash':
        return AppStrings.cash;
      case 'card':
        return AppStrings.card;
      case 'online':
        return AppStrings.online;
      default:
        return method;
    }
  }

  // Customer management methods
  Future<bool> deleteCustomer(String customerId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiEndpoints.operator}/customers/$customerId'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await loadCustomers();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Müştəri silinmədi');
      }
    } catch (e) {
      print('Delete customer error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCustomerOrders(String customerId,
      {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiEndpoints.operator}/customers/$customerId/orders?page=$page'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Müştəri sifarişləri yüklənmədi');
      }
    } catch (e) {
      print('Get customer orders error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerAddresses(
      String customerId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.operator}/customers/$customerId/addresses'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['addresses'] ?? []);
      } else {
        throw Exception('Müştəri ünvanları yüklənmədi');
      }
    } catch (e) {
      print('Get customer addresses error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCustomerOrderCount(String customerId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.operator}/customers/$customerId/order-count'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Müştəri sifariş sayı yüklənmədi');
      }
    } catch (e) {
      print('Get customer order count error: $e');
      rethrow;
    }
  }

  // Enhanced order creation with all features
  Future<bool> createEnhancedOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.operator}/orders'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode(orderData),
      );

      if (response.statusCode == 201) {
        await loadDashboardData();
        await loadOrders();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Sifariş yaradılmadı');
      }
    } catch (e) {
      print('Create enhanced order error: $e');
      rethrow;
    }
  }

  // Get customer by phone
  Future<Map<String, dynamic>?> getCustomerByPhone(String phone) async {
    try {
      final customer = _customers.firstWhere(
        (c) => c['phone'] == phone.replaceAll(RegExp(r'\s'), ''),
        orElse: () => {},
      );
      return customer.isEmpty ? null : customer;
    } catch (e) {
      return null;
    }
  }
}
