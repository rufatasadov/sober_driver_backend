import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_screen.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final user = profileProvider.user;

    if (user != null) {
      _nameController.text = user['name'] ?? '';
      _emailController.text = user['email'] ?? '';
      _phoneController.text = user['phone'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    final success = await profileProvider.updateUserProfile(
      name: _nameController.text.trim(),
      email:
          _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil uğurla yeniləndi'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        _showErrorDialog(profileProvider.error ?? 'Profil yenilənmədi');
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
          'Profil Redaktə Et',
          style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              return TextButton(
                onPressed: profileProvider.isLoading ? null : _saveProfile,
                child: Text(
                  'Saxla',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading) {
            return const LoadingScreen();
          }

          return SingleChildScrollView(
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
                        Icon(Icons.edit, color: AppColors.primary, size: 24.sp),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Şəxsi məlumatlarınızı yeniləyin',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Name Field
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

                  SizedBox(height: 24.h),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email (İstəyə bağlı)',
                      hintText: 'email@example.com',
                      prefixIcon: Icon(
                        Icons.email,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Düzgün email daxil edin';
                        }
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24.h),

                  // Phone Field (Read-only)
                  TextFormField(
                    controller: _phoneController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Telefon nömrəsi',
                      hintText: 'Telefon nömrəsi',
                      prefixIcon: Icon(
                        Icons.phone,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: Icon(
                        Icons.lock,
                        color: AppColors.textSecondary,
                        size: 16.sp,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Info about phone
                  Container(
                    padding: EdgeInsets.all(12.w),
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
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Telefon nömrəsi təhlükəsizlik səbəbindən dəyişdirilə bilməz',
                            style: AppTheme.caption.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Save Button
                  Container(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed:
                          profileProvider.isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child:
                          profileProvider.isLoading
                              ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textOnPrimary,
                                  ),
                                ),
                              )
                              : Text(
                                'Saxla',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppColors.textOnPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Warning
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
                            'Məlumatlarınızı dəyişdikdən sonra sistem tərəfindən yoxlanılacaq',
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
          );
        },
      ),
    );
  }
}
