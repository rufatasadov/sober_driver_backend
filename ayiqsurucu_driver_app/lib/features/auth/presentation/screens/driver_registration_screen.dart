import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../shared/widgets/loading_screen.dart';
import '../cubit/auth_cubit.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();

  bool _isLoading = false;
  bool _privacyPolicyAccepted = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _registerDriver() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_privacyPolicyAccepted) {
      _showErrorDialog(
        context.read<LanguageProvider>().getString('privacyPolicyRequired'),
      );
      return;
    }

    final authCubit = context.read<AuthCubit>();
    setState(() => _isLoading = true);

    try {
      final success = await authCubit.registerDriver(
        licenseNumber: _licenseController.text.trim(),
      );

      if (success) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(
            authCubit.error ??
                context.read<LanguageProvider>().getString(
                  'registrationFailed',
                ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              context.read<LanguageProvider>().getString('privacyPolicy'),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400.h,
              child: SingleChildScrollView(
                child: FutureBuilder<String>(
                  future: _loadPrivacyPolicy(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data!);
                    } else if (snapshot.hasError) {
                      return Text(
                        'Məxfilik siyasəti yüklənə bilmədi: ${snapshot.error}',
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.read<LanguageProvider>().getString('close'),
                ),
              ),
            ],
          ),
    );
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

  Future<String> _loadPrivacyPolicy() async {
    try {
      return await rootBundle.loadString('driver_privacy_policy.txt');
    } catch (e) {
      return 'Məxfilik siyasəti faylı tapılmadı.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(
              languageProvider.getString('driverRegistration'),
              style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
            ),
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
                    // Header
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              languageProvider.getString('fillInfoToWork'),
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // License Number
                    TextFormField(
                      controller: _licenseController,
                      decoration: InputDecoration(
                        labelText: languageProvider.getString('licenseNumber'),
                        hintText: languageProvider.getString('licenseHint'),
                        prefixIcon: Icon(
                          Icons.credit_card,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return languageProvider.getString('licenseRequired');
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 24.h),

                    // Privacy Policy Checkbox
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _privacyPolicyAccepted,
                                onChanged: (value) {
                                  setState(() {
                                    _privacyPolicyAccepted = value ?? false;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              Expanded(
                                child: Text(
                                  languageProvider.getString(
                                    'privacyPolicyAccepted',
                                  ),
                                  style: AppTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          TextButton(
                            onPressed: _showPrivacyPolicyDialog,
                            child: Text(
                              languageProvider.getString('readPrivacyPolicy'),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Register button
                    LoadingButton(
                      text: languageProvider.getString('completeRegistration'),
                      onPressed: _registerDriver,
                      isLoading: _isLoading,
                    ),

                    SizedBox(height: 24.h),

                    // Info
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: AppColors.warning,
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              languageProvider.getString('registrationInfo'),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.warning,
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
      },
    );
  }
}
