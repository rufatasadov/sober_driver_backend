import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/map_widget.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/waiting_timer_widget.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Sifariş #${widget.order.orderNumber}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Section
            Container(
              height: 300.h,
              margin: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: MapWidget(
                  center: _getMapCenter(),
                  zoom: 14.0,
                  markers: _getMapMarkers(),
                  polylines: _getPolylines(),
                  showLocationButton: true,
                ),
              ),
            ),

            // Order Details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              widget.order.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Icon(
                            _getStatusIcon(widget.order.status),
                            color: _getStatusColor(widget.order.status),
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _getStatusText(widget.order.status),
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(widget.order.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Price Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success,
                          AppColors.success.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sifariş Qiyməti',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppColors.textOnPrimary.withOpacity(0.8),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${widget.order.fare.toStringAsFixed(2)} AZN',
                              style: AppTheme.heading2.copyWith(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.textOnPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.attach_money,
                            color: AppColors.textOnPrimary,
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Customer Info Card (if available)
                  if (widget.order.customerId.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Müştəri Məlumatları', style: AppTheme.heading3),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.order.customer?['name'] ??
                                          'Müştəri',
                                      style: AppTheme.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (widget.order.customerPhone != null) ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        widget.order.customerPhone!,
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (widget.order.customerPhone != null)
                                IconButton(
                                  onPressed:
                                      () => _makePhoneCall(
                                        widget.order.customerPhone!,
                                      ),
                                  icon: Icon(
                                    Icons.phone,
                                    color: AppColors.success,
                                    size: 24.sp,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 16.h),

                  // Payment Method Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payment,
                          color: AppColors.warning,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ödəniş Metodu',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                widget.order.paymentMethod == 'cash'
                                    ? 'Nağd'
                                    : widget.order.paymentMethod,
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // ETA Card (if available)
                  if (widget.order.etaMinutes != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.info.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppColors.info,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Çatma Vaxtı',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '${widget.order.etaMinutes} dəqiqə',
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 16.h),

                  // Locations Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Məkanlar', style: AppTheme.heading3),
                        SizedBox(height: 16.h),

                        // Pickup
                        Row(
                          children: [
                            Container(
                              width: 12.w,
                              height: 12.w,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Qalxış nöqtəsi',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    widget.order.pickup['address'] ??
                                        'Məlumat yoxdur',
                                    style: AppTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.h),

                        // Destination
                        Row(
                          children: [
                            Container(
                              width: 12.w,
                              height: 12.w,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Məqsəd',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    widget.order.destination['address'] ??
                                        'Məlumat yoxdur',
                                    style: AppTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Order Info Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sifariş Məlumatları', style: AppTheme.heading3),
                        SizedBox(height: 16.h),

                        _buildInfoRow('Sifariş №', widget.order.orderNumber),
                        _buildInfoRow(
                          'Məsafə',
                          widget.order.estimatedDistance != null
                              ? '${widget.order.estimatedDistance!.toStringAsFixed(1)} km'
                              : 'Məlumat yoxdur',
                        ),
                        _buildInfoRow(
                          'Təxmini vaxt',
                          widget.order.estimatedTime != null
                              ? '${widget.order.estimatedTime!.toStringAsFixed(0)} dəqiqə'
                              : 'Məlumat yoxdur',
                        ),
                        _buildInfoRow(
                          'Ödəniş',
                          '${widget.order.fare.toStringAsFixed(2)} ₼',
                        ),
                        _buildInfoRow(
                          'Ödəniş üsulu',
                          widget.order.paymentMethod,
                        ),
                        _buildInfoRow(
                          'Tarix',
                          _formatDateTime(widget.order.createdAt),
                        ),
                        if (widget.order.updatedAt != null)
                          _buildInfoRow(
                            'Son yenilənmə',
                            _formatDateTime(widget.order.updatedAt!),
                          ),
                        _buildInfoRow(
                          'Yaradılma vaxtı',
                          _formatDetailedDateTime(widget.order.createdAt),
                        ),
                        if (widget.order.updatedAt != null)
                          _buildInfoRow(
                            'Yenilənmə vaxtı',
                            _formatDetailedDateTime(widget.order.updatedAt!),
                          ),

                        if (widget.order.notes != null &&
                            widget.order.notes!.isNotEmpty) ...[
                          SizedBox(height: 12.h),
                          Text(
                            'Qeydlər',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(widget.order.notes!, style: AppTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Action Buttons
                  if (_shouldShowActionButtons()) _buildActionButtons(),

                  // Waiting Timer (if driver has arrived)
                  if (widget.order.status == 'driver_arrived')
                    WaitingTimerWidget(
                      freeWaitingMinutes:
                          5, // Admin tərəfindən təyin olunan pulsuz dəqiqələr
                      paidWaitingRatePerMinute:
                          0.5, // Admin tərəfindən təyin olunan hər dəqiqəyə ödəniş
                      onTimerComplete: () {
                        // Müştəri gəldikdə timer dayanır
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gözləmə vaxtı tamamlandı'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      onAdditionalFee: (fee) {
                        // Əlavə ödəniş hesablanır
                        print('Əlavə ödəniş: $fee AZN');
                      },
                    ),

                  // Cancel Order Button (if order is accepted but not arrived)
                  if (widget.order.status == 'accepted')
                    Container(
                      width: double.infinity,
                      height: 48.h,
                      margin: EdgeInsets.only(top: 16.h),
                      child: ElevatedButton(
                        onPressed: () => _showCancelOrderDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.textOnPrimary,
                        ),
                        child: Text(
                          'Sifarişi Ləğv Et',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        return Column(
          children: [
            if (widget.order.status == 'accepted') ...[
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed:
                      state is OrdersLoading
                          ? null
                          : () => _updateOrderStatus('driver_arrived'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                  child:
                      state is OrdersLoading
                          ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textOnPrimary,
                              ),
                            ),
                          )
                          : Text(
                            'Müştərinin yanına çatdım',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                ),
              ),
            ],

            if (widget.order.status == 'driver_arrived') ...[
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed:
                      state is OrdersLoading
                          ? null
                          : () => _updateOrderStatus('in_progress'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                  child:
                      state is OrdersLoading
                          ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textOnPrimary,
                              ),
                            ),
                          )
                          : Text(
                            'Səfəri başlat',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                ),
              ),
            ],

            if (widget.order.status == 'in_progress') ...[
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed:
                      state is OrdersLoading
                          ? null
                          : () => _updateOrderStatus('completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                  child:
                      state is OrdersLoading
                          ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textOnPrimary,
                              ),
                            ),
                          )
                          : Text(
                            'Səfəri tamamla',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  bool _shouldShowActionButtons() {
    return widget.order.status == 'accepted' ||
        widget.order.status == 'driver_arrived' ||
        widget.order.status == 'in_progress';
  }

  latlong.LatLng _getMapCenter() {
    final pickup = widget.order.pickup;
    if (pickup['latitude'] != null && pickup['longitude'] != null) {
      return latlong.LatLng(
        pickup['latitude'].toDouble(),
        pickup['longitude'].toDouble(),
      );
    }
    return const latlong.LatLng(40.3777, 49.8516); // Baku center
  }

  List<MapMarker> _getMapMarkers() {
    final markers = <MapMarker>[];

    // Pickup marker
    final pickup = widget.order.pickup;
    if (pickup['latitude'] != null && pickup['longitude'] != null) {
      markers.add(
        MapMarker(
          point: latlong.LatLng(
            pickup['latitude'].toDouble(),
            pickup['longitude'].toDouble(),
          ),
          widget: const PickupMarker(),
        ),
      );
    }

    // Destination marker
    final destination = widget.order.destination;
    if (destination['latitude'] != null && destination['longitude'] != null) {
      markers.add(
        MapMarker(
          point: latlong.LatLng(
            destination['latitude'].toDouble(),
            destination['longitude'].toDouble(),
          ),
          widget: const DestinationMarker(),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _getPolylines() {
    // Simple route line between pickup and destination
    final pickup = widget.order.pickup;
    final destination = widget.order.destination;

    if (pickup['latitude'] != null &&
        pickup['longitude'] != null &&
        destination['latitude'] != null &&
        destination['longitude'] != null) {
      return [
        Polyline(
          points: [
            latlong.LatLng(
              pickup['latitude'].toDouble(),
              pickup['longitude'].toDouble(),
            ),
            latlong.LatLng(
              destination['latitude'].toDouble(),
              destination['longitude'].toDouble(),
            ),
          ],
          strokeWidth: 3.0,
          color: AppColors.primary,
        ),
      ];
    }

    return [];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.info;
      case 'driver_assigned':
        return AppColors.primary;
      case 'driver_arrived':
        return AppColors.success;
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle;
      case 'driver_assigned':
        return Icons.person;
      case 'driver_arrived':
        return Icons.location_on;
      case 'in_progress':
        return Icons.directions_car;
      case 'completed':
        return Icons.check;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Gözləyir';
      case 'accepted':
        return 'Qəbul edildi';
      case 'driver_assigned':
        return 'Sürücü təyin edildi';
      case 'driver_arrived':
        return 'Sürücü gəldi';
      case 'in_progress':
        return 'Hərəkətdə';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'Ləğv edildi';
      default:
        return status;
    }
  }

  String _formatDetailedDateTime(DateTime date) {
    final months = [
      'Yanvar',
      'Fevral',
      'Mart',
      'Aprel',
      'May',
      'İyun',
      'İyul',
      'Avqust',
      'Sentyabr',
      'Oktyabr',
      'Noyabr',
      'Dekabr',
    ];

    final weekdays = [
      'Bazar ertəsi',
      'Çərşənbə axşamı',
      'Çərşənbə',
      'Cümə axşamı',
      'Cümə',
      'Şənbə',
      'Bazar',
    ];

    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateOrderStatus(String status) async {
    final ordersCubit = context.read<OrdersCubit>();
    final success = await ordersCubit.updateOrderStatus(
      orderId: widget.order.id,
      status: status,
    );

    if (success && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status yeniləndi'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ordersCubit.error ?? 'Xəta baş verdi'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Telefon zəngi başladıla bilmədi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xəta: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showCancelOrderDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sifarişi Ləğv Et'),
            content: Text('Bu sifarişi ləğv etmək istədiyinizə əminsiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Ləğv et'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelOrder();
                },
                child: Text(
                  'Təsdiqlə',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _cancelOrder() async {
    final ordersCubit = context.read<OrdersCubit>();
    final success = await ordersCubit.cancelOrder(
      widget.order.id,
      reason: 'Sürücü tərəfindən ləğv edildi',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sifariş ləğv edildi'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ordersCubit.error ?? 'Xəta baş verdi'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
