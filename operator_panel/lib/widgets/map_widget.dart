import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../utils/constants.dart';

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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.center ??
        _currentLocation ??
        const latlong.LatLng(40.3777, 49.8516); // Baku center
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
              userAgentPackageName: 'com.ayiqsurucu.operator',
              maxZoom: 18,
            ),

            // Markers
            if (widget.markers != null)
              MarkerLayer(
                markers: widget.markers!
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
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _centerOnCurrentLocation,
              child: const Icon(Icons.my_location, size: 20),
            ),
          ),
      ],
    );
  }
}

class MapMarker {
  final latlong.LatLng point;
  final Widget widget;

  MapMarker({
    required this.point,
    required this.widget,
  });
}

class PickupMarker extends StatelessWidget {
  const PickupMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class DestinationMarker extends StatelessWidget {
  const DestinationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
