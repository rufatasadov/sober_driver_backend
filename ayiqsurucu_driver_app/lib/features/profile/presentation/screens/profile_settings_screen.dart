import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _isOnline = false;
  bool _isAvailable = false;
  bool _notificationsEnabled = true;
  bool _locationTrackingEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  void _loadSettings() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final driver = profileProvider.driver;

    if (driver != null) {
      setState(() {
        _isOnline = driver['isOnline'] ?? false;
        _isAvailable = driver['isAvailable'] ?? false;
      });
    }
  }

  Future<void> _updateDriverStatus() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    final success = await profileProvider.updateDriverStatus(
      isOnline: _isOnline,
      isAvailable: _isAvailable,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status uğurla yeniləndi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        _showErrorDialog(profileProvider.error ?? 'Status yenilənmədi');
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Çıxış'),
            content: const Text('Hesabınızdan çıxmaq istədiyinizə əminsiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ləğv et'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Provider.of<ProfileProvider>(context, listen: false).logout();
                },
                child: const Text(
                  'Çıxış',
                  style: TextStyle(color: AppColors.error),
                ),
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
          'Tənzimləmələr',
          style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Driver Status Section
            _buildSection('Sürücü Statusu', Icons.drive_eta, [
              _buildSwitchTile(
                'Online Status',
                'Sürücü kimi online görün',
                _isOnline,
                (value) {
                  setState(() {
                    _isOnline = value;
                    if (!value) {
                      _isAvailable = false;
                    }
                  });
                  _updateDriverStatus();
                },
              ),
              _buildSwitchTile(
                'Mövcudluq',
                'Yeni sifarişlər qəbul et',
                _isAvailable,
                _isOnline
                    ? (value) {
                      setState(() {
                        _isAvailable = value;
                      });
                      _updateDriverStatus();
                    }
                    : null,
              ),
            ]),

            SizedBox(height: 32.h),

            // Notifications Section
            _buildSection('Bildirişlər', Icons.notifications, [
              _buildSwitchTile(
                'Push Bildirişləri',
                'Yeni sifarişlər və yeniləmələr üçün bildirişlər',
                _notificationsEnabled,
                (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  // TODO: Update notification settings
                },
              ),
            ]),

            SizedBox(height: 32.h),

            // Privacy Section
            _buildSection('Məxfilik', Icons.privacy_tip, [
              _buildSwitchTile(
                'Yer İzləmə',
                'Real-time yer paylaşımı',
                _locationTrackingEnabled,
                (value) {
                  setState(() {
                    _locationTrackingEnabled = value;
                  });
                  // TODO: Update location tracking settings
                },
              ),
            ]),

            SizedBox(height: 32.h),

            // Account Section
            _buildSection('Hesab', Icons.account_circle, [
              _buildListTile(
                'Şifrəni Dəyiş',
                'Hesab şifrənizi yeniləyin',
                Icons.lock,
                () {
                  // TODO: Navigate to change password screen
                },
              ),
              _buildListTile(
                'Hesab Məlumatları',
                'Şəxsi məlumatlarınızı yeniləyin',
                Icons.person,
                () {
                  Navigator.pop(context);
                  // Navigate to edit profile screen
                },
              ),
            ]),

            SizedBox(height: 32.h),

            // Support Section
            _buildSection('Dəstək', Icons.help, [
              _buildListTile(
                'Kömək və Dəstək',
                'Suallarınız üçün bizimlə əlaqə saxlayın',
                Icons.help_outline,
                () {
                  // TODO: Navigate to help screen
                },
              ),
              _buildListTile(
                'Haqqımızda',
                'Tətbiq haqqında məlumat',
                Icons.info_outline,
                () {
                  // TODO: Navigate to about screen
                },
              ),
              _buildListTile(
                'Şərtlər və Qaydalar',
                'İstifadə şərtləri',
                Icons.description,
                () {
                  // TODO: Navigate to terms screen
                },
              ),
            ]),

            SizedBox(height: 32.h),

            // Logout Button
            Container(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _showLogoutDialog,
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
            ),

            SizedBox(height: 24.h),

            // App Version
            Center(
              child: Text(
                'Versiya 1.0.0',
                style: AppTheme.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return ListTile(
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20.sp),
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.textSecondary,
        size: 16.sp,
      ),
      onTap: onTap,
    );
  }
}
