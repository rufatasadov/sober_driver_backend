import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          context.watch<LanguageProvider>().getString('selectLanguage'),
          style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.language, color: AppColors.primary, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        context.watch<LanguageProvider>().getString('language'),
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Language Options
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  final languageOptions = languageProvider.getLanguageOptions();

                  return Column(
                    children:
                        languageOptions.map((option) {
                          final isSelected =
                              option['code'] ==
                              languageProvider.currentLanguage;

                          return Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primary.withOpacity(0.1)
                                      : AppColors.surface,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.language,
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                              ),
                              title: Text(
                                option['name']!,
                                style: AppTheme.bodyMedium.copyWith(
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                ),
                              ),
                              trailing:
                                  isSelected
                                      ? Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                      )
                                      : null,
                              onTap: () async {
                                await languageProvider.setLanguage(
                                  option['code']!,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          );
                        }).toList(),
                  );
                },
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
                        context.watch<LanguageProvider>().getString('language'),
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
    );
  }
}
