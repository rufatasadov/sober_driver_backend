import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    // Reset form to original values
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      _nameController.text = state.user.name;
      _emailController.text = state.user.email ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return IconButton(
                  onPressed: _isEditing ? _saveProfile : _toggleEdit,
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is AuthAuthenticated) {
            setState(() {
              _isLoading = false;
              _isEditing = false;
            });
            // Update form fields
            _nameController.text = state.user.name;
            _emailController.text = state.user.email ?? '';
          } else if (state is AuthError) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    // Profile Header
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50.r,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                state.user.name.isNotEmpty 
                                    ? state.user.name[0].toUpperCase()
                                    : 'U',
                                style: AppTheme.headlineLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              state.user.name,
                              style: AppTheme.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              state.user.phone,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (state.user.email != null) ...[
                              SizedBox(height: 4.h),
                              Text(
                                state.user.email!,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Profile Form
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Şəxsi məlumatlar',
                                style: AppTheme.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              
                              // Name field
                              TextFormField(
                                controller: _nameController,
                                enabled: _isEditing,
                                decoration: const InputDecoration(
                                  labelText: 'Ad və soyad',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ad və soyad tələb olunur';
                                  }
                                  if (value.length < 2) {
                                    return 'Ad minimum 2 simvol olmalıdır';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16.h),
                              
                              // Email field
                              TextFormField(
                                controller: _emailController,
                                enabled: _isEditing,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Düzgün email daxil edin';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16.h),
                              
                              // Phone field (read-only)
                              TextFormField(
                                initialValue: state.user.phone,
                                enabled: false,
                                decoration: const InputDecoration(
                                  labelText: 'Telefon nömrəsi',
                                  prefixIcon: Icon(Icons.phone),
                                ),
                              ),
                              
                              if (_isEditing) ...[
                                SizedBox(height: 24.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _cancelEdit,
                                        child: const Text('Ləğv et'),
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _saveProfile,
                                        child: _isLoading
                                            ? SizedBox(
                                                height: 20.h,
                                                width: 20.w,
                                                child: const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text('Saxla'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Account Info
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hesab məlumatları',
                              style: AppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            
                            _buildInfoRow(
                              icon: Icons.calendar_today,
                              label: 'Qeydiyyat tarixi',
                              value: _formatDate(state.user.createdAt),
                            ),
                            
                            SizedBox(height: 12.h),
                            
                            _buildInfoRow(
                              icon: Icons.verified,
                              label: 'Status',
                              value: state.user.isVerified ? 'Təsdiqlənib' : 'Təsdiqlənməyib',
                              valueColor: state.user.isVerified ? AppColors.success : AppColors.warning,
                            ),
                            
                            if (state.user.lastLogin != null) ...[
                              SizedBox(height: 12.h),
                              _buildInfoRow(
                                icon: Icons.login,
                                label: 'Son giriş',
                                value: _formatDate(state.user.lastLogin!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
