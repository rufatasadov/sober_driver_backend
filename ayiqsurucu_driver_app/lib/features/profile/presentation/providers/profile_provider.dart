import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_constants.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _driver;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get driver => _driver;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load profile data
  Future<void> loadProfile() async {
    try {
      _setLoading(true);
      _clearError();

      // Load user profile
      final userResponse = await _apiService.get('/auth/me');
      final userData = _apiService.handleResponse(userResponse);
      _user = userData['user'];

      // Load driver profile (only if user is a driver)
      if (_user?['role'] == 'driver') {
        try {
          final driverResponse = await _apiService.get(
            AppConstants.driverProfileEndpoint,
          );
          final driverData = _apiService.handleResponse(driverResponse);
          _driver = driverData['driver'];
        } catch (e) {
          // If driver profile doesn't exist, set empty driver data
          _driver = {
            'status': 'pending',
            'vehicleInfo': {},
            'earnings': {'today': 0, 'thisWeek': 0, 'thisMonth': 0, 'total': 0},
          };
        }
      }

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({required String name, String? email}) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.patch(
        '/auth/profile',
        data: {'name': name, if (email != null) 'email': email},
      );

      final data = _apiService.handleResponse(response);

      if (data['user'] != null) {
        _user = data['user'];
        await _storeUserData();
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

  // Update driver profile
  Future<bool> updateDriverProfile({
    required String licenseNumber,
    required Map<String, dynamic> vehicleInfo,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.patch(
        AppConstants.driverProfileEndpoint,
        data: {'licenseNumber': licenseNumber, 'vehicleInfo': vehicleInfo},
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

  // Update profile image
  Future<bool> updateProfileImage(String imagePath) async {
    try {
      _setLoading(true);
      _clearError();

      // Create FormData for file upload
      final formData = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(imagePath),
      });

      final response = await _apiService.post(
        '/auth/upload-profile-image',
        data: formData,
      );
      final data = _apiService.handleResponse(response);

      if (data['user'] != null) {
        _user = data['user'];
        await _storeUserData();
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

  // Get driver earnings
  Future<Map<String, dynamic>?> getDriverEarnings() async {
    try {
      final response = await _apiService.get(AppConstants.earningsEndpoint);
      final data = _apiService.handleResponse(response);
      return data['earnings'];
    } catch (e) {
      _setError(e.toString());
      return null;
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

  // Logout
  Future<void> logout() async {
    try {
      _setLoading(true);

      // Call logout endpoint
      await _apiService.post('/auth/logout');

      // Clear API token
      await _apiService.clearAuthToken();

      // Clear local data
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

  // Store user data locally
  Future<void> _storeUserData() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
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
}
