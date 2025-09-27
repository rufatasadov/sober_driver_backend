import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_constants.dart';

// Dashboard States
abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> recentOrders;

  DashboardLoaded({required this.stats, required this.recentOrders});
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);
}

// Dashboard Cubit
class DashboardCubit extends Cubit<DashboardState> {
  final ApiService _apiService = ApiService();

  DashboardCubit() : super(DashboardInitial());

  // Getters
  bool get isLoading => state is DashboardLoading;
  String? get error =>
      state is DashboardError ? (state as DashboardError).message : null;
  Map<String, dynamic>? get stats =>
      state is DashboardLoaded ? (state as DashboardLoaded).stats : null;
  List<Map<String, dynamic>> get recentOrders =>
      state is DashboardLoaded ? (state as DashboardLoaded).recentOrders : [];

  // Load dashboard data
  Future<void> loadDashboardData() async {
    try {
      emit(DashboardLoading());

      // Load statistics and recent orders in parallel
      await Future.wait([_loadStats(), _loadRecentOrders()]);

      // Get the loaded data
      final statsData = await _loadStats();
      final recentOrdersData = await _loadRecentOrders();

      emit(DashboardLoaded(stats: statsData, recentOrders: recentOrdersData));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  // Load dashboard statistics
  Future<Map<String, dynamic>> _loadStats() async {
    try {
      // Load earnings and driver status in parallel
      final earningsResponse = await _apiService.get(
        AppConstants.dashboardStatsEndpoint,
      );
      final earningsData = _apiService.handleResponse(earningsResponse);

      final statusResponse = await _apiService.get(
        AppConstants.driverStatusEndpoint,
      );
      final statusData = _apiService.handleResponse(statusResponse);

      // Map earnings data to stats format
      if (earningsData.isNotEmpty) {
        return {
          'todayOrders': earningsData['totalOrders'] ?? 0,
          'todayEarnings': earningsData['netEarnings'] ?? 0.0,
          'totalOrders': earningsData['totalOrders'] ?? 0,
          'totalEarnings': earningsData['netEarnings'] ?? 0.0,
          'isOnline': statusData['isOnline'] ?? false,
          'isAvailable': statusData['isAvailable'] ?? false,
        };
      }

      return _getDefaultStats();
    } catch (e) {
      print('DashboardCubit: Error loading stats: $e');
      // If stats endpoint fails, use default values
      return _getDefaultStats();
    }
  }

  // Load recent orders
  Future<List<Map<String, dynamic>>> _loadRecentOrders() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.recentOrdersEndpoint}?limit=5',
      );
      final data = _apiService.handleResponse(response);

      if (data['orders'] != null) {
        return List<Map<String, dynamic>>.from(data['orders']);
      }

      return [];
    } catch (e) {
      // If recent orders endpoint fails, use empty list
      return [];
    }
  }

  // Update driver status
  Future<bool> updateDriverStatus({
    required bool isOnline,
    bool? isAvailable,
  }) async {
    try {
      print(
        'DashboardCubit: Updating driver status - isOnline: $isOnline, isAvailable: $isAvailable',
      );
      emit(DashboardLoading());

      final response = await _apiService.patch(
        AppConstants.driverStatusEndpoint,
        data: {
          'isOnline': isOnline,
          if (isAvailable != null) 'isAvailable': isAvailable,
        },
      );

      print('DashboardCubit: API response: $response');
      final data = _apiService.handleResponse(response);
      print('DashboardCubit: Parsed data: $data');

      if (data['success'] == true) {
        // Update current state with new status
        if (state is DashboardLoaded) {
          final currentState = state as DashboardLoaded;
          final updatedStats = Map<String, dynamic>.from(currentState.stats);
          updatedStats['isOnline'] = isOnline;
          if (isAvailable != null) {
            updatedStats['isAvailable'] = isAvailable;
          }

          print('DashboardCubit: Emitting new state with stats: $updatedStats');
          emit(
            DashboardLoaded(
              stats: updatedStats,
              recentOrders: currentState.recentOrders,
            ),
          );
        }
        return true;
      }

      print('DashboardCubit: API returned success: false');
      emit(DashboardError('Failed to update driver status'));
      return false;
    } catch (e) {
      print('DashboardCubit: Error updating driver status: $e');
      emit(DashboardError(e.toString()));
      return false;
    }
  }

  // Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData();
  }

  // Get default stats
  Map<String, dynamic> _getDefaultStats() {
    return {
      'todayOrders': 0,
      'todayEarnings': 0.0,
      'totalOrders': 0,
      'totalEarnings': 0.0,
      'isOnline': false,
      'isAvailable': false,
    };
  }
}
