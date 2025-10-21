import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/constants/app_constants.dart';

// Order Model
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
  final Map<String, dynamic>? customer;
  final String? customerPhone;
  final int? etaMinutes;

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
    this.customer,
    this.customerPhone,
    this.etaMinutes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    print('Order.fromJson: Parsing order data: $json');

    final orderId = json['id']?.toString() ?? '';
    print('Order.fromJson: Parsed order ID: $orderId');

    return Order(
      id: orderId,
      orderNumber: json['orderNumber'] ?? '',
      customerId: json['customerId'] ?? '',
      driverId: json['driverId'],
      pickup: json['pickup'] ?? {},
      destination: json['destination'] ?? {},
      status: json['status'] ?? '',
      estimatedTime: json['estimatedTime']?.toDouble(),
      estimatedDistance: double.tryParse(json['estimatedDistance'] ?? "0.0"),
      fare: _parseFare(json['fare']),
      paymentMethod: json['paymentMethod'] ?? '',
      notes: json['notes'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      customer: json['customer'],
      customerPhone: json['customer']?['phone'] ?? json['customerPhone'],
      etaMinutes: json['etaMinutes'],
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
      'customer': customer,
      'customerPhone': customerPhone,
      'etaMinutes': etaMinutes,
    };
  }

  // Helper method to parse fare from different formats
  static double _parseFare(dynamic fare) {
    if (fare == null) return 0.0;

    if (fare is double) return fare;
    if (fare is int) return fare.toDouble();
    if (fare is String) {
      return double.tryParse(fare) ?? 0.0;
    }
    if (fare is Map<String, dynamic>) {
      // If fare is an object, try to get total or amount
      final total = fare['total'] ?? fare['amount'] ?? fare['fare'];
      if (total is double) return total;
      if (total is int) return total.toDouble();
      if (total is String) {
        return double.tryParse(total) ?? 0.0;
      }
    }

    return 0.0;
  }
}

// Orders States
abstract class OrdersState {}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> pendingOrders;
  final List<Order> activeOrders;
  final List<Order> completedOrders;

  OrdersLoaded({
    required this.pendingOrders,
    required this.activeOrders,
    required this.completedOrders,
  });
}

class OrdersError extends OrdersState {
  final String message;

  OrdersError(this.message);
}

// Orders Cubit
class OrdersCubit extends Cubit<OrdersState> {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  StreamSubscription? _newOrderSubscription;

  // Callback for new order notifications
  Function(Order)? _newOrderCallback;

  // Callback for order assigned notifications
  Function(Order)? _orderAssignedCallback;

  // Callback for dashboard refresh after order completion
  VoidCallback? _dashboardRefreshCallback;

  // Callback for broadcast order notifications
  Function(Order)? _broadcastOrderCallback;

  OrdersCubit() : super(OrdersInitial()) {
    // Initialize socket listeners after a delay to ensure socket is connected
    Future.delayed(const Duration(seconds: 2), () {
      _initializeSocketListeners();
    });
  }

  // Getters
  bool get isLoading => state is OrdersLoading;
  String? get error =>
      state is OrdersError ? (state as OrdersError).message : null;
  List<Order> get pendingOrders =>
      state is OrdersLoaded ? (state as OrdersLoaded).pendingOrders : [];
  List<Order> get activeOrders =>
      state is OrdersLoaded ? (state as OrdersLoaded).activeOrders : [];
  List<Order> get completedOrders =>
      state is OrdersLoaded ? (state as OrdersLoaded).completedOrders : [];

  // Initialize orders
  Future<void> initialize() async {
    await getDriverOrders();
  }

