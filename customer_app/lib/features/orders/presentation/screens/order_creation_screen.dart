import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/location_service.dart';
import '../cubit/orders_cubit.dart';
import 'order_tracking_screen.dart';

class OrderCreationScreen extends StatefulWidget {
  const OrderCreationScreen({super.key});

  @override
  State<OrderCreationScreen> createState() => _OrderCreationScreenState();
}

class _OrderCreationScreenState extends State<OrderCreationScreen> {
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedPaymentMethod = 'cash';
  final List<String> _paymentMethods = ['cash', 'card', 'online'];
  
  Map<String, dynamic>? _pickupLocation;
  Map<String, dynamic>? _destinationLocation;
  bool _isLoading = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      
      if (position != null) {
        final placemarks = await locationService.getAddressFromCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        
        if (placemarks != null && placemarks.isNotEmpty) {
          final address = locationService.formatAddress(placemarks.first);
          setState(() {
            _pickupController.text = address;
            _pickupLocation = {
              'coordinates': [position.longitude, position.latitude],
              'address': address,
            };
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yer təyin edilmədi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _createOrder() {
    if (_pickupController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Götürülmə və təyinat ünvanlarını daxil edin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_pickupLocation == null || _destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ünvanların koordinatları tələb olunur'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<OrdersCubit>().createOrder(
      pickup: _pickupLocation!,
      destination: _destinationLocation!,
      paymentMethod: _selectedPaymentMethod,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taksi sifariş et'),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.yellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.yellow),
            ),
            child: Text(
              'TEST MODE',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<OrdersCubit, OrdersState>(
        listener: (context, state) {
          if (state is OrdersLoading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is OrderCreated) {
            setState(() {
              _isLoading = false;
            });
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => OrderTrackingScreen(order: state.order),
              ),
            );
          } else if (state is OrdersError) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pickup Location
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: AppColors.primary),
                          SizedBox(width: 8.w),
                          Text(
                            'Götürülmə nöqtəsi',
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pickupController,
                              decoration: const InputDecoration(
                                hintText: 'Götürülmə ünvanını daxil edin',
                                prefixIcon: Icon(Icons.my_location),
                              ),
                              onChanged: (value) {
                                // TODO: Implement address search
                                if (value.isNotEmpty) {
                                  _pickupLocation = {
                                    'coordinates': [49.8516, 40.3777], // Default Baku coordinates
                                    'address': value,
                                  };
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8.w),
                          IconButton(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            tooltip: 'Cari yer',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Destination Location
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.place, color: AppColors.secondary),
                          SizedBox(width: 8.w),
                          Text(
                            'Təyinat nöqtəsi',
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _destinationController,
                        decoration: const InputDecoration(
                          hintText: 'Təyinat ünvanını daxil edin',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        onChanged: (value) {
                          // TODO: Implement address search
                          if (value.isNotEmpty) {
                            _destinationLocation = {
                              'coordinates': [49.8516, 40.3777], // Default Baku coordinates
                              'address': value,
                            };
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Payment Method
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ödəniş üsulu',
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      for (final method in _paymentMethods)
                        RadioListTile<String>(
                          title: Text(_getPaymentMethodName(method)),
                          value: method,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Notes
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Qeydlər',
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Sürücü üçün əlavə məlumatlar...',
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Create Order Button
              ElevatedButton(
                onPressed: _isLoading ? null : _createOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Sifariş yarat',
                        style: AppTheme.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash':
        return 'Nəğd ödəniş';
      case 'card':
        return 'Kartla ödəniş';
      case 'online':
        return 'Onlayn ödəniş';
      default:
        return method;
    }
  }
}