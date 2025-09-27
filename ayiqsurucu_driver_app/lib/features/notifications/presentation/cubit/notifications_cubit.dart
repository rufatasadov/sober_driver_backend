import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/api_service.dart';

// Notifications States
abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<Map<String, dynamic>> notifications;

  NotificationsLoaded({required this.notifications});
}

class NotificationsError extends NotificationsState {
  final String message;

  NotificationsError(this.message);
}

// Notifications Cubit
class NotificationsCubit extends Cubit<NotificationsState> {
  final ApiService _apiService = ApiService();

  NotificationsCubit() : super(NotificationsInitial());

  // Getters
  bool get isLoading => state is NotificationsLoading;
  String? get error =>
      state is NotificationsError
          ? (state as NotificationsError).message
          : null;
  List<Map<String, dynamic>> get notifications =>
      state is NotificationsLoaded
          ? (state as NotificationsLoaded).notifications
          : [];

  // Load notifications
  Future<void> loadNotifications() async {
    try {
      emit(NotificationsLoading());

      final response = await _apiService.get('/notifications/driver');
      final data = _apiService.handleResponse(response);

      // Convert to Map safely
      Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);

      if (dataMap['notifications'] != null) {
        final notifications =
            (dataMap['notifications'] as List)
                .map((notification) => Map<String, dynamic>.from(notification))
                .toList();

        emit(NotificationsLoaded(notifications: notifications));
      } else {
        emit(NotificationsLoaded(notifications: []));
      }
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.patch(
        '/notifications/$notificationId/read',
      );

      final data = _apiService.handleResponse(response);

      // Convert to Map safely
      Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);

      if (dataMap['success'] == true) {
        // Reload notifications to update the state
        await loadNotifications();
        return true;
      }

      return false;
    } catch (e) {
      emit(NotificationsError(e.toString()));
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.patch('/notifications/read-all');

      final data = _apiService.handleResponse(response);

      // Convert to Map safely
      Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);

      if (dataMap['success'] == true) {
        // Reload notifications to update the state
        await loadNotifications();
        return true;
      }

      return false;
    } catch (e) {
      emit(NotificationsError(e.toString()));
      return false;
    }
  }

  // Get unread count
  int get unreadCount {
    if (state is NotificationsLoaded) {
      final notifications = (state as NotificationsLoaded).notifications;
      return notifications.where((n) => !(n['isRead'] ?? false)).length;
    }
    return 0;
  }

  // Refresh notifications
  Future<void> refresh() async {
    await loadNotifications();
  }
}
