import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import 'package:provider/provider.dart';
import '../cubit/orders_cubit.dart';

class AnimatedOrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  final bool isUpdating;
  final String? updatingStatus;

  const AnimatedOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.actions,
    this.isUpdating = false,
    this.updatingStatus,
  });

  @override
  State<AnimatedOrderCard> createState() => _AnimatedOrderCardState();
}

class _AnimatedOrderCardState extends State<AnimatedOrderCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    if (widget.isUpdating) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isUpdating && !oldWidget.isUpdating) {
      _shimmerController.repeat();
      _scaleController.forward();
    } else if (!widget.isUpdating && oldWidget.isUpdating) {
      _shimmerController.stop();
      _scaleController.reverse();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _shimmerAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color:
                  widget.isUpdating
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color:
                    widget.isUpdating
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.textSecondary.withOpacity(0.2),
                width: widget.isUpdating ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      widget.isUpdating
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                  blurRadius: widget.isUpdating ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Shimmer effect for updating state
                if (widget.isUpdating)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                AppColors.primary.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: [
                                _shimmerAnimation.value - 0.3,
                                _shimmerAnimation.value,
                                _shimmerAnimation.value + 0.3,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Main content
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with order number and status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${languageProvider.getString('orderNumber')}: ${widget.order.orderNumber}',
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    widget.isUpdating
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.order.status),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.isUpdating) ...[
                                  SizedBox(
                                    width: 12.w,
                                    height: 12.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                ],
                                Text(
                                  _getStatusText(
                                    widget.order.status,
                                    languageProvider,
                                  ),
                                  style: AppTheme.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      // Pickup location
                      _buildLocationRow(
                        Icons.location_on,
                        languageProvider.getString('pickup'),
                        widget.order.pickup['address'] ?? 'N/A',
                        AppColors.success,
                      ),

                      SizedBox(height: 8.h),

                      // Destination
                      _buildLocationRow(
                        Icons.flag,
                        languageProvider.getString('destination'),
                        widget.order.destination['address'] ?? 'N/A',
                        AppColors.error,
                      ),

                      SizedBox(height: 12.h),

                      // Fare and customer info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${languageProvider.getString('fare')}: ${widget.order.fare.toStringAsFixed(2)} ₼',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '${languageProvider.getString('customer')}: ${widget.order.customer?['name'] ?? 'N/A'}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      // Actions
                      if (widget.actions != null &&
                          widget.actions!.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        Row(
                          children:
                              widget.actions!
                                  .map((action) => Expanded(child: action))
                                  .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        Icon(icon, color: color, size: 16.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                address,
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textPrimary,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
      case 'in_progress':
      case 'driver_assigned':
      case 'driver_arrived':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status, LanguageProvider languageProvider) {
    switch (status) {
      case 'pending':
        return languageProvider.getString('pending');
      case 'accepted':
        return languageProvider.getString('accepted');
      case 'in_progress':
        return languageProvider.getString('inProgress');
      case 'driver_assigned':
        return languageProvider.getString('driverAssigned');
      case 'driver_arrived':
        return languageProvider.getString('driverArrived');
      case 'completed':
        return languageProvider.getString('completed');
      case 'cancelled':
        return languageProvider.getString('cancelled');
      default:
        return status;
    }
  }
}
