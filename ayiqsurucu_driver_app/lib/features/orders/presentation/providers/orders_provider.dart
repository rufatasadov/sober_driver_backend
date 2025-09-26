import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/constants/app_constants.dart';

class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final String? driverId;
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> destination;
  final String status;
  final double? estimatedTime;
  final double? estimatedDistance;
  final double fare;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.driverId,
    required this.pickup,
    required this.destination,
    required this.status,
    this.estimatedTime,
    this.estimatedDistance,
    required this.fare,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customerId: json['customerId'] ?? '',
      driverId: json['driverId'],
      pickup: json['pickup'] ?? {},
      destination: json['destination'] ?? {},
      status: json['status'] ?? '',
      estimatedTime: json['estimatedTime']?.toDouble(),
      estimatedDistance: json['estimatedDistance']?.toDouble(),
      fare: (json['fare'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      notes: json['notes'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'driverId': driverId,
      'pickup': pickup,
      'destination': destination,
      'status': status,
      'estimatedTime': estimatedTime,
      'estimatedDistance': estimatedDistance,
      'fare': fare,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class OrdersProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  List<Order> _pendingOrders = [];
  List<Order> _activeOrders = [];
  List<Order> _completedOrders = [];
  Order? _currentOrder;

  bool _isLoading = false;
  String? _error;

  // Getters
  List<Order> get pendingOrders => _pendingOrders;
  List<Order> get activeOrders => _activeOrders;
  List<Order> get completedOrders => _completedOrders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize orders provider
  void initialize() {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for new orders
    _socketService.newOrderStream.listen((data) {
      final order = Order.fromJson(data['order']);
      _pendingOrders.add(order);
      notifyListeners();
    });

    // Listen for order status updates
    _socketService.orderStatusStream.listen((data) {
      final orderId = data['orderId'];
      final newStatus = data['status'];

      _updateOrderStatus(orderId, newStatus);
    });
  }

  void _updateOrderStatus(String orderId, String newStatus) {
    // Update in pending orders
    final pendingIndex = _pendingOrders.indexWhere(
      (order) => order.id == orderId,
    );
    if (pendingIndex != -1) {
      final order = _pendingOrders[pendingIndex];
      _pendingOrders.removeAt(pendingIndex);

      if (newStatus == AppConstants.orderAccepted) {
        _activeOrders.add(order);
      }
      notifyListeners();
      return;
    }

    // Update in active orders
    final activeIndex = _activeOrders.indexWhere(
      (order) => order.id == orderId,
    );
    if (activeIndex != -1) {
      final order = _activeOrders[activeIndex];
      _activeOrders.removeAt(activeIndex);

      if (newStatus == AppConstants.orderCompleted) {
        _completedOrders.add(order);
      }
      notifyListeners();
      return;
    }
  }

  // Get nearby orders
  Future<void> getNearbyOrders() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.get(AppConstants.nearbyOrdersEndpoint);
      final data = _apiService.handleResponse(response);

      if (data['orders'] != null) {
        _pendingOrders =
            (data['orders'] as List)
                .map((json) => Order.fromJson(json))
                .toList();
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Accept order
  Future<bool> acceptOrder(String orderId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.post(
        '${AppConstants.acceptOrderEndpoint}/$orderId/accept',
      );

      final data = _apiService.handleResponse(response);

      if (data['success'] == true) {
        // Move order from pending to active
        final orderIndex = _pendingOrders.indexWhere(
          (order) => order.id == orderId,
        );
        if (orderIndex != -1) {
          final order = _pendingOrders[orderIndex];
          _pendingOrders.removeAt(orderIndex);
          _activeOrders.add(order);
          _currentOrder = order;
          notifyListeners();
        }

        // Notify socket
        _socketService.acceptOrder(orderId);
        return true;
      }

      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reject order
  Future<bool> rejectOrder(String orderId, {String? reason}) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.post(
        '${AppConstants.rejectOrderEndpoint}/$orderId/reject',
        data: {'reason': reason},
      );

      final data = _apiService.handleResponse(response);

      if (data['success'] == true) {
        // Remove order from pending
        _pendingOrders.removeWhere((order) => order.id == orderId);
        notifyListeners();

        // Notify socket
        _socketService.rejectOrder(orderId, reason: reason);
        return true;
      }

      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.patch(
        '${AppConstants.ordersEndpoint}/$orderId/status',
        data: {'status': status},
      );

      final data = _apiService.handleResponse(response);

      if (data['success'] == true) {
        _updateOrderStatus(orderId, status);

        // Notify socket
        _socketService.updateOrderStatus(orderId, status);
        return true;
      }

      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get order details
  Future<Order?> getOrderDetails(String orderId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.get(
        '${AppConstants.ordersEndpoint}/$orderId',
      );

      final data = _apiService.handleResponse(response);

      if (data['order'] != null) {
        return Order.fromJson(data['order']);
      }

      return null;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get driver's orders
  Future<void> getDriverOrders() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.get(AppConstants.ordersEndpoint);
      final data = _apiService.handleResponse(response);

      if (data['orders'] != null) {
        final orders =
            (data['orders'] as List)
                .map((json) => Order.fromJson(json))
                .toList();

        // Separate orders by status
        _activeOrders =
            orders
                .where(
                  (order) =>
                      order.status == AppConstants.orderAccepted ||
                      order.status == AppConstants.orderDriverAssigned ||
                      order.status == AppConstants.orderDriverArrived ||
                      order.status == AppConstants.orderInProgress,
                )
                .toList();

        _completedOrders =
            orders
                .where((order) => order.status == AppConstants.orderCompleted)
                .toList();

        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Set current order
  void setCurrentOrder(Order? order) {
    _currentOrder = order;
    notifyListeners();
  }

  // Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
