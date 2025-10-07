import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final bool isVerified;
  final bool isActive;
  final String? profileImage;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final String? fcmToken;
  final double? averageRating;
  final int? ratingCount;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehiclePlate;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    required this.isVerified,
    required this.isActive,
    this.profileImage,
    this.lastLogin,
    required this.createdAt,
    this.fcmToken,
    this.averageRating,
    this.ratingCount,
    this.vehicleMake,
    this.vehicleModel,
    this.vehiclePlate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'customer',
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      profileImage: json['profileImage'],
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      fcmToken: json['fcmToken'],
      averageRating: json['averageRating']?.toDouble(),
      ratingCount: json['ratingCount'],
      vehicleMake: json['vehicleMake'],
      vehicleModel: json['vehicleModel'],
      vehiclePlate: json['vehiclePlate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'isVerified': isVerified,
      'isActive': isActive,
      'profileImage': profileImage,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'fcmToken': fcmToken,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehiclePlate': vehiclePlate,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    bool? isVerified,
    bool? isActive,
    String? profileImage,
    DateTime? lastLogin,
    DateTime? createdAt,
    String? fcmToken,
    double? averageRating,
    int? ratingCount,
    String? vehicleMake,
    String? vehicleModel,
    String? vehiclePlate,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      profileImage: profileImage ?? this.profileImage,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
    );
  }

  // Convenience getters
  bool get isDriver => role == 'driver';
  bool get isCustomer => role == 'customer';
  bool get isOperator => role == 'operator';
  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    email,
    role,
    isVerified,
    isActive,
    profileImage,
    lastLogin,
    createdAt,
    fcmToken,
    averageRating,
    ratingCount,
    vehicleMake,
    vehicleModel,
    vehiclePlate,
  ];
}