  // Get driver orders
  Future<void> getDriverOrders() async {
    try {
      print('OrdersCubit: Getting driver orders...');
      emit(OrdersLoading());

      final response = await _apiService.get(AppConstants.recentOrdersEndpoint);
      print('OrdersCubit: API response: $response');

      final data = _apiService.handleResponse(response);
      print('OrdersCubit: Parsed data: $data');

      // Convert to Map safely
      Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);

      if (dataMap['orders'] != null && dataMap['orders'] is List) {
        print(
          'OrdersCubit: Found ${(dataMap['orders'] as List).length} orders',
        );

        final orders =
            (dataMap['orders'] as List)
                .map((order) => Order.fromJson(order))
                .toList();

        // Categorize orders by status
        final pendingOrders =
            orders.where((order) => order.status == 'pending').toList();
        final activeOrders =
            orders
                .where(
                  (order) =>
                      order.status == 'accepted' ||
                      order.status == 'in_progress' ||
                      order.status == 'driver_assigned' ||
                      order.status == 'driver_arrived',
                )
                .toList();
        final completedOrders =
            orders
                .where(
                  (order) =>
                      order.status == 'completed' ||
                      order.status == 'cancelled',
                )
                .toList();

        print(
          'OrdersCubit: Categorized orders - Pending: ${pendingOrders.length}, Active: ${activeOrders.length}, Completed: ${completedOrders.length}',
        );

        emit(
          OrdersLoaded(
            pendingOrders: pendingOrders,
            activeOrders: activeOrders,
            completedOrders: completedOrders,
          ),
        );
      } else {
        emit(
          OrdersLoaded(
            pendingOrders: [],
            activeOrders: [],
            completedOrders: [],
          ),
        );
      }
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  // Accept order
  Future<bool> acceptOrder(String orderId) async {
    try {
      print('OrdersCubit: Accepting order with ID: $orderId');

      if (orderId.isEmpty) {
        print('OrdersCubit: Order ID is empty!');
        emit(OrdersError('Order ID is empty'));
        return false;
      }

      emit(OrdersLoading());

      final endpoint = '${AppConstants.acceptOrderEndpoint}/$orderId/accept';
      print('OrdersCubit: API endpoint: $endpoint');

      final response = await _apiService.post(endpoint);

      print('OrdersCubit: Accept order response: $response');
      final data = _apiService.handleResponse(response);

      // Convert to Map safely
      Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);

      if (dataMap['message'] != null || dataMap['order'] != null) {
        // Refresh orders
        await getDriverOrders();
        return true;
      }

      emit(OrdersError('Failed to accept order'));
      return false;
    } catch (e) {
      print('OrdersCubit: Error accepting order: $e');
      emit(OrdersError(e.toString()));
      return false;
    }
  }

