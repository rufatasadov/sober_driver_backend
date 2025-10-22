import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1976D2);
  static const Color secondary = Color(0xFF42A5F5);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF2196F3);
  static const Color text = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);
}

class AppSizes {
  static const double padding = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 24.0;
  static const double radius = 8.0;
  static const double radiusLarge = 12.0;
  static const double iconSize = 24.0;
  static const double iconSizeSmall = 20.0;
  static const double iconSizeLarge = 32.0;
}

class AppStrings {
  // Login
  static const String loginTitle = 'Giriş';
  static const String operatorLogin = 'Operator Girişi';
  static const String dispatcherLogin = 'Dispatcher Girişi';
  static const String adminLogin = 'Admin Girişi';
  static const String phoneNumber = 'Telefon nömrəsi';
  static const String sendOtp = 'OTP göndər';
  static const String otpCode = 'OTP kodu';
  static const String verifyOtp = 'OTP yoxla';
  static const String login = 'Giriş et';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String orders = 'Sifarişlər';
  static const String customers = 'Müştərilər';
  static const String drivers = 'Sürücülər';
  static const String settings = 'Tənzimləmələr';
  static const String logout = 'Çıxış';

  // Stats
  static const String todayOrders = 'Bugünkü sifarişlər';
  static const String completedOrders = 'Tamamlanmış sifarişlər';
  static const String pendingOrders = 'Gözləyən sifarişlər';
  static const String cancelledOrders = 'Ləğv edilmiş sifarişlər';
  static const String onlineDrivers = 'Online sürücülər';

  // Orders
  static const String newOrder = 'Yeni sifariş';
  static const String addOrder = 'Sifariş əlavə et';
  static const String orderNumber = 'Sifariş nömrəsi';
  static const String customer = 'Müştəri';
  static const String driver = 'Sürücü';
  static const String pickup = 'Götürülmə yeri';
  static const String destination = 'Təyinat';
  static const String pickupAddress = 'Götürülmə ünvanı';
  static const String destinationAddress = 'Təyinat ünvanı';
  static const String customerPhone = 'Müştəri telefonu';
  static const String status = 'Status';
  static const String fare = 'Qiymət';
  static const String notes = 'Qeydlər';
  static const String createdAt = 'Yaradılma tarixi';
  static const String assignDriver = 'Sürücü təyin et';
  static const String assignOrder = 'Sifariş təyin et';
  static const String viewDetails = 'Ətraflı bax';
  static const String details = 'Ətraflı';
  static const String editOrder = 'Sifarişi redaktə et';
  static const String cancelOrder = 'Sifarişi ləğv et';
  static const String searchOrders = 'Sifariş axtar';
  static const String noOrders = 'Sifariş yoxdur';

  // Status
  static const String pending = 'Gözləyir';
  static const String accepted = 'Qəbul edildi';
  static const String driverAssigned = 'Sürücü təyin edildi';
  static const String driverArrived = 'Sürücü gəldi';
  static const String inProgress = 'Yoldadır';
  static const String completed = 'Tamamlandı';
  static const String cancelled = 'Ləğv edildi';

  // Customers
  static const String addCustomer = 'Müştəri əlavə et';
  static const String searchCustomers = 'Müştəri axtar';
  static const String noCustomers = 'Müştəri yoxdur';
  static const String totalOrders = 'Ümumi sifarişlər';
  static const String totalSpent = 'Ümumi xərclər';
  static const String registeredAt = 'Qeydiyyat tarixi';
  static const String lastOrder = 'Son sifariş';

  // Drivers
  static const String addDriver = 'Sürücü əlavə et';
  static const String searchDrivers = 'Sürücü axtar';
  static const String noDrivers = 'Sürücü yoxdur';
  static const String online = 'Online';
  static const String offline = 'Offline';
  static const String busy = 'Məşğul';
  static const String location = 'Yer';
  static const String licenseNumber = 'Sürücülük vəsiqəsi';
  static const String vehicleMake = 'Avtomobil markası';
  static const String vehicleModel = 'Avtomobil modeli';
  static const String plateNumber = 'Nömrə';
  static const String rating = 'Qiymətləndirmə';
  static const String totalEarnings = 'Ümumi qazanc';
  static const String todayEarnings = 'Bugünkü qazanc';

  // Payment
  static const String cash = 'Nağd';
  static const String card = 'Kart';
  static const String onlinePayment = 'Online';

  // Common
  static const String save = 'Saxla';
  static const String cancel = 'Ləğv et';
  static const String delete = 'Sil';
  static const String edit = 'Redaktə et';
  static const String add = 'Əlavə et';
  static const String search = 'Axtar';
  static const String filter = 'Filter';
  static const String clear = 'Təmizlə';
  static const String loading = 'Yüklənir...';
  static const String error = 'Xəta';
  static const String success = 'Uğurlu';
  static const String warning = 'Diqqət';
  static const String info = 'Məlumat';
  static const String yes = 'Bəli';
  static const String no = 'Xeyr';
  static const String ok = 'Tamam';
  static const String close = 'Bağla';
  static const String all = 'Hamısı';
  static const String startDate = 'Başlanğıc tarixi';
  static const String endDate = 'Bitmə tarixi';
  static const String name = 'Ad';
  static const String phone = 'Telefon';
  static const String email = 'Email';

  // Validation
  static const String requiredField = 'Bu sahə tələb olunur';
  static const String invalidPhone = 'Düzgün telefon nömrəsi daxil edin';
  static const String invalidOtp = 'OTP 6 rəqəm olmalıdır';
  static const String invalidEmail = 'Düzgün email daxil edin';

  // Messages
  static const String loginSuccess = 'Uğurla giriş edildi';
  static const String loginError = 'Giriş xətası';
  static const String otpSent = 'OTP uğurla göndərildi';
  static const String otpError = 'OTP göndərilmədi';
  static const String orderCreated = 'Sifariş uğurla yaradıldı';
  static const String orderUpdated = 'Sifariş uğurla yeniləndi';
  static const String orderCancelled = 'Sifariş uğurla ləğv edildi';
  static const String driverAssignedSuccess = 'Sürücü uğurla təyin edildi';
  static const String networkError = 'Şəbəkə xətası';
  static const String serverError = 'Server xətası';
  static const String unknownError = 'Naməlum xəta';
}

class ApiEndpoints {
  static const String baseUrl = 'http://81.162.55.58:14122/api';
  static const String auth = '$baseUrl/auth';
  static const String orders = '$baseUrl/orders';
  static const String drivers = '$baseUrl/drivers';
  static const String operator = '$baseUrl/operator';
  static const String users = '$baseUrl/users';
  static const String payments = '$baseUrl/payments';
  static const String notifications = '$baseUrl/notifications';
  static const String admin = '$baseUrl/admin';
}

class SocketEvents {
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String newOrder = 'new_order';
  static const String orderStatusUpdated = 'order_status_updated';
  static const String driverAssigned = 'driver_assigned';
  static const String driverLocationUpdated = 'driver_location_updated';
  static const String orderCompleted = 'order_completed';
  static const String orderCancelled = 'order_cancelled';
}

enum ButtonVariant {
  primary,
  outlined,
  text,
}
