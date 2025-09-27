import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/orders_cubit.dart';

class NewOrderNotificationWidget extends StatefulWidget {
  final Order order;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onDismiss;

  const NewOrderNotificationWidget({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
    required this.onDismiss,
  });

  @override
  State<NewOrderNotificationWidget> createState() =>
      _NewOrderNotificationWidgetState();
}

class _NewOrderNotificationWidgetState extends State<NewOrderNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.textOnPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.local_taxi_rounded,
                            color: AppColors.textOnPrimary,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yeni Sifariş! 🚗',
                                style: AppTheme.heading3.copyWith(
                                  color: AppColors.textOnPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Sifariş #${widget.order.orderNumber}',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppColors.textOnPrimary.withOpacity(
                                    0.9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onDismiss,
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textOnPrimary,
                            size: 20.sp,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // Order Details
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          // Pickup Location
                          _buildLocationRow(
                            Icons.my_location_rounded,
                            'Götürülmə yeri',
                            widget.order.pickup['address'] ?? 'Məlumat yoxdur',
                            AppColors.success,
                          ),
                          SizedBox(height: 12.h),
                          // Destination
                          _buildLocationRow(
                            Icons.location_on_rounded,
                            'Təyinat yeri',
                            widget.order.destination['address'] ??
                                'Məlumat yoxdur',
                            AppColors.error,
                          ),
                          SizedBox(height: 16.h),
                          // Fare and Customer
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.textOnPrimary.withOpacity(
                                      0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Qiymət',
                                        style: AppTheme.caption.copyWith(
                                          color: AppColors.textOnPrimary
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        '${widget.order.fare.toStringAsFixed(2)} ₼',
                                        style: AppTheme.bodyLarge.copyWith(
                                          color: AppColors.textOnPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.textOnPrimary.withOpacity(
                                      0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Müştəri',
                                        style: AppTheme.caption.copyWith(
                                          color: AppColors.textOnPrimary
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        widget.order.customer?['name'] ??
                                            'Müştəri',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppColors.textOnPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onReject,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.textOnPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close_rounded, size: 18.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  'Rədd Et',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.textOnPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 18.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  'Qəbul Et',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    String label,
    String address,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(icon, color: color, size: 16.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: AppColors.textOnPrimary.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                address,
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
