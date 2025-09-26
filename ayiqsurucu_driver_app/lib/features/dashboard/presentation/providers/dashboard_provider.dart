import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_constants.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Dashboard Statistics
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentOrders = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get stats => _stats;
  List<Map<String, dynamic>> get recentOrders => _recentOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load dashboard data
  Future<void> loadDashboardData() async {
    try {
      _setLoading(true);
      _clearError();

      // Load statistics and recent orders in parallel
      await Future.wait([_loadStats(), _loadRecentOrders()]);

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load dashboard statistics
  Future<void> _loadStats() async {
    try {
      final response = await _apiService.get(
        AppConstants.dashboardStatsEndpoint,
      );
      final data = _apiService.handleResponse(response);

      // Map earnings data to stats format
      if (data['earnings'] != null) {
        final earnings = data['earnings'];
        _stats = {
          'todayOrders': earnings['todayOrders'] ?? 0,
          'todayEarnings': earnings['today'] ?? 0.0,
          'totalOrders': earnings['totalOrders'] ?? 0,
          'totalEarnings': earnings['total'] ?? 0.0,
          'isOnline': earnings['isOnline'] ?? false,
          'isAvailable': earnings['isAvailable'] ?? false,
        };
      }
    } catch (e) {
      // If stats endpoint fails, use default values
      _stats = {
        'todayOrders': 0,
        'todayEarnings': 0.0,
        'totalOrders': 0,
        'totalEarnings': 0.0,
        'isOnline': false,
        'isAvailable': false,
      };
    }
  }

  // Load recent orders
  Future<void> _loadRecentOrders() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.recentOrdersEndpoint}?limit=5',
      );
      final data = _apiService.handleResponse(response);

      if (data['orders'] != null) {
        _recentOrders = List<Map<String, dynamic>>.from(data['orders']);
      }
    } catch (e) {
      // If recent orders endpoint fails, use empty list
      _recentOrders = [];
    }
  }

  // Update driver status
  Future<bool> updateDriverStatus({
    required bool isOnline,
    bool? isAvailable,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.patch(
        AppConstants.driverStatusEndpoint,
        data: {
          'isOnline': isOnline,
          if (isAvailable != null) 'isAvailable': isAvailable,
        },
      );

      final data = _apiService.handleResponse(response);

      if (data['success'] == true) {
        // Update local stats
        if (_stats != null) {
          _stats!['isOnline'] = isOnline;
          if (isAvailable != null) {
            _stats!['isAvailable'] = isAvailable;
          }
        }
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
