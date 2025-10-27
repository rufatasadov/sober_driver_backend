import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameOrPhoneController = TextEditingController();
  bool _isLoading = false;
  String? _selectedMethod = 'phone'; // 'phone' or 'email'

  @override
  void dispose() {
    _usernameOrPhoneController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Implement backend API call
      // For now, show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reset code sent to ${_selectedMethod == 'phone' ? 'phone' : 'email'}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
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
                  'Enter your username or phone number to receive a reset code',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32.h),

                // Method selection
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

                SizedBox(height: 24.h),

                // Input field
                TextFormField(
                  controller: _usernameOrPhoneController,
                  keyboardType:
                      _selectedMethod == 'phone'
                          ? TextInputType.phone
                          : TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText:
                        _selectedMethod == 'phone' ? 'Phone Number' : 'Email',
                    hintText:
                        _selectedMethod == 'phone'
                            ? '+994501234567'
                            : 'example@email.com',
                    prefixIcon: Icon(
                      _selectedMethod == 'phone' ? Icons.phone : Icons.email,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  },
                ),

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
