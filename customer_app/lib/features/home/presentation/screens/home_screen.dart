import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
// import '../../../orders/presentation/screens/order_creation_screen.dart';
import '../../../orders/presentation/screens/order_history_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../support/presentation/screens/support_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../cubit/home_cubit.dart';
// import '../../../orders/presentation/cubit/orders_cubit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar (profile + menu)
              Row(
                children: [
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final String initial = (state is AuthAuthenticated && state.user.name.isNotEmpty)
                          ? state.user.name[0].toUpperCase()
                          : 'U';
                      return CircleAvatar(
                        radius: 20.r,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          initial,
                          style: AppTheme.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
                        builder: (context) => _buildMenuSheet(context),
                      );
                    },
                    icon: const Icon(Icons.menu),
                  ),
                ],
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 16.h),

                      // Headline
                      Text(
                        'Hara gedirik?',
                        style: AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Ünvanınızı daxil edin və sürücünüz yola düşsün',
                        style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),

                      SizedBox(height: 16.h),

                      // Pickup card
                      _buildLocationCard(
                        context: context,
                        label: 'Götürülmə',
                        placeholder: 'Cari yeriniz',
                        icon: Icons.my_location,
                        onTap: () {
                          context.read<HomeCubit>().setPickupToCurrentLocation();
                        },
                      ),

                      SizedBox(height: 12.h),

                      // Destination card
                      _buildLocationCard(
                        context: context,
                        label: 'Təyinat',
                        placeholder: 'Hara gedirsiniz?',
                        icon: Icons.place,
                        onTap: () {
                          _openDestinationInput(context);
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Map
                      SizedBox(
                        height: 260.h,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: BlocBuilder<HomeCubit, HomeState>(
                            builder: (context, state) {
                              final markers = <Marker>{};
                              if (state.pickupCoordinates != null) {
                                markers.add(
                                  Marker(
                                    markerId: const MarkerId('pickup'),
                                    position: LatLng(
                                      state.pickupCoordinates![1],
                                      state.pickupCoordinates![0],
                                    ),
                                    infoWindow: const InfoWindow(title: 'Götürülmə'),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                                  ),
                                );
                              }
                              if (state.destinationCoordinates != null) {
                                markers.add(
                                  Marker(
                                    markerId: const MarkerId('destination'),
                                    position: LatLng(
                                      state.destinationCoordinates![1],
                                      state.destinationCoordinates![0],
                                    ),
                                    infoWindow: const InfoWindow(title: 'Təyinat'),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                  ),
                                );
                              }
                              if (state.driverCoordinates != null) {
                                markers.add(
                                  Marker(
                                    markerId: const MarkerId('driver'),
                                    position: LatLng(
                                      state.driverCoordinates![1],
                                      state.driverCoordinates![0],
                                    ),
                                    infoWindow: const InfoWindow(title: 'Sürücü'),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                  ),
                                );
                              }

                              final initialLat = state.pickupCoordinates != null
                                  ? state.pickupCoordinates![1]
                                  : 40.3777;
                              final initialLng = state.pickupCoordinates != null
                                  ? state.pickupCoordinates![0]
                                  : 49.8516;

                              return GoogleMap(
                                mapType: MapType.normal,
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(initialLat, initialLng),
                                  zoom: 12,
                                ),
                                markers: markers,
                                myLocationButtonEnabled: true,
                                myLocationEnabled: true,
                                onTap: (latLng) {
                                  context.read<HomeCubit>().onMapTapSetDestination(
                                        latitude: latLng.latitude,
                                        longitude: latLng.longitude,
                                      );
                                },
                              );
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Suggestions / Chips
                      SizedBox(
                        height: 36.h,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildSuggestionChip('Ev', Icons.home),
                            SizedBox(width: 8.w),
                            _buildSuggestionChip('İş', Icons.work),
                            SizedBox(width: 8.w),
                            _buildSuggestionChip('Hava limanı', Icons.flight_takeoff),
                            SizedBox(width: 8.w),
                            _buildSuggestionChip('Klinika', Icons.local_hospital),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Promo / Banner
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_offer, color: AppColors.secondary),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Promo: AYIQ10 kodu ilə ilk sifarişə 10% endirim',
                                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
              ),

              // Bottom primary action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _requestRide(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_taxi, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'Sifariş et',
                        style: AppTheme.titleMedium.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDestinationInput(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (context) {
        final controller = TextEditingController();
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Təyinat ünvanı', style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700)),
              SizedBox(height: 12.h),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Hara gedirsiniz?',
                  prefixIcon: Icon(Icons.place),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    context.read<HomeCubit>().setDestination(value.trim());
                    Navigator.pop(context);
                  }
                },
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isNotEmpty) {
                      context.read<HomeCubit>().setDestination(value);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Təsdiqlə'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _requestRide(BuildContext context) {
    context.read<HomeCubit>().requestRide();
    _showDriverSearchSheet(context);
  }

  void _showDriverSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (context) {
        return BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.isSearchingDriver) {
              return Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16.h),
                    Text(
                      'Sürücü axtarılır...',
                      style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Xahiş edirik gözləyin, ən yaxın sürücünü tapırıq',
                      style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    _buildSummaryRoute(state),
                    SizedBox(height: 8.h),
                  ],
                ),
              );
            }

            if (state.driver != null) {
              final d = state.driver!;
              return Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text('Sürücü tapıldı', style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                    SizedBox(height: 8.h),
                    _buildSummaryRoute(state),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24.r,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            d.name.isNotEmpty ? d.name[0].toUpperCase() : 'S',
                            style: AppTheme.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.name, style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16.sp, color: AppColors.ratingActive),
                                  SizedBox(width: 4.w),
                                  Text('${d.averageRating?.toStringAsFixed(1) ?? '5.0'} (${d.ratingCount ?? 0})', style: AppTheme.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(d.vehiclePlate ?? '', style: AppTheme.bodyMedium),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car, color: AppColors.textSecondary),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              '${d.vehicleMake ?? ''} ${d.vehicleModel ?? ''}',
                              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (context.read<HomeCubit>().state.etaMinutes != null)
                            Text('${context.read<HomeCubit>().state.etaMinutes} dəq', style: AppTheme.bodyMedium),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: const Text('Təsdiqlə'),
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildSummaryRoute(HomeState state) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.my_location, size: 18.sp, color: AppColors.primary),
              SizedBox(width: 8.w),
              Expanded(child: Text(state.pickupAddress ?? 'Götürülmə: —', style: AppTheme.bodyMedium)),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.place, size: 18.sp, color: AppColors.secondary),
              SizedBox(width: 8.w),
              Expanded(child: Text(state.destinationAddress ?? 'Təyinat: —', style: AppTheme.bodyMedium)),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildLocationCard({
    required BuildContext context,
    required String label,
    required String placeholder,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    placeholder,
                    style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSheet(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(
            context: context,
            icon: Icons.history,
            label: 'Sifariş tarixçəsi',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
              );
            },
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.person,
            label: 'Profil',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.settings,
            label: 'Tənzimləmələr',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.support_agent,
            label: 'Dəstək',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SupportScreen()),
              );
            },
          ),
          SizedBox(height: 8.h),
          Divider(color: AppColors.border),
          SizedBox(height: 8.h),
          _buildMenuItem(
            context: context,
            icon: Icons.logout,
            label: 'Çıxış',
            color: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.textPrimary,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTheme.bodyMedium.copyWith(color: color)),
      onTap: onTap,
    );
  }

  Widget _buildSuggestionChip(String label, IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: AppColors.textSecondary),
            SizedBox(width: 6.w),
            Text(label, style: AppTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  // Removed unused _buildQuickActionCard after redesign

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıxış'),
        content: const Text('Hesabınızdan çıxmaq istədiyinizə əminsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ləğv et'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthCubit>().logout();
            },
            child: const Text(
              'Çıx',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}