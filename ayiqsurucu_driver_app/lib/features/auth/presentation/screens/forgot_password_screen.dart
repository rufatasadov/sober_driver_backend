import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/loading_screen.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();

      print('📤 Sending reset code for username: $username');

      final requestBody = {'username': username};
      print('📤 Request body: $requestBody');

      // Call backend API to send reset code
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/send-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (mounted) {
        if (response.statusCode == 200) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reset code sent! Test code: 123456'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 5),
            ),
          );

          // Navigate to verify code screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ResetCodeVerificationScreen(
                    usernameOrPhone: username,
                    method: 'username',
                  ),
            ),
          );
        } else {
          final error = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['error'] ?? 'Failed to send reset code'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Forgot Password',
          style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),

                // Info Icon
                Center(
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 40.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Title
                Text(
                  'Reset Password',
                  style: AppTheme.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                // Description
                Text(
                  'Enter your username to receive a reset code',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32.h),

                // Username input field (simplified - no method selection)
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 32.h),

                // Old method selection removed - keeping for reference
                /* Old code starts
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMethod = 'phone'),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color:
                                _selectedMethod == 'phone'
                                    ? AppColors.primary.withOpacity(0.1)
                                    : AppColors.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color:
                                  _selectedMethod == 'phone'
                                      ? AppColors.primary
                                      : AppColors.border,
                              width: _selectedMethod == 'phone' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.phone,
                                color:
                                    _selectedMethod == 'phone'
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                size: 24.sp,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Phone',
                                style: AppTheme.bodyMedium.copyWith(
                                  color:
                                      _selectedMethod == 'phone'
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                  fontWeight:
                                      _selectedMethod == 'phone'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMethod = 'email'),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color:
                                _selectedMethod == 'email'
                                    ? AppColors.primary.withOpacity(0.1)
                                    : AppColors.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color:
                                  _selectedMethod == 'email'
                                      ? AppColors.primary
                                      : AppColors.border,
                              width: _selectedMethod == 'email' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.email,
                                color:
                                    _selectedMethod == 'email'
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                size: 24.sp,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Email',
                                style: AppTheme.bodyMedium.copyWith(
                                  color:
                                      _selectedMethod == 'email'
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                  fontWeight:
                                      _selectedMethod == 'email'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Old code ends */
                SizedBox(height: 0.h),

                // Old input field removed above - keeping button below
                if (true) SizedBox(height: 0.h),

                SizedBox(height: 32.h),

                // Send Reset Code button
                LoadingButton(
                  text: 'Send Reset Code',
                  onPressed: _sendResetCode,
                  isLoading: _isLoading,
                ),

                SizedBox(height: 24.h),

                // Back to Login
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back to Login',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Reset Code Verification Screen
class ResetCodeVerificationScreen extends StatefulWidget {
  final String usernameOrPhone;
  final String method;

  const ResetCodeVerificationScreen({
    super.key,
    required this.usernameOrPhone,
    required this.method,
  });

  @override
  State<ResetCodeVerificationScreen> createState() =>
      _ResetCodeVerificationScreenState();
}

class _ResetCodeVerificationScreenState
    extends State<ResetCodeVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  final TEST_CODE = '123456'; // Test code - always use this for testing

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Implement backend API call to verify code
      // For now, check if code is 123456
      final enteredCode = _codeController.text.trim();

      if (enteredCode == TEST_CODE) {
        if (mounted) {
          // Navigate to new password screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => NewPasswordScreen(
                    usernameOrPhone: widget.usernameOrPhone,
                    method: widget.method,
                  ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid code. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verify Code',
          style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),

                // Info Icon
                Center(
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified,
                      size: 40.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Title
                Text(
                  'Enter Verification Code',
                  style: AppTheme.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                // Description
                Text(
                  'Enter the code sent to ${widget.method == 'phone' ? 'your phone' : 'your email'}',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32.h),

                // Code input
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8.w,
                  ),
                  decoration: InputDecoration(
                    hintText: '123456',
                    hintStyle: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8.w,
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Code is required';
                    }
                    if (value.length != 6) {
                      return 'Code must be 6 digits';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24.h),

                // Info text
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Test code: 123456',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Verify button
                LoadingButton(
                  text: 'Verify Code',
                  onPressed: _verifyCode,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// New Password Screen
class NewPasswordScreen extends StatefulWidget {
  final String usernameOrPhone;
  final String method;

  const NewPasswordScreen({
    super.key,
    required this.usernameOrPhone,
    required this.method,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newPassword = _newPasswordController.text.trim();

      // Call backend API to reset password
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': widget.usernameOrPhone,
          'code': '123456', // Test code
          'newPassword': newPassword,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset successfully!'),
              backgroundColor: AppColors.success,
            ),
          );

          // Navigate back to login
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else {
          final error = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['error'] ?? 'Failed to reset password'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Set New Password',
          style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),

                // Info Icon
                Center(
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 40.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Title
                Text(
                  'Create New Password',
                  style: AppTheme.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                // Description
                Text(
                  'Enter your new password below',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32.h),

                // New Password
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Enter new password',
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
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24.h),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm new password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password confirmation is required';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 32.h),

                // Reset button
                LoadingButton(
                  text: 'Reset Password',
                  onPressed: _resetPassword,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
