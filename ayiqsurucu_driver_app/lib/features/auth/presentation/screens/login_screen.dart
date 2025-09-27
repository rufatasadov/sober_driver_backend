import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_screen.dart';
import '../cubit/auth_cubit.dart';
import 'otp_verification_screen.dart';
import 'driver_registration_screen.dart';
import 'direct_driver_registration_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpMode = true; // true for OTP, false for username/password

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final authCubit = context.read<AuthCubit>();
    setState(() => _isLoading = true);

    try {
      final success = await authCubit.sendOtp(_phoneController.text.trim());

      if (success) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OtpVerificationScreen(
                    phone: _phoneController.text.trim(),
                  ),
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(authCubit.error ?? 'OTP göndərilmədi');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _driverLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authCubit = context.read<AuthCubit>();
    setState(() => _isLoading = true);

    try {
      final success = await authCubit.driverLogin(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (success) {
        if (mounted) {
          // Check if user is already a driver
          if (authCubit.driver != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
          } else {
            // Navigate to driver registration
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DriverRegistrationScreen(),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          _showErrorDialog(authCubit.error ?? 'Giriş uğursuz oldu');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xəta'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60.h),

                // Logo
                Center(
                  child: Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.local_taxi,
                      size: 60.sp,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // App title
                Text(
                  'Ayiq Sürücü',
                  style: AppTheme.heading1.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                Text(
                  'Driver App',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 48.h),

                // Welcome text
                Text(
                  'Xoş gəlmisiniz!',
                  style: AppTheme.heading2,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                Text(
                  'Davam etmək üçün telefon nömrənizi daxil edin',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32.h),

                // Login mode toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isOtpMode = true),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color:
                                  _isOtpMode
                                      ? AppColors.primary
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              'OTP ilə',
                              style: AppTheme.bodyMedium.copyWith(
                                color:
                                    _isOtpMode
                                        ? AppColors.textOnPrimary
                                        : AppColors.textSecondary,
                                fontWeight:
                                    _isOtpMode
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isOtpMode = false),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color:
                                  !_isOtpMode
                                      ? AppColors.primary
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              'İstifadəçi adı',
                              style: AppTheme.bodyMedium.copyWith(
                                color:
                                    !_isOtpMode
                                        ? AppColors.textOnPrimary
                                        : AppColors.textSecondary,
                                fontWeight:
                                    !_isOtpMode
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Direct registration option
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.person_add, color: AppColors.success),
                    title: Text(
                      'Yeni sürücü kimi qeydiyyat',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'OTP olmadan birbaşa qeydiyyat',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.success.withOpacity(0.8),
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.success,
                      size: 16.sp,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const DirectDriverRegistrationScreen(),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 24.h),

                // Input fields based on mode
                if (_isOtpMode) ...[
                  // Phone input for OTP mode
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Telefon nömrəsi',
                      hintText: '+994 50 123 45 67',
                      prefixIcon: Icon(
                        Icons.phone,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon:
                          _phoneController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => _phoneController.clear(),
                              )
                              : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Telefon nömrəsi tələb olunur';
                      }
                      if (value.length < 10) {
                        return 'Düzgün telefon nömrəsi daxil edin';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() {}),
                  ),
                ] else ...[
                  // Username input for username/password mode
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'İstifadəçi adı',
                      hintText: 'İstifadəçi adınızı daxil edin',
                      prefixIcon: Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon:
                          _usernameController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => _usernameController.clear(),
                              )
                              : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'İstifadəçi adı tələb olunur';
                      }
                      if (value.length < 3) {
                        return 'İstifadəçi adı minimum 3 simvol olmalıdır';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() {}),
                  ),

                  SizedBox(height: 16.h),

                  // Password input for username/password mode
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Şifrə',
                      hintText: 'Şifrənizi daxil edin',
                      prefixIcon: Icon(
                        Icons.lock,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon:
                          _passwordController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => _passwordController.clear(),
                              )
                              : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifrə tələb olunur';
                      }
                      if (value.length < 6) {
                        return 'Şifrə minimum 6 simvol olmalıdır';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() {}),
                  ),
                ],

                SizedBox(height: 32.h),

                // Login button
                LoadingButton(
                  text: _isOtpMode ? 'OTP Göndər' : 'Giriş Et',
                  onPressed: _isOtpMode ? _sendOtp : _driverLogin,
                  isLoading: _isLoading,
                ),

                SizedBox(height: 24.h),

                // Info text
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          _isOtpMode
                              ? 'OTP kodu SMS vasitəsilə göndəriləcək'
                              : 'İstifadəçi adı və şifrənizlə giriş edin',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Terms and privacy
                Text(
                  'Davam etməklə şərtləri və məxfilik siyasətini qəbul etmiş olursunuz',
                  style: AppTheme.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
