import 'package:equatable/equatable.dart';
import 'user_model.dart';

class OrderModel extends Equatable {
  final String id;
  final String orderNumber;
  final String customerId;
  final String? driverId;
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> destination;
  final String status;
  final int? estimatedTime;
  final double? estimatedDistance;
  final Map<String, dynamic> fare;
  final Map<String, dynamic> payment;
  final Map<String, dynamic>? rating;
  final List<dynamic> timeline;
  final String? notes;
  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields for display
  final UserModel? customer;
  final DriverModel? driver;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.driverId,
    required this.pickup,
    required this.destination,
    required this.status,
    this.estimatedTime,
    this.estimatedDistance,
    required this.fare,
    required this.payment,
    this.rating,
    required this.timeline,
    this.notes,
    this.cancelledBy,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.driver,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customerId: json['customerId'] ?? '',
      driverId: json['driverId'],
      pickup: json['pickup'] ?? {},
      destination: json['destination'] ?? {},
      status: json['status'] ?? 'pending',
      estimatedTime: json['estimatedTime'],
      estimatedDistance: json['estimatedDistance']?.toDouble(),
      fare: json['fare'] ?? {},
      payment: json['payment'] ?? {},
      rating: json['rating'],
      timeline: json['timeline'] ?? [],
      notes: json['notes'],
      cancelledBy: json['cancelledBy'],
      cancellationReason: json['cancellationReason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      customer: json['customer'] != null 
          ? UserModel.fromJson(json['customer']) 
          : null,
      driver: json['driver'] != null 
          ? DriverModel.fromJson(json['driver']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'driverId': driverId,
      'pickup': pickup,
      'destination': destination,
      'status': status,
      'estimatedTime': estimatedTime,
      'estimatedDistance': estimatedDistance,
      'fare': fare,
      'payment': payment,
      'rating': rating,
      'timeline': timeline,
      'notes': notes,
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'customer': customer?.toJson(),
      'driver': driver?.toJson(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? driverId,
    Map<String, dynamic>? pickup,
    Map<String, dynamic>? destination,
    String? status,
    int? estimatedTime,
    double? estimatedDistance,
    Map<String, dynamic>? fare,
    Map<String, dynamic>? payment,
    Map<String, dynamic>? rating,
    List<dynamic>? timeline,
    String? notes,
    String? cancelledBy,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? customer,
    DriverModel? driver,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      status: status ?? this.status,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      fare: fare ?? this.fare,
      payment: payment ?? this.payment,
      rating: rating ?? this.rating,
      timeline: timeline ?? this.timeline,
      notes: notes ?? this.notes,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customer: customer ?? this.customer,
      driver: driver ?? this.driver,
    );
  }

  // Helper methods
  String get pickupAddress => pickup['address'] ?? '';
  String get destinationAddress => destination['address'] ?? '';
  List<double> get pickupCoordinates => 
      (pickup['coordinates'] as List?)?.cast<double>() ?? [];
  List<double> get destinationCoordinates => 
      (destination['coordinates'] as List?)?.cast<double>() ?? [];
  
  double get totalFare => (fare['total'] ?? 0).toDouble();
  String get currency => fare['currency'] ?? 'AZN';
  String get paymentMethod => payment['method'] ?? 'cash';
  
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        customerId,
        driverId,
        pickup,
        destination,
        status,
        estimatedTime,
        estimatedDistance,
        fare,
        payment,
        rating,
        timeline,
        notes,
        cancelledBy,
        cancellationReason,
        createdAt,
        updatedAt,
        customer,
        driver,
      ];
}

class DriverModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String licenseNumber;
  final Map<String, dynamic> vehicleInfo;
  final Map<String, dynamic> rating;
  final Map<String, dynamic>? currentLocation;
  final bool isOnline;

  const DriverModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    required this.vehicleInfo,
    required this.rating,
    this.currentLocation,
    required this.isOnline,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      vehicleInfo: json['vehicleInfo'] ?? {},
      rating: json['rating'] ?? {},
      currentLocation: json['currentLocation'],
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'vehicleInfo': vehicleInfo,
      'rating': rating,
      'currentLocation': currentLocation,
      'isOnline': isOnline,
    };
  }

  String get vehicleMake => vehicleInfo['make'] ?? '';
  String get vehicleModel => vehicleInfo['model'] ?? '';
  String get vehiclePlate => vehicleInfo['plateNumber'] ?? '';
  String get vehicleColor => vehicleInfo['color'] ?? '';
  int get vehicleYear => vehicleInfo['year'] ?? 0;
  
  double get averageRating => (rating['average'] ?? 0).toDouble();
  int get ratingCount => rating['count'] ?? 0;
  
  List<double> get locationCoordinates {
    if (currentLocation == null) return [];
    return (currentLocation!['coordinates'] as List?)?.cast<double>() ?? [];
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        phone,
        licenseNumber,
        vehicleInfo,
        rating,
        currentLocation,
        isOnline,
      ];
}
