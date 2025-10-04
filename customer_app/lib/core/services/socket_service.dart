import 'dart:async';
import 'dart:convert';
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
  final StreamController<Map<String, dynamic>> _orderCompletedController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get orderStatusStream => _orderStatusController.stream;
  Stream<Map<String, dynamic>> get driverLocationStream => _driverLocationController.stream;
  Stream<Map<String, dynamic>> get driverAssignedStream => _driverAssignedController.stream;
  Stream<Map<String, dynamic>> get orderCompletedStream => _orderCompletedController.stream;

  bool get isConnected => _isConnected;

  void initialize({String? authToken}) {
    _authToken = authToken;
    
    if (_socket != null) {
      _socket!.disconnect();
    }

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _setupEventListeners();
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      print('Socket connected');
      _isConnected = true;
      
      // Send auth token if available
      if (_authToken != null) {
        _socket!.emit('authenticate', {'token': _authToken});
      }
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      _isConnected = false;
    });

    _socket!.onConnectError((error) {
      print('Socket connection error: $error');
      _isConnected = false;
    });

    // Order status changes
    _socket!.on(AppConstants.socketOrderStatusEvent, (data) {
      print('Order status changed: $data');
      try {
        if (data is Map<String, dynamic>) {
          _orderStatusController.add(data);
        } else if (data is String) {
          final Map<String, dynamic> jsonData = jsonDecode(data);
          _orderStatusController.add(jsonData);
        }
      } catch (e) {
        print('Error parsing order status data: $e');
      }
    });

    // Driver location updates
    _socket!.on(AppConstants.socketDriverLocationEvent, (data) {
      print('Driver location updated: $data');
      try {
        if (data is Map<String, dynamic>) {
          _driverLocationController.add(data);
        } else if (data is String) {
          final Map<String, dynamic> jsonData = jsonDecode(data);
          _driverLocationController.add(jsonData);
        }
      } catch (e) {
        print('Error parsing driver location data: $e');
      }
    });

    // Driver assigned to order
    _socket!.on('driver_assigned', (data) {
      print('Driver assigned: $data');
      try {
        if (data is Map<String, dynamic>) {
          _driverAssignedController.add(data);
        } else if (data is String) {
          final Map<String, dynamic> jsonData = jsonDecode(data);
          _driverAssignedController.add(jsonData);
        }
      } catch (e) {
        print('Error parsing driver assigned data: $e');
      }
    });

    // Order completed
    _socket!.on('order_completed', (data) {
      print('Order completed: $data');
      try {
        if (data is Map<String, dynamic>) {
          _orderCompletedController.add(data);
        } else if (data is String) {
          final Map<String, dynamic> jsonData = jsonDecode(data);
          _orderCompletedController.add(jsonData);
        }
      } catch (e) {
        print('Error parsing order completed data: $e');
      }
    });

    // Order accepted
    _socket!.on(AppConstants.socketOrderAcceptedEvent, (data) {
      print('Order accepted: $data');
      try {
        if (data is Map<String, dynamic>) {
          _driverAssignedController.add(data);
        } else if (data is String) {
          final Map<String, dynamic> jsonData = jsonDecode(data);
          _driverAssignedController.add(jsonData);
        }
      } catch (e) {
        print('Error parsing order accepted data: $e');
      }
    });

    // Order rejected
    _socket!.on(AppConstants.socketOrderRejectedEvent, (data) {
      print('Order rejected: $data');
      try {
        if (data is Map<String, dynamic>) {
          _orderStatusController.add({
            'status': 'rejected',
            'orderId': data['orderId'],
            'reason': data['reason'],
          });
        } else if (data is String) {
          final Map<String, dynamic> jsonData = jsonDecode(data);
          _orderStatusController.add({
            'status': 'rejected',
            'orderId': jsonData['orderId'],
            'reason': jsonData['reason'],
          });
        }
      } catch (e) {
        print('Error parsing order rejected data: $e');
      }
    });
  }

  // Send events to server
  void trackOrder(String orderId) {
    if (_socket != null && _isConnected) {
      _socket!.emit(AppConstants.socketTrackOrderEvent, {'orderId': orderId});
    }
  }

  void stopTrackingOrder(String orderId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('stop_tracking_order', {'orderId': orderId});
    }
  }

  void sendLocationUpdate({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('update_location', {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
      });
    }
  }

  void updateAuthToken(String token) {
    _authToken = token;
    
    if (_socket != null && _isConnected) {
      _socket!.emit('authenticate', {'token': token});
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
    _orderCompletedController.close();
  }
}
