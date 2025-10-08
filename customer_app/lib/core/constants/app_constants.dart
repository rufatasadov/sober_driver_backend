class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://81.162.55.58:14122/api';
  static const String socketUrl = 'http://81.162.55.58:14122';

  // API Endpoints
  static const String sendOtpEndpoint = '/auth/send-otp';
  static const String verifyOtpEndpoint = '/auth/verify-otp';
  static const String createUserEndpoint = '/auth/create-user';
  static const String userProfileEndpoint = '/auth/me';
  static const String updateProfileEndpoint = '/auth/profile';
  static const String fcmTokenEndpoint = '/auth/fcm-token';
  static const String logoutEndpoint = '/auth/logout';

  // Orders Endpoints
  static const String ordersEndpoint = '/orders';
  static const String orderStatusEndpoint = '/orders';

  // Socket Events
  static const String socketNewOrderEvent = 'new_order_available';
  static const String socketOrderStatusEvent = 'order_status_changed';
  static const String socketDriverLocationEvent = 'driver_location_updated';
  static const String socketTrackOrderEvent = 'track_order';
  static const String socketOrderAcceptedEvent = 'order_accepted';
  static const String socketOrderRejectedEvent = 'order_rejected';

  // Shared Preferences Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String fcmTokenKey = 'fcm_token';

  // Location Settings
  static const double defaultLatitude = 40.3777;
  static const double defaultLongitude = 49.8516;
  static const double defaultZoom = 15.0;
  static const int locationUpdateInterval = 5000; // 5 seconds

  // Order Status
  static const String orderPending = 'pending';
  static const String orderAccepted = 'accepted';
  static const String orderInProgress = 'in_progress';
  static const String orderCompleted = 'completed';
  static const String orderCancelled = 'cancelled';

  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentCard = 'card';
  static const String paymentOnline = 'online';

  // App Settings
  static const String appName = 'Ayiq Sürücü Customer';
  static const String appVersion = '1.0.0';

  // Map Settings
  static const double mapZoom = 15.0;
  static const double mapZoomDriver = 18.0;

  // Timeouts
  static const int apiTimeout = 30000; // 30 seconds
  static const int socketTimeout = 10000; // 10 seconds
}
