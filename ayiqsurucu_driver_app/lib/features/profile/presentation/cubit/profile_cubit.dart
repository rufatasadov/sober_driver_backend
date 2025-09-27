import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_constants.dart';

// Profile States
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? driver;

  ProfileLoaded({required this.user, this.driver});
}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);
}

// Profile Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final ApiService _apiService = ApiService();

  ProfileCubit() : super(ProfileInitial());

  // Getters
  bool get isLoading => state is ProfileLoading;
  String? get error =>
      state is ProfileError ? (state as ProfileError).message : null;
  Map<String, dynamic>? get user =>
      state is ProfileLoaded ? (state as ProfileLoaded).user : null;
  Map<String, dynamic>? get driver =>
      state is ProfileLoaded ? (state as ProfileLoaded).driver : null;

  // Load profile data
  Future<void> loadProfile() async {
    try {
      emit(ProfileLoading());

      // Load user profile
      final userResponse = await _apiService.get('/auth/me');
      final userData = _apiService.handleResponse(userResponse);
      final user = userData['user'];

      Map<String, dynamic>? driver;

      // Load driver profile (only if user is a driver)
      if (user?['role'] == 'driver') {
        try {
          final driverResponse = await _apiService.get(
            AppConstants.driverProfileEndpoint,
          );
          final driverData = _apiService.handleResponse(driverResponse);
          driver = driverData['driver'];
        } catch (e) {
          // If driver profile doesn't exist, set empty driver data
          driver = {
            'status': 'pending',
            'vehicleInfo': {},
            'earnings': {'today': 0, 'thisWeek': 0, 'thisMonth': 0, 'total': 0},
          };
        }
      }

      emit(ProfileLoaded(user: user, driver: driver));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({required String name, String? email}) async {
    try {
      emit(ProfileLoading());

      final response = await _apiService.patch(
        '/auth/profile',
        data: {'name': name, if (email != null) 'email': email},
      );

      final data = _apiService.handleResponse(response);

      if (data['user'] != null) {
        final updatedUser = data['user'];
        await _storeUserData(updatedUser);

        // Update current state
        if (state is ProfileLoaded) {
          final currentState = state as ProfileLoaded;
          emit(ProfileLoaded(user: updatedUser, driver: currentState.driver));
        }

        return true;
      }

      emit(ProfileError('Failed to update profile'));
      return false;
    } catch (e) {
      emit(ProfileError(e.toString()));
      return false;
    }
  }

  // Update driver profile
  Future<bool> updateDriverProfile({
    required String licenseNumber,
    required Map<String, dynamic> vehicleInfo,
  }) async {
    try {
      emit(ProfileLoading());

      final response = await _apiService.patch(
        AppConstants.driverProfileEndpoint,
        data: {'licenseNumber': licenseNumber, 'vehicleInfo': vehicleInfo},
      );

      final data = _apiService.handleResponse(response);

      if (data['driver'] != null) {
        final updatedDriver = data['driver'];
        await _storeDriverData(updatedDriver);

        // Update current state
        if (state is ProfileLoaded) {
          final currentState = state as ProfileLoaded;
          emit(ProfileLoaded(user: currentState.user, driver: updatedDriver));
        }

        return true;
      }

      emit(ProfileError('Failed to update driver profile'));
      return false;
    } catch (e) {
      emit(ProfileError(e.toString()));
      return false;
    }
  }

  // Update profile image
  Future<bool> updateProfileImage(String imagePath) async {
    try {
      emit(ProfileLoading());

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
        final updatedUser = data['user'];
        await _storeUserData(updatedUser);

        // Update current state
        if (state is ProfileLoaded) {
          final currentState = state as ProfileLoaded;
          emit(ProfileLoaded(user: updatedUser, driver: currentState.driver));
        }

        return true;
      }

      emit(ProfileError('Failed to update profile image'));
      return false;
    } catch (e) {
      emit(ProfileError(e.toString()));
      return false;
    }
  }

  // Get driver earnings
  Future<Map<String, dynamic>?> getDriverEarnings() async {
    try {
      final response = await _apiService.get(AppConstants.earningsEndpoint);
      final data = _apiService.handleResponse(response);
      return data['earnings'];
    } catch (e) {
      emit(ProfileError(e.toString()));
      return null;
    }
  }

  // Update driver status
  Future<bool> updateDriverStatus({
    required bool isOnline,
    bool? isAvailable,
  }) async {
    try {
      emit(ProfileLoading());

      final response = await _apiService.patch(
        AppConstants.driverStatusEndpoint,
        data: {
          'isOnline': isOnline,
          if (isAvailable != null) 'isAvailable': isAvailable,
        },
      );

      final data = _apiService.handleResponse(response);

      if (data['driver'] != null) {
        final updatedDriver = data['driver'];
        await _storeDriverData(updatedDriver);

        // Update current state
        if (state is ProfileLoaded) {
          final currentState = state as ProfileLoaded;
          emit(ProfileLoaded(user: currentState.user, driver: updatedDriver));
        }

        return true;
      }

      emit(ProfileError('Failed to update driver status'));
      return false;
    } catch (e) {
      emit(ProfileError(e.toString()));
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      emit(ProfileLoading());

      // Call logout endpoint
      await _apiService.post('/auth/logout');

      // Clear API token
      await _apiService.clearAuthToken();

      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userKey);
      await prefs.remove(AppConstants.driverKey);

      emit(ProfileInitial());
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // Store user data locally
  Future<void> _storeUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, user.toString());
  }

  // Store driver data locally
  Future<void> _storeDriverData(Map<String, dynamic> driver) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.driverKey, driver.toString());
  }
}
