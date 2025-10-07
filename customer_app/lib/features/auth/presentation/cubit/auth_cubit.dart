import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/models/user_model.dart';

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

class ProfileUpdatedState extends AuthState {
  final UserModel user;

  const ProfileUpdatedState(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final ApiService _apiService = ApiService();

  AuthCubit() : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    try {
      emit(AuthLoading());

      if (!_apiService.isAuthenticated) {
        emit(AuthUnauthenticated());
        return;
      }

      final response = await _apiService.getUserProfile();
      
      if (response['success']) {
        final user = UserModel.fromJson(response['user']);
        emit(AuthAuthenticated(
          user: user,
          token: _apiService.authToken!,
        ));
      } else {
        await _apiService.logout();
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Failed to check auth status: ${e.toString()}'));
    }
  }

  Future<void> sendOtp(String phone) async {
    try {
      emit(AuthLoading());

      // TEMPORARY: Skip OTP check for testing
      // Simulate successful OTP send
      await Future.delayed(const Duration(seconds: 1));
      emit(OtpSentState(phone));
      
      // Original OTP code (commented out for now):
      // final response = await _apiService.sendOtp(phone);
      // if (response['success']) {
      //   emit(OtpSentState(phone));
      // } else {
      //   emit(AuthError(response['error'] ?? 'Failed to send OTP'));
      // }
    } catch (e) {
      emit(AuthError('Failed to send OTP: ${e.toString()}'));
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
    String? name,
    String? email,
  }) async {
    try {
      emit(OtpVerifyingState());

      // TEMPORARY: Skip OTP verification for testing
      // Simulate successful verification
      await Future.delayed(const Duration(seconds: 1));
      
      // Create a mock user for testing
      final mockUser = UserModel(
        id: 'test-user-id',
        name: name ?? 'Test User',
        phone: phone,
        email: email,
        role: 'customer',
        isVerified: true,
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      // Mock token
      const mockToken = 'mock-jwt-token-for-testing';
      await _apiService.setAuthToken(mockToken);
      // Move app into Authenticated state so routing uses provider tree
      emit(AuthAuthenticated(user: mockUser, token: mockToken));
      
      // Original OTP verification code (commented out for now):
      // final response = await _apiService.verifyOtp(
      //   phone: phone,
      //   otp: otp,
      //   name: name,
      //   email: email,
      // );
      // 
      // if (response['success']) {
      //   final user = UserModel.fromJson(response['user']);
      //   emit(OtpVerifiedState(
      //     user: user,
      //     token: response['token'],
      //   ));
      // } else {
      //   emit(AuthError(response['error'] ?? 'Failed to verify OTP'));
      // }
    } catch (e) {
      emit(AuthError('Failed to verify OTP: ${e.toString()}'));
    }
  }

  Future<void> updateProfile({
    required String name,
    String? email,
  }) async {
    try {
      emit(AuthLoading());

      final response = await _apiService.updateProfile(
        name: name,
        email: email,
      );
      
      if (response['success']) {
        final user = UserModel.fromJson(response['user']);
        emit(ProfileUpdatedState(user));
      } else {
        emit(AuthError(response['error'] ?? 'Failed to update profile'));
      }
    } catch (e) {
      emit(AuthError('Failed to update profile: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Failed to logout: ${e.toString()}'));
    }
  }

  // TEST/DEV: Skip OTP and authenticate directly
  Future<void> skipToAuthenticated({String name = 'Test User', String phone = '+994500000000'}) async {
    final mockUser = UserModel(
      id: 'test-user-id',
      name: name,
      phone: phone,
      role: 'customer',
      isVerified: true,
      isActive: true,
      createdAt: DateTime.now(),
    );
    const mockToken = 'mock-jwt-token-for-testing';
    await _apiService.setAuthToken(mockToken);
    emit(AuthAuthenticated(user: mockUser, token: mockToken));
  }
}