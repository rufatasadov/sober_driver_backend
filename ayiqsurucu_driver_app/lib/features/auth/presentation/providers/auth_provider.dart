import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _driver;
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get driver => _driver;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isDriver => _driver != null;

  // Initialize auth state from stored data
  Future<void> checkAuthStatus() async {
    try {
      _setLoading(true);

      final storedToken = await _apiService.getStoredToken();
      if (storedToken != null) {
        _token = storedToken;

        // Load user data from storage
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(AppConstants.userKey);
        final driverJson = prefs.getString(AppConstants.driverKey);

        if (userJson != null) {
          _user = Map<String, dynamic>.from(Uri.splitQueryString(userJson));
        }

        if (driverJson != null) {
          _driver = Map<String, dynamic>.from(Uri.splitQueryString(driverJson));
        }
      }
    } catch (e) {
      _setError('Auth status check failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Send OTP
  Future<bool> sendOtp(String phone) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.post(
        AppConstants.sendOtpEndpoint,
        data: {'phone': phone},
      );

      final data = _apiService.handleResponse(response);
      return data['message'] != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify OTP and login
  Future<bool> verifyOtp({
    required String phone,
    required String otp,
    String? name,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.post(
        AppConstants.verifyOtpEndpoint,
        data: {'phone': phone, 'otp': otp, if (name != null) 'name': name},
      );

      final data = _apiService.handleResponse(response);

      if (data['token'] != null) {
        _token = data['token'];
        _user = data['user'];

        // Store auth data
        await _storeAuthData();

        // Set token in API service
        await _apiService.setAuthToken(_token!);

        notifyListeners();
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

  // Driver login with username/password
  Future<bool> driverLogin({
    required String username,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.post(
        AppConstants.driverLoginEndpoint,
        data: {'username': username, 'password': password},
      );

      final data = _apiService.handleResponse(response);

      if (data['token'] != null) {
        _token = data['token'];
        _user = data['user'];

        // Store auth data
        await _storeAuthData();

        // Set token in API service
        await _apiService.setAuthToken(_token!);

        notifyListeners();
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

  // Create user account (for direct registration)
  Future<bool> createUserAccount({
    required String name,
    required String phone,
    required String username,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.post(
        AppConstants.createUserEndpoint,
        data: {
          'name': name,
          'phone': phone,
          'username': username,
          'password': password,
          'role': 'driver',
        },
      );

      final data = _apiService.handleResponse(response);

      if (data['token'] != null) {
        _token = data['token'];
        _user = data['user'];

        // Store auth data
        await _storeAuthData();

        // Set token in API service
        await _apiService.setAuthToken(_token!);

        notifyListeners();
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

  // Driver registration
  Future<bool> registerDriver({
    required String licenseNumber,
    required Map<String, dynamic> vehicleInfo,
    Map<String, dynamic>? documents,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.post(
        AppConstants.driverRegisterEndpoint,
        data: {
          'licenseNumber': licenseNumber,
          'vehicleInfo': vehicleInfo,
          if (documents != null) 'documents': documents,
        },
      );

      final data = _apiService.handleResponse(response);

      if (data['driver'] != null) {
        _driver = data['driver'];
        await _storeDriverData();
        notifyListeners();
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

  // Get driver profile
  Future<bool> getDriverProfile() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.get(
        AppConstants.driverProfileEndpoint,
      );
      final data = _apiService.handleResponse(response);

      if (data['driver'] != null) {
        _driver = data['driver'];
        await _storeDriverData();
        notifyListeners();
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

  // Update driver status
  Future<bool> updateDriverStatus({
    required bool isOnline,
    bool? isAvailable,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.patch(
        AppConstants.driverStatusEndpoint,
        data: {
          'isOnline': isOnline,
          if (isAvailable != null) 'isAvailable': isAvailable,
        },
      );

      final data = _apiService.handleResponse(response);

      if (data['driver'] != null && _driver != null) {
        _driver!['isOnline'] = data['driver']['isOnline'];
        _driver!['isAvailable'] = data['driver']['isAvailable'];
        await _storeDriverData();
        notifyListeners();
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

  // Update driver location
  Future<bool> updateLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final response = await _apiService.patch(
        AppConstants.driverLocationEndpoint,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (address != null) 'address': address,
        },
      );

      final data = _apiService.handleResponse(response);
      return data['message'] != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _setLoading(true);

      // Clear API token
      await _apiService.clearAuthToken();

      // Clear local data
      _token = null;
      _user = null;
      _driver = null;

      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userKey);
      await prefs.remove(AppConstants.driverKey);

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Store auth data locally
  Future<void> _storeAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, _token!);
    if (_user != null) {
      await prefs.setString(AppConstants.userKey, _user.toString());
    }
  }

  // Store driver data locally
  Future<void> _storeDriverData() async {
    if (_driver != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.driverKey, _driver.toString());
    }
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

  // Clear error manually
  void clearError() {
    _clearError();
  }
}
