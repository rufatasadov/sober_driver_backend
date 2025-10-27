import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../shared/widgets/loading_screen.dart';
import '../cubit/auth_cubit.dart';
import 'driver_registration_screen.dart';
import 'direct_driver_registration_screen.dart';
import 'forgot_password_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isAutoLoggingIn = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('saved_username');
      final savedPassword = prefs.getString('saved_password');

      if (savedUsername != null && savedPassword != null) {
        setState(() {
          _isAutoLoggingIn = true;
        });

        // Auto login with saved credentials
        final authCubit = context.read<AuthCubit>();
        final success = await authCubit.driverLogin(
          username: savedUsername,
          password: savedPassword,
        );

        if (success && mounted) {
          if (authCubit.driver != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
          }
        } else if (mounted) {
          // Clear saved credentials if login failed
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('saved_username');
          await prefs.remove('saved_password');

          setState(() {
            _isAutoLoggingIn = false;
          });
        }
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
      setState(() {
        _isAutoLoggingIn = false;
      });
    }
  }

  Future<void> _saveCredentials(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', username);
      await prefs.setString('saved_password', password);
      print('✅ Credentials saved for auto login');
    } catch (e) {
      print('Error saving credentials: $e');
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
        // Save credentials for auto login
        await _saveCredentials(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

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
          _showErrorDialog(
            authCubit.error ??
                context.read<LanguageProvider>().getString('loginFailed'),
          );
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
            title: Text(context.read<LanguageProvider>().getString('error')),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.read<LanguageProvider>().getString('ok')),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen during auto login
    if (_isAutoLoggingIn) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Logging in...',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
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
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Image.asset(
                          'assets/images/logo.jpeg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.local_taxi,
                              size: 60.sp,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // App title
                    Text(
                      'Peregon hayda',
                      style: AppTheme.heading1.copyWith(
                        color: AppColors.primary,
                      ),
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
                      languageProvider.getString('welcome'),
                      style: AppTheme.heading2,
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 8.h),

                    Text(
                      languageProvider.getString('enterCredentials'),
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 32.h),

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
                        leading: Icon(
                          Icons.person_add,
                          color: AppColors.success,
                        ),
                        title: Text(
                          languageProvider.getString('driverRegistration'),
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          languageProvider.getString('completeRegistration'),
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

                    // Username input
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: languageProvider.getString('username'),
                        hintText: languageProvider.getString('enterUsername'),
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
                          return languageProvider.getString('usernameRequired');
                        }
                        if (value.length < 3) {
                          return languageProvider.getString(
                            'usernameMinLength',
                          );
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() {}),
                    ),

                    SizedBox(height: 16.h),

                    // Password input
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: languageProvider.getString('password'),
                        hintText: languageProvider.getString('enterPassword'),
                        prefixIcon: Icon(
                          Icons.lock,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return languageProvider.getString('passwordRequired');
                        }
                        if (value.length < 6) {
                          return languageProvider.getString(
                            'passwordMinLength',
                          );
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() {}),
                    ),

                    SizedBox(height: 16.h),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Login button
                    LoadingButton(
                      text: languageProvider.getString('login'),
                      onPressed: _driverLogin,
                      isLoading: _isLoading,
                    ),

                    SizedBox(height: 24.h),

                    // Info text
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.info.withOpacity(0.3),
                        ),
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
                              languageProvider.getString(
                                'loginWithCredentials',
                              ),
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
                      languageProvider.getString('privacyPolicy'),
                      style: AppTheme.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
