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
  final UserModel? driver;

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
    this.driver,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customerId: json['customerId'] ?? '',
      driverId: json['driverId'],
      pickup: Map<String, dynamic>.from(json['pickup'] ?? {}),
      destination: Map<String, dynamic>.from(json['destination'] ?? {}),
      status: json['status'] ?? 'pending',
      estimatedTime: json['estimatedTime'],
      estimatedDistance: json['estimatedDistance']?.toDouble(),
      fare: Map<String, dynamic>.from(json['fare'] ?? {}),
      payment: Map<String, dynamic>.from(json['payment'] ?? {}),
      rating: json['rating'] != null 
          ? Map<String, dynamic>.from(json['rating']) 
          : null,
      timeline: List<dynamic>.from(json['timeline'] ?? []),
      notes: json['notes'],
      cancelledBy: json['cancelledBy'],
      cancellationReason: json['cancellationReason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      driver: json['driver'] != null 
          ? UserModel.fromJson(json['driver']) 
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
    UserModel? driver,
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
      driver: driver ?? this.driver,
    );
  }

  // Convenience getters
  String get pickupAddress => pickup['address'] ?? '';
  String get destinationAddress => destination['address'] ?? '';
  List<double> get pickupCoordinates => List<double>.from(pickup['coordinates'] ?? []);
  List<double> get destinationCoordinates => List<double>.from(destination['coordinates'] ?? []);
  
  String get paymentMethod => payment['method'] ?? 'cash';
  double get totalFare => (fare['total'] ?? 0).toDouble();
  String get currency => fare['currency'] ?? 'AZN';
  
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
    driver,
  ];
}