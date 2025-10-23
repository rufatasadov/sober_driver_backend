import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyWidget extends StatefulWidget {
  final bool isAccepted;
  final ValueChanged<bool> onChanged;

  const PrivacyPolicyWidget({
    super.key,
    required this.isAccepted,
    required this.onChanged,
  });

  @override
  State<PrivacyPolicyWidget> createState() => _PrivacyPolicyWidgetState();
}

class _PrivacyPolicyWidgetState extends State<PrivacyPolicyWidget> {
  String _privacyPolicyText = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    try {
      final String policyText = await rootBundle.loadString(
        'driver_privacy_policy.txt',
      );
      setState(() {
        _privacyPolicyText = policyText;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _privacyPolicyText = 'Privacy policy could not be loaded.';
        _isLoading = false;
      });
    }
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                SizedBox(width: 8.w),
                Text(
                  'Terms and Conditions',
                  style: AppTheme.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400.h,
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                      : SingleChildScrollView(
                        child: Text(
                          _privacyPolicyText,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: AppTheme.bodyMedium.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color:
              widget.isAccepted
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.textSecondary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color:
                    widget.isAccepted
                        ? AppColors.success
                        : AppColors.textSecondary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Terms and Conditions',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Description
          Text(
            'By registering as a driver, you agree to our terms and conditions. Please read them carefully before proceeding.',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),

          SizedBox(height: 12.h),

          // Checkbox and View Terms button
          Row(
            children: [
              // Checkbox
              Checkbox(
                value: widget.isAccepted,
                onChanged: (value) => widget.onChanged(value ?? false),
                activeColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),

              SizedBox(width: 8.w),

              // Accept text
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onChanged(!widget.isAccepted),
                  child: Text(
                    'I accept the terms and conditions',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              // View Terms button
              TextButton(
                onPressed: _showPrivacyPolicyDialog,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View Terms',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          // Status indicator
          if (widget.isAccepted) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 14.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Terms accepted',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
