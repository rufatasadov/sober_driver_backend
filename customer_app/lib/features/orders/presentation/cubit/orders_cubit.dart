import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/models/order_model.dart';

// States
abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<OrderModel> orders;

  const OrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderCreated extends OrdersState {
  final OrderModel order;

  const OrderCreated(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderTracking extends OrdersState {
  final OrderModel order;

  const OrderTracking(this.order);

  @override
  List<Object?> get props => [order];
}

class OrdersError extends OrdersState {
  final String message;

  const OrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

// Events
abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrdersEvent extends OrdersEvent {}

class CreateOrderEvent extends OrdersEvent {
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> destination;
  final String paymentMethod;
  final String? notes;

  const CreateOrderEvent({
    required this.pickup,
    required this.destination,
    required this.paymentMethod,
    this.notes,
  });

  @override
  List<Object?> get props => [pickup, destination, paymentMethod, notes];
}

class TrackOrderEvent extends OrdersEvent {
  final String orderId;

  const TrackOrderEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class CancelOrderEvent extends OrdersEvent {
  final String orderId;
  final String? reason;

  const CancelOrderEvent(this.orderId, {this.reason});

  @override
  List<Object?> get props => [orderId, reason];
}

// Cubit
class OrdersCubit extends Cubit<OrdersState> {
  final ApiService _apiService = ApiService();

  OrdersCubit() : super(OrdersInitial());

  Future<void> loadOrders() async {
    try {
      emit(OrdersLoading());

      final response = await _apiService.getOrders();
      
      if (response['success']) {
        final orders = (response['orders'] as List)
            .map((order) => OrderModel.fromJson(order))
            .toList();
        emit(OrdersLoaded(orders));
      } else {
        emit(OrdersError(response['error'] ?? 'Failed to load orders'));
      }
    } catch (e) {
      emit(OrdersError('Failed to load orders: ${e.toString()}'));
    }
  }

  Future<void> createOrder({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      emit(OrdersLoading());

      // TEMPORARY: Skip API call for testing
      // Simulate successful order creation
      await Future.delayed(const Duration(seconds: 2));
      
      // Create a mock order for testing
      final mockOrder = OrderModel(
        id: 'test-order-${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        customerId: 'test-user-id',
        pickup: pickup,
        destination: destination,
        status: 'pending',
        estimatedTime: 15,
        estimatedDistance: 5.2,
        fare: {
          'total': 8.50,
          'currency': 'AZN',
          'base': 3.00,
          'distance': 3.50,
          'time': 2.00,
        },
        payment: {
          'method': paymentMethod,
          'status': 'pending',
        },
        timeline: [
          {
            'status': 'pending',
            'timestamp': DateTime.now().toIso8601String(),
            'description': 'Sifariş yaradıldı',
          },
        ],
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      emit(OrderCreated(mockOrder));
      
      // Original API code (commented out for now):
      // final response = await _apiService.createOrder(
      //   pickup: pickup,
      //   destination: destination,
      //   paymentMethod: paymentMethod,
      //   notes: notes,
      // );
      // 
      // if (response['success']) {
      //   final order = OrderModel.fromJson(response['order']);
      //   emit(OrderCreated(order));
      // } else {
      //   emit(OrdersError(response['error'] ?? 'Failed to create order'));
      // }
    } catch (e) {
      emit(OrdersError('Failed to create order: ${e.toString()}'));
    }
  }

  Future<void> trackOrder(String orderId) async {
    try {
      emit(OrdersLoading());

      final response = await _apiService.getOrderById(orderId);
      
      if (response['success']) {
        final order = OrderModel.fromJson(response['order']);
        emit(OrderTracking(order));
      } else {
        emit(OrdersError(response['error'] ?? 'Failed to load order'));
      }
    } catch (e) {
      emit(OrdersError('Failed to track order: ${e.toString()}'));
    }
  }

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      emit(OrdersLoading());

      final response = await _apiService.cancelOrder(orderId, reason: reason);
      
      if (response['success']) {
        // Reload orders after cancellation
        await loadOrders();
      } else {
        emit(OrdersError(response['error'] ?? 'Failed to cancel order'));
      }
    } catch (e) {
      emit(OrdersError('Failed to cancel order: ${e.toString()}'));
    }
  }
}
