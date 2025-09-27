import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/orders_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class WoltStyleActiveOrder extends StatefulWidget {
  final Order order;
  final VoidCallback? onViewDetails;
  final Function(String)? onStatusUpdate;

  const WoltStyleActiveOrder({
    super.key,
    required this.order,
    this.onViewDetails,
    this.onStatusUpdate,
  });

  @override
  State<WoltStyleActiveOrder> createState() => _WoltStyleActiveOrderState();
}

class _WoltStyleActiveOrderState extends State<WoltStyleActiveOrder>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _timer;
  int _elapsedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    _calculateElapsedTime();
    _startTimer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _calculateElapsedTime() {
    final now = DateTime.now();
    _elapsedMinutes = now.difference(widget.order.createdAt).inMinutes;
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
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 255, 255, 255).withOpacity(0.15),
            const Color.fromARGB(255, 255, 255, 255).withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: 3,
          ),
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          // Header with status and ETA
          _buildHeader(),

          // Order details
          _buildOrderDetails(),

          // Status update buttons
          _buildStatusButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          // Animated status icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: AppColors.textOnPrimary,
                    size: 20.sp,
                  ),
                ),
              );
            },
          ),

          SizedBox(width: 12.w),

          // Order info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktiv Sifariş',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Sifariş #${widget.order.orderNumber}',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ETA and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _getStatusColor().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusText(),
                  style: AppTheme.caption.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              // Elapsed time
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 14.sp, color: AppColors.warning),
                    SizedBox(width: 4.w),
                    Text(
                      '$_elapsedMinutes dəq',
                      style: AppTheme.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.order.etaMinutes != null) ...[
                SizedBox(height: 2.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${widget.order.etaMinutes} dəq',
                      style: AppTheme.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Pickup location
          _buildLocationRow(
            icon: Icons.my_location,
            address: widget.order.pickup['address'] ?? 'Ünvan yoxdur',
            color: AppColors.success,
            isPickup: true,
          ),

          SizedBox(height: 12.h),

          // Destination
          _buildLocationRow(
            icon: Icons.location_on,
            address: widget.order.destination['address'] ?? 'Ünvan yoxdur',
            color: AppColors.primary,
            isPickup: false,
          ),

          SizedBox(height: 16.h),

          // Order summary
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                // Distance
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.straighten,
                    label: 'Məsafə',
                    value:
                        '${widget.order.estimatedDistance?.toStringAsFixed(1) ?? '0.0'} km',
                    color: AppColors.info,
                  ),
                ),

                Container(width: 1, height: 30.h, color: AppColors.border),

                // Fare
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.monetization_on,
                    label: 'Qiymət',
                    value: '${widget.order.fare.toStringAsFixed(2)} ₼',
                    color: AppColors.success,
                  ),
                ),

                Container(width: 1, height: 30.h, color: AppColors.border),

                // Payment method
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.payment,
                    label: 'Ödəniş',
                    value:
                        widget.order.paymentMethod == 'cash' ? 'Nağd' : 'Kart',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Customer info if available
          if (widget.order.customer != null) ...[
            SizedBox(height: 12.h),
            _buildCustomerInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String address,
    required Color color,
    required bool isPickup,
  }) {
    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPickup ? 'Götürmə' : 'Təhvil',
                style: AppTheme.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                address,
                style: AppTheme.bodyMedium.copyWith(
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

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16.sp),
        SizedBox(height: 4.h),
        Text(
          label,
          style: AppTheme.caption.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: AppColors.primary, size: 16.sp),
          SizedBox(width: 8.w),
          Text(
            'Müştəri: ${widget.order.customer!['name'] ?? 'N/A'}',
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.order.customerPhone != null) ...[
            Spacer(),
            GestureDetector(
              onTap: () => _makePhoneCall(widget.order.customerPhone!),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone,
                  color: AppColors.textOnPrimary,
                  size: 16.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusButtons() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          // View details button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onViewDetails,
              icon: Icon(Icons.visibility, size: 16.sp),
              label: Text('Ətraflı'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Quick status update button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _showQuickStatusUpdate(),
              icon: Icon(Icons.update, size: 16.sp),
              label: Text(_getNextStatusText()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(),
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickStatusUpdate() {
    final nextStatus = _getNextStatus();
    if (nextStatus != null) {
      widget.onStatusUpdate?.call(nextStatus);
    }
  }

  Color _getStatusColor() {
    switch (widget.order.status) {
      case 'accepted':
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

  IconData _getStatusIcon() {
    switch (widget.order.status) {
      case 'accepted':
      case 'driver_assigned':
        return Icons.directions_car;
      case 'driver_arrived':
        return Icons.location_on;
      case 'in_progress':
        return Icons.local_taxi;
      default:
        return Icons.assignment;
    }
  }

  String _getStatusText() {
    switch (widget.order.status) {
      case 'accepted':
        return 'Qəbul Edildi';
      case 'driver_assigned':
        return 'Sürücü Təyin Edildi';
      case 'driver_arrived':
        return 'Çatdı';
      case 'in_progress':
        return 'Gedişdə';
      default:
        return widget.order.status;
    }
  }

  String _getNextStatusText() {
    switch (widget.order.status) {
      case 'accepted':
      case 'driver_assigned':
        return 'Çatdım';
      case 'driver_arrived':
        return 'Gedişdə';
      case 'in_progress':
        return 'Tamamladım';
      default:
        return 'Yenilə';
    }
  }

  String? _getNextStatus() {
    switch (widget.order.status) {
      case 'accepted':
      case 'driver_assigned':
        return 'driver_arrived';
      case 'driver_arrived':
        return 'in_progress';
      case 'in_progress':
        return 'completed';
      default:
        return null;
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
