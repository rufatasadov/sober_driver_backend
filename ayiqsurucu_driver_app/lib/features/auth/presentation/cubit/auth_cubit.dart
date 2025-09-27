import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_constants.dart';

// Auth States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  final Map<String, dynamic> user;
  final Map<String, dynamic>? driver;

  AuthAuthenticated({required this.token, required this.user, this.driver});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}

// Auth Cubit
class AuthCubit extends Cubit<AuthState> {
  final ApiService _apiService = ApiService();

  AuthCubit() : super(AuthInitial());

  // Getters
  bool get isAuthenticated => state is AuthAuthenticated;
  bool get isLoading => state is AuthLoading;
  String? get error => state is AuthError ? (state as AuthError).message : null;
  Map<String, dynamic>? get user =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;
  Map<String, dynamic>? get driver =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).driver : null;
  String? get token =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).token : null;

  // Initialize auth state from stored data
  Future<void> checkAuthStatus() async {
    try {
      emit(AuthLoading());

      final storedToken = await _apiService.getStoredToken();
      if (storedToken != null) {
        // Load user data from storage
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(AppConstants.userKey);
        final driverJson = prefs.getString(AppConstants.driverKey);

        Map<String, dynamic>? user;
        Map<String, dynamic>? driver;

        if (userJson != null) {
          user = Map<String, dynamic>.from(Uri.splitQueryString(userJson));
        }

        if (driverJson != null) {
          driver = Map<String, dynamic>.from(Uri.splitQueryString(driverJson));
        }

        emit(
          AuthAuthenticated(
            token: storedToken,
            user: user ?? {},
            driver: driver,
          ),
        );
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Auth status check failed: $e'));
    }
  }

  // Send OTP
  Future<bool> sendOtp(String phone) async {
    try {
      emit(AuthLoading());

      final response = await _apiService.post(
        AppConstants.sendOtpEndpoint,
        data: {'phone': phone},
      );

      final data = _apiService.handleResponse(response);

      if (data['message'] != null) {
        emit(AuthUnauthenticated());
        return true;
      }

      emit(AuthError('Failed to send OTP'));
      return false;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Verify OTP and login
  Future<bool> verifyOtp({
    required String phone,
    required String otp,
    String? name,
  }) async {
    try {
      emit(AuthLoading());

      final response = await _apiService.post(
        AppConstants.verifyOtpEndpoint,
        data: {'phone': phone, 'otp': otp, if (name != null) 'name': name},
      );

      final data = _apiService.handleResponse(response);

      if (data['token'] != null) {
        final token = data['token'];
        final user = data['user'];

        // Store auth data
        await _storeAuthData(token, user);

        // Set token in API service
        await _apiService.setAuthToken(token);

        emit(AuthAuthenticated(token: token, user: user));
        return true;
      }

      emit(AuthError('Invalid OTP'));
      return false;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Driver login with username/password
  Future<bool> driverLogin({
    required String username,
    required String password,
  }) async {
    try {
      emit(AuthLoading());

      final response = await _apiService.post(
        AppConstants.driverLoginEndpoint,
        data: {'username': username, 'password': password},
      );

      final data = _apiService.handleResponse(response);

      if (data['token'] != null) {
        final token = data['token'];
        final user = data['user'];

        // Store auth data
        await _storeAuthData(token, user);

        // Set token in API service
        await _apiService.setAuthToken(token);

        emit(AuthAuthenticated(token: token, user: user));
        return true;
      }

      emit(AuthError('Invalid credentials'));
      return false;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
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
      emit(AuthLoading());

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
        final token = data['token'];
        final user = data['user'];

        // Store auth data
        await _storeAuthData(token, user);

        // Set token in API service
        await _apiService.setAuthToken(token);

        emit(AuthAuthenticated(token: token, user: user));
        return true;
      }

      emit(AuthError('Failed to create account'));
      return false;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Driver registration
  Future<bool> registerDriver({
    required String licenseNumber,
    required Map<String, dynamic> vehicleInfo,
    Map<String, dynamic>? documents,
  }) async {
    try {
      emit(AuthLoading());

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
        final driver = data['driver'];
        await _storeDriverData(driver);

        // Update current state with driver info
        if (state is AuthAuthenticated) {
          final currentState = state as AuthAuthenticated;
          emit(
            AuthAuthenticated(
              token: currentState.token,
              user: currentState.user,
              driver: driver,
            ),
          );
        }

        return true;
      }

      emit(AuthError('Failed to register driver'));
      return false;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Get driver profile
  Future<bool> getDriverProfile() async {
    try {
      emit(AuthLoading());

      final response = await _apiService.get(
        AppConstants.driverProfileEndpoint,
      );
      final data = _apiService.handleResponse(response);

      if (data['driver'] != null) {
        final driver = data['driver'];
        await _storeDriverData(driver);

        // Update current state with driver info
        if (state is AuthAuthenticated) {
          final currentState = state as AuthAuthenticated;
          emit(
            AuthAuthenticated(
              token: currentState.token,
              user: currentState.user,
              driver: driver,
            ),
          );
        }

        return true;
      }

      emit(AuthError('Failed to load driver profile'));
      return false;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Update driver status
  Future<bool> updateDriverStatus({
    required bool isOnline,
    bool? isAvailable,
  }) async {
    try {
      emit(AuthLoading());

      final response = await _apiService.patch(
        AppConstants.driverStatusEndpoint,
        data: {
          'isOnline': isOnline,
          if (isAvailable != null) 'isAvailable': isAvailable,
        },
      );

      final data = _apiService.handleResponse(response);

      if (data['driver'] != null && state is AuthAuthenticated) {
        final currentState = state as AuthAuthenticated;
        final updatedDriver = Map<String, dynamic>.from(
          currentState.driver ?? {},
        );
        updatedDriver['isOnline'] = data['driver']['isOnline'];
        updatedDriver['isAvailable'] = data['driver']['isAvailable'];

        await _storeDriverData(updatedDriver);

        emit(
          AuthAuthenticated(
            token: currentState.token,
            user: currentState.user,
            driver: updatedDriver,
          ),
        );
        return true;
      }

      emit(AuthError('Failed to update driver status'));
      return false;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
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
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      emit(AuthLoading());

      // Clear API token
      await _apiService.clearAuthToken();

      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userKey);
      await prefs.remove(AppConstants.driverKey);

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Store auth data locally
  Future<void> _storeAuthData(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userKey, user.toString());
  }

  // Store driver data locally
  Future<void> _storeDriverData(Map<String, dynamic> driver) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.driverKey, driver.toString());
  }

  // Clear error manually
  void clearError() {
    if (state is AuthError) {
      emit(AuthUnauthenticated());
    }
  }
}
