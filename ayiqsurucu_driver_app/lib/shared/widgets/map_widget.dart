import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/location_service.dart';

class MapWidget extends StatefulWidget {
  final latlong.LatLng? center;
  final double? zoom;
  final List<MapMarker>? markers;
  final List<Polyline>? polylines;
  final bool showCurrentLocation;
  final bool showLocationButton;
  final VoidCallback? onMapTap;
  final Function(latlong.LatLng)? onLocationChanged;

  const MapWidget({
    super.key,
    this.center,
    this.zoom,
    this.markers,
    this.polylines,
    this.showCurrentLocation = true,
    this.showLocationButton = true,
    this.onMapTap,
    this.onLocationChanged,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late MapController _mapController;
  latlong.LatLng? _currentLocation;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentLocation = latlong.LatLng(
          position.latitude,
          position.longitude,
        );
      });

      if (widget.onLocationChanged != null) {
        widget.onLocationChanged!(_currentLocation!);
      }
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center =
        widget.center ??
        _currentLocation ??
        const latlong.LatLng(40.3777, 49.8516);
    final zoom = widget.zoom ?? 15.0;

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            onTap: (tapPosition, point) {
              if (widget.onMapTap != null) {
                widget.onMapTap!();
              }
            },
          ),
          children: [
            // OpenStreetMap tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ayiqsurucu.driver',
              maxZoom: 18,
            ),

            // Markers
            if (widget.markers != null)
              MarkerLayer(
                markers:
                    widget.markers!
                        .map(
                          (marker) =>
                              Marker(point: marker.point, child: marker.widget),
                        )
                        .toList(),
              ),

            // Polylines
            if (widget.polylines != null)
              PolylineLayer(polylines: widget.polylines!),
          ],
        ),

        // Current location button
        if (widget.showLocationButton)
          Positioned(
            bottom: 20.h,
            right: 20.w,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              onPressed: _centerOnCurrentLocation,
              child: Icon(Icons.my_location, size: 20.sp),
            ),
          ),

        // Loading indicator
        if (_currentLocation == null && widget.showCurrentLocation)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

// Map marker class
class MapMarker {
  final latlong.LatLng point;
  final Widget widget;

  const MapMarker({required this.point, required this.widget});
}

// Custom marker widgets
class DriverMarker extends StatelessWidget {
  final bool isOnline;

  const DriverMarker({super.key, this.isOnline = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.success : AppColors.textSecondary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textOnPrimary, width: 2.w),
      ),
      child: Icon(
        Icons.local_taxi,
        color: AppColors.textOnPrimary,
        size: 20.sp,
      ),
    );
  }
}

class PickupMarker extends StatelessWidget {
  const PickupMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30.w,
      height: 30.w,
      decoration: BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textOnPrimary, width: 2.w),
      ),
      child: Icon(
        Icons.location_on,
        color: AppColors.textOnPrimary,
        size: 16.sp,
      ),
    );
  }
}

class DestinationMarker extends StatelessWidget {
  const DestinationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30.w,
      height: 30.w,
      decoration: BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textOnPrimary, width: 2.w),
      ),
      child: Icon(Icons.place, color: AppColors.textOnPrimary, size: 16.sp),
    );
  }
}
