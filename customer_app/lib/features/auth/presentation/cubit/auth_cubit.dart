import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../core/constants/app_constants.dart';

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token;

  const AuthAuthenticated({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class OtpSentState extends AuthState {
  final String phone;

  const OtpSentState(this.phone);

  @override
  List<Object?> get props => [phone];
}

class OtpVerifyingState extends AuthState {}

class OtpVerifiedState extends AuthState {
  final UserModel user;
  final String token;

  const OtpVerifiedState({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SendOtpEvent extends AuthEvent {
  final String phone;

  const SendOtpEvent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class VerifyOtpEvent extends AuthEvent {
  final String phone;
  final String otp;
  final String? name;

  const VerifyOtpEvent({
    required this.phone,
    required this.otp,
    this.name,
  });

  @override
  List<Object?> get props => [phone, otp, name];
}

class LogoutEvent extends AuthEvent {}

class UpdateProfileEvent extends AuthEvent {
  final String? name;
  final String? email;

  const UpdateProfileEvent({
    this.name,
    this.email,
  });

  @override
  List<Object?> get props => [name, email];
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final ApiService _apiService = ApiService();

  AuthCubit() : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    try {
      emit(AuthLoading());

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      final userJson = prefs.getString(AppConstants.userKey);

      if (token != null && userJson != null) {
        // Verify token is still valid by getting user profile
        final response = await _apiService.getUserProfile();
        
        if (response['success']) {
          final user = UserModel.fromJson(response['user']);
          emit(AuthAuthenticated(user: user, token: token));
        } else {
          // Token is invalid, clear stored data
          await _clearStoredAuthData();
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Authentication check failed: ${e.toString()}'));
    }
  }

  Future<void> sendOtp(String phone) async {
    try {
      emit(AuthLoading());

      final response = await _apiService.sendOtp(phone);
      
      if (response['success']) {
        emit(OtpSentState(phone));
      } else {
        emit(AuthError(response['error'] ?? 'Failed to send OTP'));
      }
    } catch (e) {
      emit(AuthError('Failed to send OTP: ${e.toString()}'));
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
    String? name,
  }) async {
    try {
      emit(OtpVerifyingState());

      final response = await _apiService.verifyOtp(
        phone: phone,
        otp: otp,
        name: name,
      );

      if (response['success']) {
        final user = UserModel.fromJson(response['user']);
        final token = response['token'];

        // Store auth data
        await _storeAuthData(token, user);

        emit(OtpVerifiedState(user: user, token: token));
      } else {
        emit(AuthError(response['error'] ?? 'Failed to verify OTP'));
      }
    } catch (e) {
      emit(AuthError('Failed to verify OTP: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    try {
      emit(AuthLoading());

      await _apiService.logout();
      await _clearStoredAuthData();

      emit(AuthUnauthenticated());
    } catch (e) {
      // Even if logout fails on server, clear local data
      await _clearStoredAuthData();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(const AuthError('User not authenticated'));
        return;
      }

      emit(AuthLoading());

      final response = await _apiService.updateProfile(
        name: name,
        email: email,
      );

      if (response['success']) {
        // Update the user data in the current state
        final updatedUser = currentState.user.copyWith(
          name: name ?? currentState.user.name,
          email: email ?? currentState.user.email,
        );

        // Store updated user data
        await _storeAuthData(currentState.token, updatedUser);

        emit(AuthAuthenticated(user: updatedUser, token: currentState.token));
      } else {
        emit(AuthError(response['error'] ?? 'Failed to update profile'));
      }
    } catch (e) {
      emit(AuthError('Failed to update profile: ${e.toString()}'));
    }
  }

  Future<void> _storeAuthData(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userKey, user.toJson().toString());
  }

  Future<void> _clearStoredAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }
}