  // Reject order
  Future<bool> rejectOrder(String orderId) async {
    try {
      print('OrdersCubit: Rejecting order with ID: $orderId');

      if (orderId.isEmpty) {
        print('OrdersCubit: Order ID is empty!');
        emit(OrdersError('Order ID is empty'));
        return false;
      }

      emit(OrdersLoading());

      final endpoint = '${AppConstants.rejectOrderEndpoint}/$orderId/reject';
      print('OrdersCubit: API endpoint: $endpoint');

      final response = await _apiService.post(endpoint);

      print('OrdersCubit: Reject order response: $response');
      final data = _apiService.handleResponse(response);

      // Convert to Map safely
      Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);

      if (dataMap['message'] != null) {
        // Refresh orders
        await getDriverOrders();
        return true;
      }

      emit(OrdersError('Failed to reject order'));
      return false;
    } catch (e) {
      print('OrdersCubit: Error rejecting order: $e');
      emit(OrdersError(e.toString()));
      return false;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
    String? notes,
  }) async {
    try {
      emit(OrdersLoading());

      final response = await _apiService.patch(
        '${AppConstants.ordersEndpoint}/$orderId/status',
        data: {'status': status, if (notes != null) 'notes': notes},
      );

      final data = _apiService.handleResponse(response);

      // Convert to Map safely
      Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);

      if (response.statusCode == 200 || dataMap['success'] == true) {
        // Refresh orders
        await getDriverOrders();
        return true;
      }

      emit(OrdersError('Failed to update order status'));
      return false;
    } catch (e) {
      emit(OrdersError(e.toString()));
      return false;
    }
  }

  // Start order
  Future<bool> startOrder(String orderId) async {
    return await updateOrderStatus(orderId: orderId, status: 'in_progress');
  }

  // Complete order
  Future<bool> completeOrder(String orderId) async {
    try {
      final success = await updateOrderStatus(
        orderId: orderId,
        status: 'completed',
      );

      if (success) {
        // Update driver status to available after completing order
        final socketService = SocketService();
        socketService.updateStatus(isOnline: true, isAvailable: true);
        print(
          'OrdersCubit: Driver status updated to available after completing order',
        );

        // Refresh dashboard data to update balance information
        // This will trigger a refresh of the balance display
        _refreshDashboardData();
      }

      return success;
    } catch (e) {
      print('OrdersCubit: Error completing order: $e');
      return false;
    }
  }

  // Refresh dashboard data after order completion
  void _refreshDashboardData() {
    try {
      print(
        'OrdersCubit: Triggering dashboard data refresh for balance update',
      );

      // Call the dashboard refresh callback if it's set
      if (_dashboardRefreshCallback != null) {
        _dashboardRefreshCallback!();
        print('OrdersCubit: Dashboard refresh callback executed');
      } else {
        print('OrdersCubit: No dashboard refresh callback set');
      }
    } catch (e) {
      print('OrdersCubit: Error refreshing dashboard data: $e');
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      final success = await updateOrderStatus(
        orderId: orderId,
        status: 'cancelled',
        notes: reason,
      );

      if (success) {
        // Update driver status to available after cancelling order
        final socketService = SocketService();
        socketService.updateStatus(isOnline: true, isAvailable: true);
        print(
          'OrdersCubit: Driver status updated to available after cancelling order',
        );

        // Refresh dashboard data to update balance information
        _refreshDashboardData();
      }

      return success;
    } catch (e) {
      print('OrdersCubit: Error cancelling order: $e');
      return false;
    }
  }

  // Get order by ID
  Order? getOrderById(String orderId) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      final allOrders = [
        ...currentState.pendingOrders,
        ...currentState.activeOrders,
        ...currentState.completedOrders,
      ];
      try {
        return allOrders.firstWhere((order) => order.id == orderId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Refresh orders
  Future<void> refresh() async {
    await getDriverOrders();
  }

  // Set callback for new order notifications
  void setNewOrderCallback(Function(Order) callback) {
    _newOrderCallback = callback;
  }

  // Set callback for broadcast order notifications
  void setOrderAssignedCallback(Function(Order) callback) {
    _orderAssignedCallback = callback;
  }

  void setDashboardRefreshCallback(VoidCallback callback) {
    _dashboardRefreshCallback = callback;
  }

  void setBroadcastOrderCallback(Function(Order) callback) {
    _broadcastOrderCallback = callback;
  }

  // Initialize socket listeners
  void _initializeSocketListeners() {
    print('OrdersCubit: Initializing socket listeners...');
    print('OrdersCubit: Socket connected: ${_socketService.isConnected}');

    _newOrderSubscription = _socketService.newOrderStream.listen((orderData) {
      print('OrdersCubit: New order received via socket: $orderData');
      _handleNewOrder(orderData);
    });

    // Listen for broadcast orders
    _socketService.broadcastOrderStream.listen((orderData) {
      print('OrdersCubit: Broadcast order received via socket: $orderData');
      _handleBroadcastOrder(orderData);
    });

    // Listen for orders assigned by operator
    _socketService.orderAssignedStream.listen((orderData) {
      print('OrdersCubit: Order assigned by operator: $orderData');
      _handleOrderAssigned(orderData);
    });

    // Listen for orders accepted by other drivers
    _socketService.orderAcceptedByOtherStream.listen((data) {
      print('OrdersCubit: Order accepted by other driver: $data');
      _handleOrderAcceptedByOther(data);
    });

    print('OrdersCubit: Socket listeners initialized');
  }

  // Handle new order from socket
  void _handleNewOrder(Map<String, dynamic> orderData) {
    try {
      final newOrder = Order.fromJson(orderData);

      // Call the callback to show notification
      if (_newOrderCallback != null) {
        print(
          'OrdersCubit: Calling new order callback for: ${newOrder.orderNumber}',
        );
        _newOrderCallback!(newOrder);
      }

      if (state is OrdersLoaded) {
        final currentState = state as OrdersLoaded;
        final updatedPendingOrders = List<Order>.from(
          currentState.pendingOrders,
        );

        // Check if order already exists
        final existingIndex = updatedPendingOrders.indexWhere(
          (order) => order.id == newOrder.id,
        );
        if (existingIndex == -1) {
          // Add new order to pending orders
          updatedPendingOrders.add(newOrder);

          emit(
            OrdersLoaded(
              pendingOrders: updatedPendingOrders,
              activeOrders: currentState.activeOrders,
              completedOrders: currentState.completedOrders,
            ),
          );

          print(
            'OrdersCubit: New order added to pending orders: ${newOrder.orderNumber}',
          );
        }
      } else {
        // If not loaded, refresh orders
        getDriverOrders();
      }
    } catch (e) {
      print('OrdersCubit: Error handling new order: $e');
    }
  }

  // Handle order assigned by operator
  void _handleOrderAssigned(Map<String, dynamic> orderData) {
    try {
      final assignedOrder = Order.fromJson(orderData);

      // Call the callback to show notification
      if (_orderAssignedCallback != null) {
        print(
          'OrdersCubit: Calling order assigned callback for: ${assignedOrder.orderNumber}',
        );
        _orderAssignedCallback!(assignedOrder);
      }

      if (state is OrdersLoaded) {
        final currentState = state as OrdersLoaded;
        final updatedActiveOrders = List<Order>.from(currentState.activeOrders);

        // Check if order already exists
        final existingIndex = updatedActiveOrders.indexWhere(
          (order) => order.id == assignedOrder.id,
        );
        if (existingIndex == -1) {
          // Add new assigned order to active orders
          updatedActiveOrders.add(assignedOrder);

          emit(
            OrdersLoaded(
              pendingOrders: currentState.pendingOrders,
              activeOrders: updatedActiveOrders,
              completedOrders: currentState.completedOrders,
            ),
          );

          print(
            'OrdersCubit: Assigned order added to active orders: ${assignedOrder.orderNumber}',
          );
        }
      } else {
        // If not loaded, refresh orders
        getDriverOrders();
      }
    } catch (e) {
      print('OrdersCubit: Error handling assigned order: $e');
    }
  }

  // Handle broadcast order from socket
  void _handleBroadcastOrder(Map<String, dynamic> orderData) {
    try {
      final broadcastOrder = Order.fromJson(orderData);

      // Call the callback to show broadcast notification
      if (_broadcastOrderCallback != null) {
        print(
          'OrdersCubit: Calling broadcast order callback for: ${broadcastOrder.orderNumber}',
        );
        _broadcastOrderCallback!(broadcastOrder);
      }

      if (state is OrdersLoaded) {
        final currentState = state as OrdersLoaded;
        final updatedPendingOrders = List<Order>.from(
          currentState.pendingOrders,
        );

        // Check if order already exists
        final existingIndex = updatedPendingOrders.indexWhere(
          (order) => order.id == broadcastOrder.id,
        );
        if (existingIndex == -1) {
          // Add new broadcast order to pending orders
          updatedPendingOrders.add(broadcastOrder);

          emit(
            OrdersLoaded(
              pendingOrders: updatedPendingOrders,
              activeOrders: currentState.activeOrders,
              completedOrders: currentState.completedOrders,
            ),
          );

          print(
            'OrdersCubit: Broadcast order added to pending orders: ${broadcastOrder.orderNumber}',
          );
        }
      } else {
        // If not loaded, refresh orders
        getDriverOrders();
      }
    } catch (e) {
      print('OrdersCubit: Error handling broadcast order: $e');
    }
  }

  // Handle order accepted by other driver
  void _handleOrderAcceptedByOther(Map<String, dynamic> data) {
    try {
      final orderId = data['orderId']?.toString();
      if (orderId == null) return;

      print('OrdersCubit: Order $orderId accepted by other driver');

      if (state is OrdersLoaded) {
        final currentState = state as OrdersLoaded;
        final updatedPendingOrders = List<Order>.from(
          currentState.pendingOrders,
        );

        // Remove the order from pending orders
        updatedPendingOrders.removeWhere((order) => order.id == orderId);

        emit(
          OrdersLoaded(
            pendingOrders: updatedPendingOrders,
            activeOrders: currentState.activeOrders,
            completedOrders: currentState.completedOrders,
          ),
        );

        print('OrdersCubit: Order $orderId removed from pending orders');
      }
    } catch (e) {
      print('OrdersCubit: Error handling order accepted by other: $e');
    }
  }

  @override
  Future<void> close() {
    _newOrderSubscription?.cancel();
    return super.close();
  }
}
