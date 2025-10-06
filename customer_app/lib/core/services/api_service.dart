import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late http.Client _client;
  String? _authToken;
  
  void initialize() {
    _client = http.Client();
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(AppConstants.tokenKey);
  }

  Future<void> _saveAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  // Expose a safe setter for test/mocked auth flows
  Future<void> setAuthToken(String token) async {
    await _saveAuthToken(token);
  }

  Future<void> _clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  void _logRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
  }) {
    if (!kDebugMode) return;
    debugPrint('[API] -> $method ${url.toString()}');
    if (headers != null) debugPrint('[API] Headers: ${jsonEncode(headers)}');
    if (body != null) {
      try {
        debugPrint('[API] Body: ${body is String ? body : jsonEncode(body)}');
      } catch (_) {
        debugPrint('[API] Body: <non-json body>');
      }
    }
  }

  void _logResponse({
    required Uri url,
    required int status,
    required String body,
  }) {
    if (!kDebugMode) return;
    debugPrint('[API] <- (${status}) ${url.toString()}');
    debugPrint('[API] Response: $body');
  }

  // Authentication Methods
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.sendOtpEndpoint}');
      final reqBody = jsonEncode({'phone': phone});
      _logRequest(method: 'POST', url: url, headers: _headers, body: reqBody);
      final response = await _client.post(url, headers: _headers, body: reqBody);
      _logResponse(url: url, status: response.statusCode, body: response.body);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to send OTP'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    String? name,
    String? email,
  }) async {
    try {
      final body = {
        'phone': phone,
        'otp': otp,
      };
      
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;

      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.verifyOtpEndpoint}');
      final reqBody = jsonEncode(body);
      _logRequest(method: 'POST', url: url, headers: _headers, body: reqBody);
      final response = await _client.post(url, headers: _headers, body: reqBody);
      _logResponse(url: url, status: response.statusCode, body: response.body);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        await _saveAuthToken(data['token']);
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to verify OTP'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
  }) async {
    try {
      final body = {'name': name};
      if (email != null) body['email'] = email;

      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.updateProfileEndpoint}');
      final reqBody = jsonEncode(body);
      _logRequest(method: 'PUT', url: url, headers: _headers, body: reqBody);
      final response = await _client.put(url, headers: _headers, body: reqBody);
      _logResponse(url: url, status: response.statusCode, body: response.body);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.userProfileEndpoint}');
      _logRequest(method: 'GET', url: url, headers: _headers);
      final response = await _client.get(url, headers: _headers);
      _logResponse(url: url, status: response.statusCode, body: response.body);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to get profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<void> logout() async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.logoutEndpoint}');
      _logRequest(method: 'POST', url: url, headers: _headers);
      final response = await _client.post(url, headers: _headers);
      _logResponse(url: url, status: response.statusCode, body: response.body);
    } catch (e) {
      if (kDebugMode) debugPrint('Logout error: $e');
    } finally {
      await _clearAuthToken();
    }
  }

  // Orders Methods
  Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'pickup': pickup,
        'destination': destination,
        'payment': {'method': paymentMethod},
      };
      
      if (notes != null) body['notes'] = notes;

      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.ordersEndpoint}');
      final reqBody = jsonEncode(body);
      _logRequest(method: 'POST', url: url, headers: _headers, body: reqBody);
      final response = await _client.post(url, headers: _headers, body: reqBody);
      _logResponse(url: url, status: response.statusCode, body: response.body);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'order': data['order']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to create order'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getOrders() async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.ordersEndpoint}');
      _logRequest(method: 'GET', url: url, headers: _headers);
      final response = await _client.get(url, headers: _headers);
      _logResponse(url: url, status: response.statusCode, body: response.body);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'orders': data['orders']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to get orders'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.ordersEndpoint}/$orderId');
      _logRequest(method: 'GET', url: url, headers: _headers);
      final response = await _client.get(url, headers: _headers);
      _logResponse(url: url, status: response.statusCode, body: response.body);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'order': data['order']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to get order'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId, {String? reason}) async {
    try {
      final body = <String, dynamic>{};
      if (reason != null) body['reason'] = reason;

      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.ordersEndpoint}/$orderId/cancel');
      final reqBody = jsonEncode(body);
      _logRequest(method: 'PUT', url: url, headers: _headers, body: reqBody);
      final response = await _client.put(url, headers: _headers, body: reqBody);
      _logResponse(url: url, status: response.statusCode, body: response.body);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'order': data['order']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to cancel order'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Utility Methods
  bool get isAuthenticated => _authToken != null;
  
  String? get authToken => _authToken;

  void dispose() {
    _client.close();
  }
}