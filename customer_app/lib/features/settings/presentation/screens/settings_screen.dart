import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _language = 'az';
  String _theme = 'light';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _locationEnabled = prefs.getBool('location_enabled') ?? true;
      _language = prefs.getString('language') ?? 'az';
      _theme = prefs.getString('theme') ?? 'light';
    });
  }

  Future<void> _saveNotificationsSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _saveLocationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_enabled', value);
    setState(() {
      _locationEnabled = value;
    });
  }

  Future<void> _saveLanguageSetting(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    setState(() {
      _language = value;
    });
  }

  Future<void> _saveThemeSetting(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', value);
    setState(() {
      _theme = value;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıxış'),
        content: const Text('Hesabınızdan çıxmaq istədiyinizə əminsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ləğv et'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthCubit>().logout();
            },
            child: const Text(
              'Çıx',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keş təmizlə'),
        content: const Text('Keş təmizləmək istədiyinizə əminsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ləğv et'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement cache clearing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Keş təmizləndi'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Təmizlə'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tənzimləmələr'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // App Settings
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tətbiq tənzimləmələri',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // Notifications
                  _buildSwitchTile(
                    icon: Icons.notifications,
                    title: 'Bildirişlər',
                    subtitle: 'Sifariş yeniləmələri və bildirişlər',
                    value: _notificationsEnabled,
                    onChanged: _saveNotificationsSetting,
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Location
                  _buildSwitchTile(
                    icon: Icons.location_on,
                    title: 'Yer məlumatları',
                    subtitle: 'Avtomatik yer təyin etmə',
                    value: _locationEnabled,
                    onChanged: _saveLocationSetting,
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Language
                  _buildDropdownTile(
                    icon: Icons.language,
                    title: 'Dil',
                    subtitle: 'Tətbiq dili',
                    value: _language,
                    items: const [
                      {'value': 'az', 'label': 'Azərbaycan'},
                      {'value': 'en', 'label': 'English'},
                      {'value': 'ru', 'label': 'Русский'},
                    ],
                    onChanged: _saveLanguageSetting,
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Theme
                  _buildDropdownTile(
                    icon: Icons.palette,
                    title: 'Mövzu',
                    subtitle: 'Tətbiq görünüşü',
                    value: _theme,
                    items: const [
                      {'value': 'light', 'label': 'Açıq'},
                      {'value': 'dark', 'label': 'Tünd'},
                      {'value': 'system', 'label': 'Sistem'},
                    ],
                    onChanged: _saveThemeSetting,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Privacy & Security
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Məxfilik və təhlükəsizlik',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  _buildListTile(
                    icon: Icons.privacy_tip,
                    title: 'Məxfilik siyasəti',
                    subtitle: 'Məlumatlarınızın istifadəsi',
                    onTap: () {
                      // TODO: Open privacy policy
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Məxfilik siyasəti tezliklə'),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  _buildListTile(
                    icon: Icons.security,
                    title: 'İstifadə şərtləri',
                    subtitle: 'Xidmət şərtləri',
                    onTap: () {
                      // TODO: Open terms of service
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('İstifadə şərtləri tezliklə'),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  _buildListTile(
                    icon: Icons.lock,
                    title: 'Şifrə dəyişdir',
                    subtitle: 'Hesab təhlükəsizliyi',
                    onTap: () {
                      // TODO: Change password
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Şifrə dəyişdirilməsi tezliklə'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Storage & Cache
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saxlama və keş',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  _buildListTile(
                    icon: Icons.storage,
                    title: 'Keş təmizlə',
                    subtitle: 'Tətbiq məlumatlarını təmizlə',
                    onTap: _clearCache,
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  _buildListTile(
                    icon: Icons.delete_forever,
                    title: 'Məlumatları sil',
                    subtitle: 'Bütün məlumatları sil',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Məlumatları sil'),
                          content: const Text('Bütün məlumatları silmək istədiyinizə əminsiniz? Bu əməliyyat geri alına bilməz.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Ləğv et'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // TODO: Clear all data
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Məlumatlar silindi'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                              child: const Text(
                                'Sil',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Account Actions
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hesab əməliyyatları',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  _buildListTile(
                    icon: Icons.info,
                    title: 'Tətbiq haqqında',
                    subtitle: 'Versiya və məlumat',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Ayiq Sürücü',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.local_taxi,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        children: [
                          const Text('Taksi sifariş etmək üçün mobil tətbiq'),
                        ],
                      );
                    },
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  _buildListTile(
                    icon: Icons.logout,
                    title: 'Çıxış',
                    subtitle: 'Hesabdan çıx',
                    onTap: _showLogoutDialog,
                    textColor: AppColors.error,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        DropdownButton<String>(
          value: value,
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(item['label']!),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor ?? AppColors.primary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
