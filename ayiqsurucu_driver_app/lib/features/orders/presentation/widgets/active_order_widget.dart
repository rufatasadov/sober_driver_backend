import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import '../cubit/orders_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class ActiveOrderWidget extends StatefulWidget {
  final Order order;
  final VoidCallback? onViewDetails;
  final VoidCallback? onUpdateStatus;

  const ActiveOrderWidget({
    super.key,
    required this.order,
    this.onViewDetails,
    this.onUpdateStatus,
  });

  @override
  State<ActiveOrderWidget> createState() => _ActiveOrderWidgetState();
}

class _ActiveOrderWidgetState extends State<ActiveOrderWidget> {
  Timer? _timer;
  int _elapsedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _calculateElapsedTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateElapsedTime() {
    final now = DateTime.now();
    // Use updatedAt if available (last status update), otherwise use createdAt
    final referenceTime = widget.order.updatedAt ?? widget.order.createdAt;
    _elapsedMinutes = now.difference(referenceTime).inMinutes;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedMinutes++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 184, 231, 186).withOpacity(0.1),
            const Color.fromARGB(255, 112, 114, 112).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.local_shipping,
                  color: AppColors.textOnPrimary,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sifariş #${widget.order.orderNumber}',
                      style: AppTheme.bodyMedium.copyWith(
                        //      color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_elapsedMinutes dəq',
                      style: AppTheme.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      widget.order.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _getStatusText(widget.order.status),
                    style: AppTheme.caption.copyWith(
                      color: _getStatusColor(widget.order.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 10.sp,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Compact Order Details
          Row(
            children: [
              // Pickup
              Expanded(
                child: _buildCompactLocation(
                  icon: Icons.my_location,
                  label: Provider.of<LanguageProvider>(
                    context,
                  ).getString('pickup'),
                  address:
                      widget.order.pickup['address'] ??
                      Provider.of<LanguageProvider>(
                        context,
                      ).getString('noAddress'),
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: 8.w),
              // Destination
              Expanded(
                child: _buildCompactLocation(
                  icon: Icons.location_on,
                  label: Provider.of<LanguageProvider>(
                    context,
                  ).getString('delivery'),
                  address:
                      widget.order.destination['address'] ??
                      Provider.of<LanguageProvider>(
                        context,
                      ).getString('noAddress'),
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Compact Info Row
          Row(
            children: [
              // Fare
              Expanded(
                child: _buildCompactInfo(
                  icon: Icons.monetization_on,
                  value: '${widget.order.fare.toStringAsFixed(2)} ₼',
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: 8.w),
              // Distance
              Expanded(
                child: _buildCompactInfo(
                  icon: Icons.straighten,
                  value:
                      '${widget.order.estimatedDistance?.toStringAsFixed(1) ?? '0.0'} km',
                  color: AppColors.info,
                ),
              ),
              SizedBox(width: 8.w),
              // Payment
              Expanded(
                child: _buildCompactInfo(
                  icon: Icons.payment,
                  value: widget.order.paymentMethod == 'cash' ? 'Nağd' : 'Kart',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),

          // Customer Info (if available)
          if (widget.order.customer != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primary, size: 14.sp),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    '${widget.order.customer!['name'] ?? 'N/A'}',
                    style: AppTheme.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.order.customerPhone != null)
                  GestureDetector(
                    onTap: () => _makePhoneCall(widget.order.customerPhone!),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Icon(
                        Icons.phone,
                        color: AppColors.textOnPrimary,
                        size: 12.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          SizedBox(height: 8.h),

          // Compact Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onViewDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    Provider.of<LanguageProvider>(context).getString('details'),
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onUpdateStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    _getStatusText(widget.order.status),
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLocation({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 12.sp),
              SizedBox(width: 4.w),
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            address,
            style: AppTheme.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 10.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfo({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(height: 2.h),
          Text(
            value,
            style: AppTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success;
      case 'driver_assigned':
        return AppColors.info;
      case 'driver_arrived':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    switch (status) {
      case 'accepted':
        return languageProvider.getString('accepted');
      case 'driver_assigned':
        return languageProvider.getString('driverAssigned');
      case 'driver_arrived':
        return languageProvider.getString('driverArrived');
      case 'in_progress':
        return languageProvider.getString('inProgress');
      case 'completed':
        return languageProvider.getString('completed');
      case 'cancelled':
        return languageProvider.getString('cancelled');
      default:
        return status;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        print('Could not launch phone call to: $phoneNumber');
      }
    } catch (e) {
      print('Error making phone call: $e');
    }
  }
}
