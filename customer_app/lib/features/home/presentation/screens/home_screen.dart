import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../orders/presentation/screens/order_creation_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayiq Sürücü'),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      _showLogoutDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: AppColors.error),
                          SizedBox(width: 8.w),
                          const Text('Çıxış'),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        state.user.name.isNotEmpty 
                            ? state.user.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Message
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xoş gəlmisiniz, ${state.user.name}!',
                          style: AppTheme.titleLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Taksi sifariş etmək üçün aşağıdakı düyməni basın',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            SizedBox(height: 24.h),
            
            // Quick Actions
            Text(
              'Sürətli əməliyyatlar',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context: context,
                    icon: Icons.local_taxi,
                    title: 'Taksi sifariş et',
                    subtitle: 'Yeni sifariş yarat',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const OrderCreationScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildQuickActionCard(
                    context: context,
                    icon: Icons.history,
                    title: 'Sifariş tarixçəsi',
                    subtitle: 'Keçmiş sifarişlər',
                    onTap: () {
                      // TODO: Navigate to order history
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sifariş tarixçəsi tezliklə'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context: context,
                    icon: Icons.person,
                    title: 'Profil',
                    subtitle: 'Hesab məlumatları',
                    onTap: () {
                      // TODO: Navigate to profile
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil tezliklə'),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildQuickActionCard(
                    context: context,
                    icon: Icons.support_agent,
                    title: 'Dəstək',
                    subtitle: 'Kömək və dəstək',
                    onTap: () {
                      // TODO: Navigate to support
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dəstək tezliklə'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Main Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OrderCreationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.local_taxi),
                label: Text(
                  'Taksi sifariş et',
                  style: AppTheme.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32.sp,
                color: AppColors.primary,
              ),
              SizedBox(height: 8.h),
              Text(
                title,
                style: AppTheme.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
}
