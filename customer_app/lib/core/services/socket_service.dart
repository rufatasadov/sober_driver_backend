import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  String? _authToken;

  // Stream controllers for different events
  final StreamController<Map<String, dynamic>> _orderStatusController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _driverLocationController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _driverAssignedController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _orderAcceptedController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _orderRejectedController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get orderStatusStream => _orderStatusController.stream;
  Stream<Map<String, dynamic>> get driverLocationStream => _driverLocationController.stream;
  Stream<Map<String, dynamic>> get driverAssignedStream => _driverAssignedController.stream;
  Stream<Map<String, dynamic>> get orderAcceptedStream => _orderAcceptedController.stream;
  Stream<Map<String, dynamic>> get orderRejectedStream => _orderRejectedController.stream;

  bool get isConnected => _isConnected;

  void initialize({required String authToken}) {
    _authToken = authToken;
    _connect();
  }

  void _connect() {
    try {
      _socket = io.io(
        AppConstants.socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'Authorization': 'Bearer $_authToken'})
            .build(),
      );

      _socket!.onConnect((_) {
        print('Socket connected');
        _isConnected = true;
        _setupEventListeners();
      });

      _socket!.onDisconnect((_) {
        print('Socket disconnected');
        _isConnected = false;
      });

      _socket!.onConnectError((error) {
        print('Socket connection error: $error');
        _isConnected = false;
      });

      _socket!.onError((error) {
        print('Socket error: $error');
      });

      _socket!.connect();
    } catch (e) {
      print('Socket initialization error: $e');
    }
  }

  void _setupEventListeners() {
    // Order status changes
    _socket!.on(AppConstants.socketOrderStatusEvent, (data) {
      print('Order status changed: $data');
      _orderStatusController.add(Map<String, dynamic>.from(data));
    });

    // Driver location updates
    _socket!.on(AppConstants.socketDriverLocationEvent, (data) {
      print('Driver location updated: $data');
      _driverLocationController.add(Map<String, dynamic>.from(data));
    });

    // Driver assigned to order
    _socket!.on(AppConstants.socketOrderAcceptedEvent, (data) {
      print('Order accepted: $data');
      _orderAcceptedController.add(Map<String, dynamic>.from(data));
    });

    // Order rejected
    _socket!.on(AppConstants.socketOrderRejectedEvent, (data) {
      print('Order rejected: $data');
      _orderRejectedController.add(Map<String, dynamic>.from(data));
    });

    // New order available (for drivers)
    _socket!.on(AppConstants.socketNewOrderEvent, (data) {
      print('New order available: $data');
      // This is mainly for drivers, but we can handle it if needed
    });
  }

  // Methods to emit events
  void trackOrder(String orderId) {
    if (_isConnected) {
      _socket!.emit(AppConstants.socketTrackOrderEvent, {'orderId': orderId});
    }
  }

  void stopTrackingOrder(String orderId) {
    if (_isConnected) {
      _socket!.emit('stop_track_order', {'orderId': orderId});
    }
  }

  void joinOrderRoom(String orderId) {
    if (_isConnected) {
      _socket!.emit('join_order_room', {'orderId': orderId});
    }
  }

  void leaveOrderRoom(String orderId) {
    if (_isConnected) {
      _socket!.emit('leave_order_room', {'orderId': orderId});
    }
  }

  // Utility methods
  void reconnect() {
    if (!_isConnected) {
      _connect();
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
    }
  }

  void dispose() {
    disconnect();
    _orderStatusController.close();
    _driverLocationController.close();
    _driverAssignedController.close();
    _orderAcceptedController.close();
    _orderRejectedController.close();
  }
}