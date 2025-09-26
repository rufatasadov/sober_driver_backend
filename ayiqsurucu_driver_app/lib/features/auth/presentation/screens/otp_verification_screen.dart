import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_screen.dart';
import '../providers/auth_provider.dart';
import 'driver_registration_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;

  const OtpVerificationScreen({super.key, required this.phone});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isNewUser = false;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _canResend = false;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown <= 0) {
            _canResend = true;
            return;
          }
        });
      }
      return _resendCountdown > 0;
    });
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      final success = await authProvider.verifyOtp(
        phone: widget.phone,
        otp: _otpController.text.trim(),
        name: _isNewUser ? _nameController.text.trim() : null,
      );

      if (success) {
        if (mounted) {
          // Check if user is already a driver
          if (authProvider.isDriver) {
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
          _showErrorDialog(authProvider.error ?? 'OTP yoxlanılmadı');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      final success = await authProvider.sendOtp(widget.phone);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP yenidən göndərildi'),
              backgroundColor: AppColors.success,
            ),
          );
          _startResendTimer();
        }
      } else {
        if (mounted) {
          _showErrorDialog(authProvider.error ?? 'OTP göndərilmədi');
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
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
                SizedBox(height: 20.h),

                // Icon
                Center(
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40.r),
                    ),
                    child: Icon(
                      Icons.sms,
                      size: 40.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Title
                Text(
                  'OTP Təsdiqlə',
                  style: AppTheme.heading2,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                Text(
                  '${widget.phone} nömrəsinə göndərilən kodu daxil edin',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32.h),

                // OTP Input
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: AppTheme.heading2,
                  decoration: InputDecoration(
                    labelText: 'OTP Kodu',
                    hintText: '123456',
                    counterText: '',
                  ),
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'OTP kodu tələb olunur';
                    }
                    if (value.length != 6) {
                      return 'OTP kodu 6 rəqəm olmalıdır';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24.h),

                // Name input for new users
                if (_isNewUser) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Ad Soyad',
                      hintText: 'Adınızı və soyadınızı daxil edin',
                      prefixIcon: Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    validator: (value) {
                      if (_isNewUser && (value == null || value.isEmpty)) {
                        return 'Ad Soyad tələb olunur';
                      }
                      if (value != null && value.length < 2) {
                        return 'Ad minimum 2 simvol olmalıdır';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),
                ],

                // Verify button
                LoadingButton(
                  text: 'Təsdiqlə',
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                ),

                SizedBox(height: 24.h),

                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('OTP almadınız? ', style: AppTheme.bodyMedium),
                    if (_canResend)
                      TextButton(
                        onPressed: _resendOtp,
                        child: Text(
                          'Yenidən göndər',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Yenidən göndər (${_resendCountdown}s)',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 32.h),

                // Info
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
                          'OTP kodu 60 saniyə ərzində etibarlıdır',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
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
