import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class DriverProvider with ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _nearbyDrivers = [];
  List<Map<String, dynamic>> _onlineDrivers = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get drivers => _drivers;
  List<Map<String, dynamic>> get nearbyDrivers => _nearbyDrivers;
  List<Map<String, dynamic>> get onlineDrivers => _onlineDrivers;

  Future<void> loadDrivers({
    int page = 1,
    int limit = 20,
    String? status,
    bool? isOnline,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (isOnline != null) 'isOnline': isOnline.toString(),
      };

      final uri = Uri.parse('${ApiEndpoints.operator}/drivers')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _drivers = List<Map<String, dynamic>>.from(data['drivers'] ?? []);
        print('Loaded ${_drivers.length} drivers');
        // Debug: Print the first driver structure to understand the data format
        if (_drivers.isNotEmpty) {
          print('First driver structure: ${_drivers.first}');
          print('First driver user: ${_drivers.first['user']}');
          print('First driver name: ${_drivers.first['user']?['name']}');
        } else {
          print('No drivers found in response');
        }
      } else {
        print('Failed to load drivers: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Drivers load error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNearbyDrivers({
    required double latitude,
    required double longitude,
    double maxDistance = 5,
  }) async {
    try {
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'maxDistance': maxDistance.toString(),
      };

      final uri = Uri.parse('${ApiEndpoints.operator}/nearby-drivers')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _nearbyDrivers = List<Map<String, dynamic>>.from(data['drivers'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      print('Nearby drivers load error: $e');
    }
  }

  void searchDrivers(String query) {
    if (query.isEmpty) {
      loadDrivers();
      return;
    }

    _drivers = _drivers.where((driver) {
      final name = driver['user']?['name']?.toString().toLowerCase() ?? '';
      final phone = driver['user']?['phone']?.toString().toLowerCase() ?? '';
      final licenseNumber =
          driver['licenseNumber']?.toString().toLowerCase() ?? '';
      final plateNumber =
          driver['vehicleInfo']?['plateNumber']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return name.contains(searchQuery) ||
          phone.contains(searchQuery) ||
          licenseNumber.contains(searchQuery) ||
          plateNumber.contains(searchQuery);
    }).toList();

    notifyListeners();
  }

  void filterDriversByStatus(String status) {
    if (status == 'all') {
      loadDrivers();
      return;
    }

    _drivers = _drivers.where((driver) {
      if (status == 'online') {
        return driver['isOnline'] == true && driver['isAvailable'] == true;
      } else if (status == 'offline') {
        return driver['isOnline'] == false;
      } else if (status == 'busy') {
        return driver['isOnline'] == true && driver['isAvailable'] == false;
      }
      return true;
    }).toList();

    notifyListeners();
  }

  Future<bool> createDriver(Map<String, dynamic> driverData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.operator}/drivers'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode(driverData),
      );

      if (response.statusCode == 201) {
        await loadDrivers();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Sürücü yaradılmadı');
      }
    } catch (e) {
      print('Create driver error: $e');
      rethrow;
    }
  }

  Future<bool> updateDriver(
      String driverId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.operator}/drivers/$driverId'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        await loadDrivers();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Sürücü yenilənmədi');
      }
    } catch (e) {
      print('Update driver error: $e');
      rethrow;
    }
  }

  Future<bool> deleteDriver(String driverId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiEndpoints.operator}/drivers/$driverId'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await loadDrivers();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Sürücü silinmədi');
      }
    } catch (e) {
      print('Delete driver error: $e');
      rethrow;
    }
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Token get error: $e');
      return null;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Gözləyir';
      case 'approved':
        return 'Təsdiqlənib';
      case 'rejected':
        return 'Rədd edilib';
      case 'suspended':
        return 'Dayandırılıb';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'suspended':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String getOnlineStatusText(bool isOnline) {
    return isOnline ? 'Online' : 'Offline';
  }

  Color getOnlineStatusColor(bool isOnline) {
    return isOnline ? AppColors.success : AppColors.textSecondary;
  }

  // Load online drivers with GPS locations
  Future<void> loadOnlineDrivers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.drivers}/online'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _onlineDrivers = List<Map<String, dynamic>>.from(data['drivers'] ?? []);
        print('Loaded ${_onlineDrivers.length} online drivers');
      } else {
        print('Error loading online drivers: ${response.statusCode}');
        _onlineDrivers = [];
      }
    } catch (e) {
      print('Error loading online drivers: $e');
      _onlineDrivers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
