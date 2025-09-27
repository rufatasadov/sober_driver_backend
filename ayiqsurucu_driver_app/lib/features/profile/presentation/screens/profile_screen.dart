import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_screen.dart';
import '../cubit/profile_cubit.dart';
import 'edit_profile_screen.dart';
import 'profile_settings_screen.dart';
import 'earnings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // Load profile when screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileCubit>().loadProfile();
    });

    return _buildProfileContent();
  }

  Widget _buildProfileContent() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Profil',
          style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(Icons.settings, color: AppColors.textPrimary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BlocProvider.value(
                            value: context.read<ProfileCubit>(),
                            child: const ProfileSettingsScreen(),
                          ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const LoadingScreen();
          }

          if (state is ProfileError) {
            return _buildErrorWidget(state.message);
          }

          if (state is ProfileLoaded) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  _buildProfileHeader(state),

                  SizedBox(height: 32.h),

                  // Statistics Cards
                  _buildStatisticsCards(state),

                  SizedBox(height: 32.h),

                  // Profile Information
                  _buildProfileInfo(state),

                  SizedBox(height: 32.h),

                  // Action Buttons
                  _buildActionButtons(context),

                  SizedBox(height: 24.h),

                  // Logout Button
                  _buildLogoutButton(context),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildProfileHeader(ProfileLoaded state) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Profile Image
          GestureDetector(
            onTap: () => _showImagePicker(state),
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child:
                  state.user['profileImage'] != null
                      ? ClipOval(
                        child: Image.network(
                          state.user['profileImage'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 40.sp,
                              color: AppColors.textOnPrimary,
                            );
                          },
                        ),
                      )
                      : Icon(
                        Icons.person,
                        size: 40.sp,
                        color: AppColors.textOnPrimary,
                      ),
            ),
          ),

          SizedBox(width: 16.w),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.user['name'] ?? 'Ad Soyad',
                  style: AppTheme.heading3.copyWith(color: AppColors.primary),
                ),
                SizedBox(height: 4.h),
                Text(
                  state.user['phone'] ?? 'Telefon nömrəsi',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(state.driver?['status']),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _getStatusText(state.driver?['status']),
                    style: AppTheme.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Edit Button
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BlocProvider.value(
                            value: context.read<ProfileCubit>(),
                            child: const EditProfileScreen(),
                          ),
                    ),
                  );
                },
                icon: Icon(Icons.edit, color: AppColors.primary),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(ProfileLoaded state) {
    final earnings = state.driver?['earnings'] ?? {};

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Günlük Gəlir',
            '${earnings['today']?.toString() ?? '0'} AZN',
            Icons.today,
            AppColors.success,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildStatCard(
            'Həftəlik Gəlir',
            '${earnings['thisWeek']?.toString() ?? '0'} AZN',
            Icons.date_range,
            AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTheme.heading3.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: AppTheme.caption.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(ProfileLoaded state) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Şəxsi Məlumatlar',
            style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            'Ad Soyad',
            state.user['name'] ?? 'Məlumat yoxdur',
            Icons.person,
          ),
          _buildInfoRow(
            'Telefon',
            state.user['phone'] ?? 'Məlumat yoxdur',
            Icons.phone,
          ),
          _buildInfoRow(
            'Email',
            state.user['email'] ?? 'Məlumat yoxdur',
            Icons.email,
          ),
          _buildInfoRow(
            'Qeydiyyat Tarixi',
            _formatDate(state.user['createdAt']),
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          'Profil Məlumatlarını Yenilə',
          Icons.edit,
          AppColors.primary,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => BlocProvider.value(
                      value: context.read<ProfileCubit>(),
                      child: const EditProfileScreen(),
                    ),
              ),
            );
          },
        ),
        SizedBox(height: 12.h),
        _buildActionButton(
          'Gəlir Hesabatı',
          Icons.account_balance_wallet,
          AppColors.success,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => BlocProvider.value(
                      value: context.read<ProfileCubit>(),
                      child: const EarningsScreen(),
                    ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          'Çıxış',
          style: AppTheme.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
          SizedBox(height: 16.h),
          Text(
            'Xəta baş verdi',
            style: AppTheme.heading3.copyWith(color: AppColors.error),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              context.read<ProfileCubit>().loadProfile();
            },
            child: Text('Yenidən cəhd et'),
          ),
        ],
      ),
    );
  }

  void _showImagePicker(ProfileLoaded state) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Profil şəkli seçin', style: AppTheme.heading3),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageOption('Kamera', Icons.camera_alt, () {
                      Navigator.pop(context);
                      // TODO: Implement camera picker
                    }),
                    _buildImageOption('Qalereya', Icons.photo_library, () {
                      Navigator.pop(context);
                      // TODO: Implement gallery picker
                    }),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildImageOption(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32.sp, color: AppColors.primary),
            SizedBox(height: 8.h),
            Text(title, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Çıxış'),
            content: Text('Hesabınızdan çıxmaq istədiyinizə əminsiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Ləğv et'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<ProfileCubit>().logout();
                },
                child: Text('Çıxış', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      case 'suspended':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'approved':
        return 'Təsdiqlənib';
      case 'pending':
        return 'Gözləyir';
      case 'rejected':
        return 'Rədd edilib';
      case 'suspended':
        return 'Dayandırılıb';
      default:
        return 'Naməlum';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Məlumat yoxdur';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Məlumat yoxdur';
    }
  }
}
