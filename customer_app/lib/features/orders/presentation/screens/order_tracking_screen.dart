import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../shared/models/order_model.dart';
import '../cubit/orders_cubit.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late OrderModel _currentOrder;
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _initializeSocketListeners();
  }

  void _initializeSocketListeners() {
    final socketService = SocketService();
    
    // Listen to order status changes
    _socketSubscription = socketService.orderStatusStream.listen((data) {
      if (data['orderId'] == _currentOrder.id) {
        setState(() {
          _currentOrder = _currentOrder.copyWith(
            status: data['status'] ?? _currentOrder.status,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sifarişi ləğv et'),
        content: const Text('Sifarişi ləğv etmək istədiyinizə əminsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ləğv et'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<OrdersCubit>().cancelOrder(_currentOrder.id);
            },
            child: const Text(
              'Bəli, ləğv et',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sifariş #${_currentOrder.orderNumber}'),
        actions: [
          if (_currentOrder.isPending || _currentOrder.isAccepted)
            IconButton(
              onPressed: _cancelOrder,
              icon: const Icon(Icons.cancel),
              tooltip: 'Sifarişi ləğv et',
            ),
        ],
      ),
      body: BlocListener<OrdersCubit, OrdersState>(
        listener: (context, state) {
          if (state is OrdersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Status Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      _buildStatusIndicator(),
                      SizedBox(height: 16.h),
                      Text(
                        _getStatusText(_currentOrder.status),
                        style: AppTheme.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(_currentOrder.status),
                        ),
                      ),
                      if (_currentOrder.estimatedTime != null) ...[
                        SizedBox(height: 8.h),
                        Text(
                          'Təxmini vaxt: ${_currentOrder.estimatedTime} dəqiqə',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Order Details
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sifariş məlumatları',
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      
                      _buildLocationRow(
                        icon: Icons.location_on,
                        iconColor: AppColors.primary,
                        title: 'Götürülmə',
                        address: _currentOrder.pickupAddress,
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      _buildLocationRow(
                        icon: Icons.place,
                        iconColor: AppColors.secondary,
                        title: 'Təyinat',
                        address: _currentOrder.destinationAddress,
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      Row(
                        children: [
                          Icon(Icons.payment, color: AppColors.info),
                          SizedBox(width: 8.w),
                          Text(
                            'Ödəniş: ',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getPaymentMethodName(_currentOrder.paymentMethod),
                            style: AppTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${_currentOrder.totalFare.toStringAsFixed(2)} ${_currentOrder.currency}',
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      
                      if (_currentOrder.notes != null && _currentOrder.notes!.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.note, color: AppColors.warning),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _currentOrder.notes!,
                                style: AppTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Driver Information
              if (_currentOrder.driver != null) ...[
                SizedBox(height: 16.h),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sürücü məlumatları',
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30.r,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                _currentOrder.driver!.name.isNotEmpty 
                                    ? _currentOrder.driver!.name[0].toUpperCase()
                                    : 'S',
                                style: AppTheme.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentOrder.driver!.name,
                                    style: AppTheme.titleMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _currentOrder.driver!.phone,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16.sp,
                                        color: AppColors.ratingActive,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        '${_currentOrder.driver!.averageRating?.toStringAsFixed(1) ?? '0.0'} (${_currentOrder.driver!.ratingCount ?? 0})',
                                        style: AppTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // TODO: Call driver
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sürücüyə zəng etmə tezliklə'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.phone),
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        // Vehicle Information
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.directions_car, color: AppColors.textSecondary),
                              SizedBox(width: 8.w),
                              Text(
                                '${_currentOrder.driver!.vehicleMake ?? ''} ${_currentOrder.driver!.vehicleModel ?? ''}',
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _currentOrder.driver!.vehiclePlate ?? '',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: 16.h),
              
              // Action Buttons
              if (_currentOrder.isCompleted) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Rate driver
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sürücünü qiymətləndirmə tezliklə'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('Sürücünü qiymətləndir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                ),
              ] else if (_currentOrder.isCancelled) ...[
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: AppColors.error),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Sifariş ləğv edildi',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatusDot(AppColors.primary, _currentOrder.isPending || _currentOrder.isAccepted || _currentOrder.isInProgress || _currentOrder.isCompleted),
        Container(
          width: 40.w,
          height: 2.h,
          color: (_currentOrder.isAccepted || _currentOrder.isInProgress || _currentOrder.isCompleted) 
              ? AppColors.primary 
              : AppColors.border,
        ),
        _buildStatusDot(AppColors.info, _currentOrder.isAccepted || _currentOrder.isInProgress || _currentOrder.isCompleted),
        Container(
          width: 40.w,
          height: 2.h,
          color: (_currentOrder.isInProgress || _currentOrder.isCompleted) 
              ? AppColors.info 
              : AppColors.border,
        ),
        _buildStatusDot(AppColors.success, _currentOrder.isCompleted),
      ],
    );
  }

  Widget _buildStatusDot(Color color, bool isActive) {
    return Container(
      width: 16.w,
      height: 16.w,
      decoration: BoxDecoration(
        color: isActive ? color : AppColors.border,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                address,
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Gözləyir';
      case 'accepted':
        return 'Qəbul edildi';
      case 'in_progress':
        return 'Gedir';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'Ləğv edildi';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.orderPending;
      case 'accepted':
        return AppColors.orderAccepted;
      case 'in_progress':
        return AppColors.orderInProgress;
      case 'completed':
        return AppColors.orderCompleted;
      case 'cancelled':
        return AppColors.orderCancelled;
      default:
        return AppColors.textPrimary;
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash':
        return 'Nəğd';
      case 'card':
        return 'Kart';
      case 'online':
        return 'Onlayn';
      default:
        return method;
    }
  }
}
