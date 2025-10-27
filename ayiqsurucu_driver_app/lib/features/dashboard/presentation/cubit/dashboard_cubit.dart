import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../orders/presentation/cubit/orders_cubit.dart';

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
      final results = await Future.wait([_loadStats(), _loadRecentOrders()]);

      final statsData = results[0] as Map<String, dynamic>;
      final recentOrdersData = results[1] as List<Map<String, dynamic>>;

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

      // Convert to Map safely with error handling
      Map<String, dynamic> earningsMap = {};
      Map<String, dynamic> statusMap = {};

      try {
        earningsMap = Map<String, dynamic>.from(earningsData);
        print('DashboardCubit: Earnings data structure: $earningsMap');
      } catch (e) {
        print('DashboardCubit: Error converting earnings data: $e');
        earningsMap = {};
      }

      try {
        statusMap = Map<String, dynamic>.from(statusData);
      } catch (e) {
        print('DashboardCubit: Error converting status data: $e');
        statusMap = {};
      }

      // Map earnings data to stats format
      if (earningsMap.isNotEmpty) {
        // Extract earnings data from nested structure
        final earnings = earningsMap['earnings'] as Map<String, dynamic>? ?? {};
        final balance = _safeParseDouble(earnings['balance']) ?? 0.0;

        print('DashboardCubit: Extracted earnings: $earnings');
        print('DashboardCubit: Balance value: $balance');

        return {
          'todayOrders': _safeParseInt(earnings['totalOrders']) ?? 0,
          'todayEarnings': _safeParseDouble(earnings['netEarnings']) ?? 0.0,
          'totalOrders': _safeParseInt(earnings['totalOrders']) ?? 0,
          'totalEarnings': _safeParseDouble(earnings['netEarnings']) ?? 0.0,
          'balance': balance,
          'isOnline': _safeParseBool(statusMap['isOnline']) ?? true,
          'isAvailable': _safeParseBool(statusMap['isAvailable']) ?? true,
          'isActive': _safeParseBool(statusMap['isActive']) ?? true,
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

      // Convert to Map safely with error handling
      Map<String, dynamic> dataMap = {};

      try {
        dataMap = Map<String, dynamic>.from(data);
      } catch (e) {
        print('DashboardCubit: Error converting recent orders data: $e');
        return [];
      }

      if (dataMap['orders'] != null && dataMap['orders'] is List) {
        try {
          return List<Map<String, dynamic>>.from(dataMap['orders']);
        } catch (e) {
          print('DashboardCubit: Error converting orders list: $e');
          return [];
        }
      }

      return [];
    } catch (e) {
      print('DashboardCubit: Error loading recent orders: $e');
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

      // Convert to Map safely
      Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);

      // Check if the response is successful (either 'success: true' or has 'driver' field)
      if (dataMap['success'] == true || dataMap['driver'] != null) {
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
        } else {
          // If state is not loaded, reload the entire dashboard
          print('DashboardCubit: State not loaded, reloading dashboard...');
          await loadDashboardData();
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

  // Refresh only balance data
  Future<void> refreshBalance() async {
    try {
      print('DashboardCubit: Refreshing balance data...');

      final response = await _apiService.get(
        AppConstants.dashboardStatsEndpoint,
      );
      final data = _apiService.handleResponse(response);

      // Convert to Map safely
      Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);

      if (dataMap['earnings'] != null &&
          dataMap['earnings']['balance'] != null) {
        final newBalance =
            _safeParseDouble(dataMap['earnings']['balance']) ?? 0.0;

        // Update current state with new balance
        if (state is DashboardLoaded) {
          final currentState = state as DashboardLoaded;
          final updatedStats = Map<String, dynamic>.from(currentState.stats);
          updatedStats['balance'] = newBalance;

          print(
            'DashboardCubit: Balance updated to: ${newBalance.toStringAsFixed(2)} AZN',
          );

          emit(
            DashboardLoaded(
              stats: updatedStats,
              recentOrders: currentState.recentOrders,
            ),
          );
        }
      }
    } catch (e) {
      print('DashboardCubit: Error refreshing balance: $e');
    }
  }

  // Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData();
  }

  // Check and auto-set online status based on active orders
  Future<void> checkAndAutoSetOnlineStatus(OrdersCubit ordersCubit) async {
    try {
      final ordersState = ordersCubit.state;
      final hasActiveOrders =
          ordersState is OrdersLoaded && ordersState.activeOrders.isNotEmpty;

      // Get current driver status
      final currentStats = stats;
      final isCurrentlyOnline = currentStats?['isOnline'] ?? false;

      print(
        'DashboardCubit: Checking auto-online status - hasActiveOrders: $hasActiveOrders, isCurrentlyOnline: $isCurrentlyOnline',
      );

      // If driver has active orders but is offline, automatically set them online
      if (hasActiveOrders && !isCurrentlyOnline) {
        print(
          'DashboardCubit: Driver has active orders but is offline. Setting to online automatically.',
        );
        await updateDriverStatus(isOnline: true, isAvailable: true);
      }
      // If driver has no active orders but is online, allow them to go offline
      else if (!hasActiveOrders && isCurrentlyOnline) {
        print(
          'DashboardCubit: Driver has no active orders and is online. Status unchanged.',
        );
      }
    } catch (e) {
      print('DashboardCubit: Error checking auto-online status: $e');
    }
  }

  // Get default stats
  Map<String, dynamic> _getDefaultStats() {
    return {
      'todayOrders': 0,
      'todayEarnings': 0.0,
      'totalOrders': 0,
      'totalEarnings': 0.0,
      'isOnline': true, // Default to online
      'isAvailable': true, // Default to available
      'isActive': true, // Default to active
    };
  }

  // Safe parsing helper methods
  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  bool? _safeParseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) {
      return value == 1;
    }
    return null;
  }
}
