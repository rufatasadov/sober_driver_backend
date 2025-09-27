import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  Timer? _locationTimer;
  Position? _lastPosition;
  final ApiService _apiService = ApiService();
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  // Start location tracking
  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('LocationTrackingService: Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('LocationTrackingService: Location permission denied forever');
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('LocationTrackingService: Location services are disabled');
        return;
      }

      _isTracking = true;
      print('LocationTrackingService: Started location tracking');

      // Start periodic location updates
      _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _updateLocation();
      });

      // Send initial location
      await _updateLocation();
    } catch (e) {
      print('LocationTrackingService: Error starting tracking: $e');
      _isTracking = false;
    }
  }

  // Stop location tracking
  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
    print('LocationTrackingService: Stopped location tracking');
  }

  // Update location
  Future<void> _updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Check if position has changed significantly (at least 10 meters)
      if (_lastPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Only update if moved more than 10 meters
        if (distance < 10) {
          return;
        }
      }

      _lastPosition = position;
      await _sendLocationToServer(position);
    } catch (e) {
      print('LocationTrackingService: Error updating location: $e');
    }
  }

  // Send location to server
  Future<void> _sendLocationToServer(Position position) async {
    try {
      final response = await _apiService.patch(
        AppConstants.driverLocationEndpoint,
        data: {'latitude': position.latitude, 'longitude': position.longitude},
      );

      if (response.statusCode == 200) {
        print('LocationTrackingService: Location sent successfully');
      } else {
        print(
          'LocationTrackingService: Failed to send location: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('LocationTrackingService: Error sending location: $e');
    }
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('LocationTrackingService: Error getting current position: $e');
      return null;
    }
  }

  // Check location permissions
  Future<bool> checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // Request location permissions
  Future<bool> requestLocationPermissions() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
