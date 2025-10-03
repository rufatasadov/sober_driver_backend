import 'dart:convert';
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

  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.sendOtpEndpoint}'),
        headers: _headers,
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    String? name,
  }) async {
    try {
      final body = {
        'phone': phone,
        'otp': otp,
        if (name != null) 'name': name,
      };

      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.verifyOtpEndpoint}'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      final result = _handleResponse(response);
      
      // Save token if login successful
      if (result['success'] && result['token'] != null) {
        await setAuthToken(result['token']);
      }
      
      return result;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
    required String paymentMethod,
    String? notes,
    String? customerPhone,
    String? customerName,
  }) async {
    try {
      final body = {
        'pickup': pickup,
        'destination': destination,
        'payment': {'method': paymentMethod},
        if (notes != null) 'notes': notes,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (customerName != null) 'customerName': customerName,
      };

      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.ordersEndpoint}'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getOrders() async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.ordersEndpoint}'),
        headers: _headers,
      ).timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.ordersEndpoint}/$orderId'),
        headers: _headers,
      ).timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId, {String? reason}) async {
    try {
      final body = {
        'status': 'cancelled',
        if (reason != null) 'cancellationReason': reason,
      };

      final response = await _client.patch(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.ordersEndpoint}/$orderId/status'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.userProfileEndpoint}'),
        headers: _headers,
      ).timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;

      final response = await _client.put(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.updateProfileEndpoint}'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async {
    try {
      final response = await _client.put(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.fcmTokenEndpoint}'),
        headers: _headers,
        body: jsonEncode({'fcmToken': fcmToken}),
      ).timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.logoutEndpoint}'),
        headers: _headers,
      ).timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      await clearAuthToken();
      return _handleResponse(response);
    } catch (e) {
      await clearAuthToken();
      return {'success': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          ...data,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Unknown error occurred',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to parse response: $e',
        'statusCode': response.statusCode,
      };
    }
  }

  void dispose() {
    _client.close();
  }
}
