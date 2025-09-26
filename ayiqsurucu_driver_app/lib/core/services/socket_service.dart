import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _authToken;
  bool _isConnected = false;

  // Stream controllers for real-time events
  final StreamController<Map<String, dynamic>> _newOrderController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _orderStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _driverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams
  Stream<Map<String, dynamic>> get newOrderStream => _newOrderController.stream;
  Stream<Map<String, dynamic>> get orderStatusStream =>
      _orderStatusController.stream;
  Stream<Map<String, dynamic>> get driverLocationStream =>
      _driverLocationController.stream;

  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  // Initialize socket connection
  void initialize({required String authToken}) {
    _authToken = authToken;
    _connect();
  }

  void _connect() {
    if (_authToken == null) return;

    try {
      _socket = IO.io(AppConstants.socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': _authToken},
      });

      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      print('Socket connection error: $e');
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      print('✅ Socket connected');
      _isConnected = true;
      _joinDriverRoom();
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket disconnected');
      _isConnected = false;
    });

    _socket!.onConnectError((error) {
      print('❌ Socket connection error: $error');
      _isConnected = false;
    });

    _socket!.onError((error) {
      print('❌ Socket error: $error');
    });

    // Business logic events
    _socket!.on(AppConstants.socketNewOrderEvent, (data) {
      print('📦 New order received: $data');
      _newOrderController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(AppConstants.socketOrderStatusEvent, (data) {
      print('📋 Order status updated: $data');
      _orderStatusController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(AppConstants.socketDriverLocationEvent, (data) {
      print('📍 Driver location updated: $data');
      _driverLocationController.add(Map<String, dynamic>.from(data));
    });

    // Order events
    _socket!.on('driver_assigned', (data) {
      print('👨‍💼 Driver assigned: $data');
      _orderStatusController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('order_completed', (data) {
      print('✅ Order completed: $data');
      _orderStatusController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('order_cancelled', (data) {
      print('❌ Order cancelled: $data');
      _orderStatusController.add(Map<String, dynamic>.from(data));
    });
  }

  void _joinDriverRoom() {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_driver_room');
      print('🏠 Joined driver room');
    }
  }

  // Send events to server
  void updateLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit(AppConstants.socketUpdateLocationEvent, {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      });
      print('📍 Location updated: $latitude, $longitude');
    }
  }

  void updateStatus({required bool isOnline, bool? isAvailable}) {
    if (_socket != null && _isConnected) {
      _socket!.emit(AppConstants.socketUpdateStatusEvent, {
        'isOnline': isOnline,
        'isAvailable': isAvailable,
      });
      print('🔄 Status updated: online=$isOnline, available=$isAvailable');
    }
  }

  void acceptOrder(String orderId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('order_accepted', {'orderId': orderId});
      print('✅ Order accepted: $orderId');
    }
  }

  void rejectOrder(String orderId, {String? reason}) {
    if (_socket != null && _isConnected) {
      _socket!.emit('order_rejected', {'orderId': orderId, 'reason': reason});
      print('❌ Order rejected: $orderId');
    }
  }

  void updateOrderStatus(
    String orderId,
    String status, {
    Map<String, dynamic>? data,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('order_status_updated', {
        'orderId': orderId,
        'status': status,
        ...?data,
      });
      print('📋 Order status updated: $orderId -> $status');
    }
  }

  void startTrackingOrder(String orderId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('track_order', {'orderId': orderId});
      print('👁️ Started tracking order: $orderId');
    }
  }

  void stopTrackingOrder(String orderId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('stop_tracking', {'orderId': orderId});
      print('🛑 Stopped tracking order: $orderId');
    }
  }

  // Reconnect with new token
  void reconnectWithToken(String newToken) {
    disconnect();
    _authToken = newToken;
    _connect();
  }

  // Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    print('🔌 Socket disconnected and disposed');
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _newOrderController.close();
    _orderStatusController.close();
    _driverLocationController.close();
  }

  // Check connection status
  bool get isSocketConnected => _socket?.connected ?? false;
}
