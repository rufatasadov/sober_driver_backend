import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';

class AnimatedBalanceWidget extends StatefulWidget {
  final double balance;
  final double todayEarnings;
  final bool isUpdating;

  const AnimatedBalanceWidget({
    super.key,
    required this.balance,
    required this.todayEarnings,
    this.isUpdating = false,
  });

  @override
  State<AnimatedBalanceWidget> createState() => _AnimatedBalanceWidgetState();
}

class _AnimatedBalanceWidgetState extends State<AnimatedBalanceWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _colorController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: AppColors.primary,
      end: AppColors.success,
    ).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );

    if (widget.isUpdating) {
      _pulseController.repeat(reverse: true);
      _colorController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedBalanceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isUpdating && !oldWidget.isUpdating) {
      _pulseController.repeat(reverse: true);
      _colorController.forward();
    } else if (!widget.isUpdating && oldWidget.isUpdating) {
      _pulseController.stop();
      _colorController.reverse();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _colorAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 0),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (_colorAnimation.value ?? AppColors.primary).withOpacity(
                      0.05,
                    ),
                    (_colorAnimation.value ?? AppColors.primary).withOpacity(
                      0.02,
                    ),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: (_colorAnimation.value ?? AppColors.primary)
                      .withOpacity(0.15),
                  width: widget.isUpdating ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_colorAnimation.value ?? AppColors.primary)
                        .withOpacity(0.08),
                    blurRadius: widget.isUpdating ? 12 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: _colorAnimation.value ?? AppColors.primary,
                              size: 16.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              languageProvider.getString('balance'),
                              style: AppTheme.bodySmall.copyWith(
                                color:
                                    _colorAnimation.value ?? AppColors.primary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (widget.isUpdating) ...[
                              SizedBox(width: 8.w),
                              SizedBox(
                                width: 12.w,
                                height: 12.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _colorAnimation.value ?? AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          '${widget.balance.toStringAsFixed(2)} ₼',
                          style: AppTheme.heading3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.sp,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${languageProvider.getString('today')}: ${widget.todayEarnings.toStringAsFixed(2)} ₼',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (_colorAnimation.value ?? AppColors.primary)
                              .withOpacity(0.1),
                          (_colorAnimation.value ?? AppColors.primary)
                              .withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: (_colorAnimation.value ?? AppColors.primary)
                            .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: _colorAnimation.value ?? AppColors.primary,
                      size: 18.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
