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

  OrdersCubit() : super(OrdersInitial());

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
      emit(OrdersLoading());

      final response = await _apiService.get(AppConstants.recentOrdersEndpoint);
      final data = _apiService.handleResponse(response);

      if (data['orders'] != null) {
        final orders =
            (data['orders'] as List)
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
                      order.status == 'in_progress',
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
      emit(OrdersLoading());

      final response = await _apiService.patch(
        '${AppConstants.ordersEndpoint}/$orderId/accept',
      );

      final data = _apiService.handleResponse(response);

      if (data['success'] == true) {
        // Refresh orders
        await getDriverOrders();
        return true;
      }

      emit(OrdersError('Failed to accept order'));
      return false;
    } catch (e) {
      emit(OrdersError(e.toString()));
      return false;
    }
  }

  // Reject order
  Future<bool> rejectOrder(String orderId) async {
    try {
      emit(OrdersLoading());

      final response = await _apiService.patch(
        '${AppConstants.ordersEndpoint}/$orderId/reject',
      );

      final data = _apiService.handleResponse(response);

      if (data['success'] == true) {
        // Refresh orders
        await getDriverOrders();
        return true;
      }

      emit(OrdersError('Failed to reject order'));
      return false;
    } catch (e) {
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

      if (data['success'] == true) {
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
    return await updateOrderStatus(orderId: orderId, status: 'completed');
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    return await updateOrderStatus(
      orderId: orderId,
      status: 'cancelled',
      notes: reason,
    );
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
}
