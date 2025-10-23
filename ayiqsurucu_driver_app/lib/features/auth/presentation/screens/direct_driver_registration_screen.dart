import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_screen.dart';
import '../../../../shared/widgets/privacy_policy_widget.dart';
import '../../../../shared/widgets/image_upload_widget.dart';
import '../cubit/auth_cubit.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class DirectDriverRegistrationScreen extends StatefulWidget {
  const DirectDriverRegistrationScreen({super.key});

  @override
  State<DirectDriverRegistrationScreen> createState() =>
      _DirectDriverRegistrationScreenState();
}

class _DirectDriverRegistrationScreenState
    extends State<DirectDriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _actualAddressController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _privacyPolicyAccepted = false;

  // Image paths
  String? _identityCardFront;
  String? _identityCardBack;
  String? _licenseFront;
  String? _licenseBack;

  // License expiry date
  DateTime? _licenseExpiryDate;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseController.dispose();
    _actualAddressController.dispose();
    super.dispose();
  }

  Future<void> _registerDriver() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_privacyPolicyAccepted) {
      _showErrorDialog('Please accept the terms and conditions to continue.');
      return;
    }

    if (_licenseExpiryDate == null) {
      _showErrorDialog('Please select license expiry date.');
      return;
    }

    final authCubit = context.read<AuthCubit>();
    setState(() => _isLoading = true);

    try {
      // First create user account
      final userSuccess = await authCubit.createUserAccount(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userSuccess) {
        // Then register as driver (without vehicle info)
        final driverSuccess = await authCubit.registerDriver(
          licenseNumber: _licenseController.text.trim(),
          actualAddress: _actualAddressController.text.trim(),
          licenseExpiryDate: _licenseExpiryDate!,
          identityCardFront: _identityCardFront,
          identityCardBack: _identityCardBack,
          licenseFront: _licenseFront,
          licenseBack: _licenseBack,
        );

        if (driverSuccess) {
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
              authCubit.error ?? 'Sürücü qeydiyyatı tamamlanmadı',
            );
          }
        }
      } else {
        if (mounted) {
          _showErrorDialog(
            authCubit.error ?? 'İstifadəçi qeydiyyatı tamamlanmadı',
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
        title: Text(
          'Sürücü Qeydiyyatı',
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
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add,
                        color: AppColors.success,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Yeni sürücü kimi qeydiyyat - OTP olmadan',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Personal Information Section
                Text('Şəxsi Məlumatlar', style: AppTheme.heading3),
                SizedBox(height: 16.h),

                // Name
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
                    if (value == null || value.isEmpty) {
                      return 'Ad Soyad tələb olunur';
                    }
                    if (value.length < 2) {
                      return 'Ad minimum 2 simvol olmalıdır';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                // Phone
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
                ),

                SizedBox(height: 16.h),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'İstifadəçi adı',
                    hintText: 'İstifadəçi adınızı daxil edin',
                    prefixIcon: Icon(
                      Icons.account_circle,
                      color: AppColors.textSecondary,
                    ),
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
                ),

                SizedBox(height: 16.h),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Şifrə',
                    hintText: 'Şifrənizi daxil edin',
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
                      return 'Şifrə tələb olunur';
                    }
                    if (value.length < 6) {
                      return 'Şifrə minimum 6 simvol olmalıdır';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Şifrəni təsdiq et',
                    hintText: 'Şifrənizi yenidən daxil edin',
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
                      return 'Şifrə təsdiqi tələb olunur';
                    }
                    if (value != _passwordController.text) {
                      return 'Şifrələr uyğun gəlmir';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 32.h),

                // Driver Information Section
                Text('Sürücü Məlumatları', style: AppTheme.heading3),
                SizedBox(height: 16.h),

                // License Number
                TextFormField(
                  controller: _licenseController,
                  decoration: InputDecoration(
                    labelText: 'Sürücülük vəsiqəsi nömrəsi',
                    hintText: 'AZE123456789',
                    prefixIcon: Icon(
                      Icons.credit_card,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Sürücülük vəsiqəsi nömrəsi tələb olunur';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                // Actual Address
                TextFormField(
                  controller: _actualAddressController,
                  decoration: InputDecoration(
                    labelText: 'Faktiki ünvan',
                    hintText: 'Yaşadığınız ünvanı daxil edin',
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Faktiki ünvan tələb olunur';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                // License Expiry Date
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setState(() {
                        _licenseExpiryDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            _licenseExpiryDate != null
                                ? '${_licenseExpiryDate!.day}/${_licenseExpiryDate!.month}/${_licenseExpiryDate!.year}'
                                : 'Sürücülük vəsiqəsinin bitmə tarixi',
                            style: AppTheme.bodyMedium.copyWith(
                              color:
                                  _licenseExpiryDate != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Documents Section
                Text('Sənədlər', style: AppTheme.heading3),
                SizedBox(height: 16.h),

                // Identity Card Front
                ImageUploadWidget(
                  label: 'Şəxsiyyət vəsiqəsi (Ön tərəf)',
                  currentImagePath: _identityCardFront,
                  onImageSelected: (path) {
                    setState(() {
                      _identityCardFront = path;
                    });
                  },
                  isRequired: true,
                  frontOrBack: 'front',
                ),

                SizedBox(height: 16.h),

                // Identity Card Back
                ImageUploadWidget(
                  label: 'Şəxsiyyət vəsiqəsi (Arxa tərəf)',
                  currentImagePath: _identityCardBack,
                  onImageSelected: (path) {
                    setState(() {
                      _identityCardBack = path;
                    });
                  },
                  isRequired: true,
                  frontOrBack: 'back',
                ),

                SizedBox(height: 16.h),

                // License Front
                ImageUploadWidget(
                  label: 'Sürücülük vəsiqəsi (Ön tərəf)',
                  currentImagePath: _licenseFront,
                  onImageSelected: (path) {
                    setState(() {
                      _licenseFront = path;
                    });
                  },
                  isRequired: true,
                  frontOrBack: 'front',
                ),

                SizedBox(height: 16.h),

                // License Back
                ImageUploadWidget(
                  label: 'Sürücülük vəsiqəsi (Arxa tərəf)',
                  currentImagePath: _licenseBack,
                  onImageSelected: (path) {
                    setState(() {
                      _licenseBack = path;
                    });
                  },
                  isRequired: true,
                  frontOrBack: 'back',
                ),

                SizedBox(height: 24.h),

                // Privacy Policy Section
                Text('Terms and Conditions', style: AppTheme.heading3),
                SizedBox(height: 16.h),

                PrivacyPolicyWidget(
                  isAccepted: _privacyPolicyAccepted,
                  onChanged: (value) {
                    setState(() {
                      _privacyPolicyAccepted = value;
                    });
                  },
                ),

                SizedBox(height: 24.h),

                // Register button
                LoadingButton(
                  text: 'Qeydiyyatı Tamamla',
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
                          'Qeydiyyatdan sonra məlumatlarınız yoxlanılacaq və təsdiqləndikdən sonra işə başlaya biləcəksiniz',
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
  }
}
