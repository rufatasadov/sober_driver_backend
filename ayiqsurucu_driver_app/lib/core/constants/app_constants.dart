class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:3000/api';
  static const String socketUrl = 'http://localhost:3000';

  // API Endpoints
  static const String sendOtpEndpoint = '/auth/send-otp';
  static const String verifyOtpEndpoint = '/auth/verify-otp';
  static const String driverLoginEndpoint = '/auth/driver-login';
  static const String driverRegisterEndpoint = '/drivers/register';
  static const String driverProfileEndpoint = '/drivers/profile';
  static const String driverStatusEndpoint = '/drivers/status';
  static const String driverLocationEndpoint = '/drivers/location';
  static const String nearbyOrdersEndpoint = '/drivers/nearby-orders';
  static const String acceptOrderEndpoint = '/drivers/orders';
  static const String rejectOrderEndpoint = '/drivers/orders';
  static const String earningsEndpoint = '/drivers/earnings';
  static const String ordersEndpoint = '/orders';

  // Socket Events
  static const String socketNewOrderEvent = 'new_order_available';
  static const String socketOrderStatusEvent = 'order_status_changed';
  static const String socketDriverLocationEvent = 'driver_location_updated';
  static const String socketUpdateLocationEvent = 'update_location';
  static const String socketUpdateStatusEvent = 'update_status';

  // Shared Preferences Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String driverKey = 'driver_data';
  static const String fcmTokenKey = 'fcm_token';

  // Location Settings
  static const double defaultLatitude = 40.3777;
  static const double defaultLongitude = 49.8516;
  static const double defaultZoom = 15.0;
  static const int locationUpdateInterval = 5000; // 5 seconds

  // Order Status
  static const String orderPending = 'pending';
  static const String orderAccepted = 'accepted';
  static const String orderDriverAssigned = 'driver_assigned';
  static const String orderDriverArrived = 'driver_arrived';
  static const String orderInProgress = 'in_progress';
  static const String orderCompleted = 'completed';
  static const String orderCancelled = 'cancelled';

  // Driver Status
  static const String driverPending = 'pending';
  static const String driverApproved = 'approved';
  static const String driverRejected = 'rejected';
  static const String driverSuspended = 'suspended';

  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentCard = 'card';
  static const String paymentOnline = 'online';

  // Currency
  static const String currency = 'AZN';

  // App Settings
  static const int otpTimeout = 60; // seconds
  static const int requestTimeout = 30000; // 30 seconds
  static const int maxRetryAttempts = 3;

  // Map Settings
  static const double maxDistanceForOrders = 5.0; // km
  static const double mapPadding = 50.0;

  // Notification Settings
  static const String notificationChannelId = 'ayiqsurucu_driver_channel';
  static const String notificationChannelName = 'Ayiq Sürücü Driver';
  static const String notificationChannelDescription =
      'Driver notifications for orders and updates';
}
