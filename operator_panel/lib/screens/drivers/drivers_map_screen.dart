import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:provider/provider.dart';
import 'dart:async';
import '../../utils/constants.dart';
import '../../providers/driver_provider.dart';
import '../../widgets/map_widget.dart';

class DriversMapScreen extends StatefulWidget {
  const DriversMapScreen({super.key});

  @override
  State<DriversMapScreen> createState() => _DriversMapScreenState();
}

class _DriversMapScreenState extends State<DriversMapScreen> {
  late MapController _mapController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startPeriodicRefresh();
    _loadDrivers();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadDrivers();
    });
  }

  Future<void> _loadDrivers() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.loadOnlineDrivers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onlayn Sürücülər'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrivers,
            tooltip: 'Yenilə',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnDrivers,
            tooltip: 'Sürücüləri mərkəzə gətir',
          ),
        ],
      ),
      body: Consumer<DriverProvider>(
        builder: (context, driverProvider, child) {
          if (driverProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (driverProvider.onlineDrivers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Onlayn sürücü yoxdur',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Map
              MapWidget(
                center: _getMapCenter(driverProvider.onlineDrivers),
                zoom: 12.0,
                markers: _getDriverMarkers(driverProvider.onlineDrivers),
                showLocationButton: true,
              ),

              // Driver count info
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${driverProvider.onlineDrivers.length} sürücü onlayn',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Last update time
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Son yenilənmə: ${_getLastUpdateTime()}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  latlong.LatLng _getMapCenter(List<Map<String, dynamic>> drivers) {
    if (drivers.isEmpty) {
      return const latlong.LatLng(40.3777, 49.8516); // Default to Baku
    }

    double totalLat = 0;
    double totalLng = 0;
    int validDrivers = 0;

    for (final driver in drivers) {
      final location = driver['currentLocation'];
      if (location != null && location['coordinates'] != null) {
        final coords = location['coordinates'];
        if (coords is List && coords.length >= 2) {
          totalLat += (coords[1] as num).toDouble();
          totalLng += (coords[0] as num).toDouble();
          validDrivers++;
        }
      }
    }

    if (validDrivers > 0) {
      return latlong.LatLng(
        totalLat / validDrivers,
        totalLng / validDrivers,
      );
    }

    return const latlong.LatLng(40.3777, 49.8516);
  }

  List<MapMarker> _getDriverMarkers(List<Map<String, dynamic>> drivers) {
    final markers = <MapMarker>[];

    for (final driver in drivers) {
      final location = driver['currentLocation'];
      if (location != null && location['coordinates'] != null) {
        final coords = location['coordinates'];
        if (coords is List && coords.length >= 2) {
          markers.add(
            MapMarker(
              point: latlong.LatLng(
                (coords[1] as num).toDouble(),
                (coords[0] as num).toDouble(),
              ),
              widget: DriverMarker(
                driverName: driver['name'] ?? 'Sürücü',
                isAvailable: driver['isAvailable'] ?? false,
                lastUpdate: driver['lastLocationUpdate'],
              ),
            ),
          );
        }
      }
    }

    return markers;
  }

  void _centerOnDrivers() {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final center = _getMapCenter(driverProvider.onlineDrivers);
    _mapController.move(center, 12.0);
  }

  String _getLastUpdateTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class DriverMarker extends StatelessWidget {
  final String driverName;
  final bool isAvailable;
  final String? lastUpdate;

  const DriverMarker({
    super.key,
    required this.driverName,
    required this.isAvailable,
    this.lastUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDriverInfo(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isAvailable ? AppColors.success : AppColors.warning,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.directions_car,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _showDriverInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driverName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.pause_circle,
                  color: isAvailable ? AppColors.success : AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isAvailable ? 'Müsait' : 'Məşğul',
                  style: TextStyle(
                    color: isAvailable ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (lastUpdate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Son yenilənmə: $lastUpdate',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Bağla'),
          ),
        ],
      ),
    );
  }
}
