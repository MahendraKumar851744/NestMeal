import 'helpers.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String role;
  final String? profilePictureUrl;
  final bool isVerified;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final CustomerProfile? customerProfile;
  final CookProfile? cookProfile;
  final AdminProfile? adminProfile;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.profilePictureUrl,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.customerProfile,
    this.cookProfile,
    this.adminProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      profilePictureUrl: json['profile_picture_url'],
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      customerProfile: json['customer_profile'] != null
          ? CustomerProfile.fromJson(json['customer_profile'])
          : null,
      cookProfile: json['cook_profile'] != null
          ? CookProfile.fromJson(json['cook_profile'])
          : null,
      adminProfile: json['admin_profile'] != null
          ? AdminProfile.fromJson(json['admin_profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'profile_picture_url': profilePictureUrl,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'customer_profile': customerProfile?.toJson(),
      'cook_profile': cookProfile?.toJson(),
      'admin_profile': adminProfile?.toJson(),
    };
  }
}

class CustomerProfile {
  final String id;
  final String userId;
  final double walletBalance;
  final String preferredFulfillment;
  final String status;

  CustomerProfile({
    required this.id,
    required this.userId,
    required this.walletBalance,
    required this.preferredFulfillment,
    required this.status,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: json['id'].toString(),
      userId: json['user'].toString(),
      walletBalance: toSafeDouble(json['wallet_balance']),
      preferredFulfillment: json['preferred_fulfillment'] ?? 'pickup',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'wallet_balance': walletBalance,
      'preferred_fulfillment': preferredFulfillment,
      'status': status,
    };
  }
}

class CookProfile {
  final String id;
  final String userId;
  final String displayName;
  final String bio;
  final String kitchenStreet;
  final String kitchenCity;
  final String kitchenState;
  final String kitchenZip;
  final double? kitchenLatitude;
  final double? kitchenLongitude;
  final String pickupInstructions;
  final bool deliveryEnabled;
  final double deliveryRadiusKm;
  final String deliveryFeeType;
  final double deliveryFeeValue;
  final double deliveryMinOrder;
  final double avgRating;
  final int totalReviews;
  final bool isActive;
  final String status;
  final double commissionRate;
  final List<dynamic> pickupLocations;

  CookProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.bio,
    required this.kitchenStreet,
    required this.kitchenCity,
    required this.kitchenState,
    required this.kitchenZip,
    this.kitchenLatitude,
    this.kitchenLongitude,
    required this.pickupInstructions,
    required this.deliveryEnabled,
    required this.deliveryRadiusKm,
    required this.deliveryFeeType,
    required this.deliveryFeeValue,
    required this.deliveryMinOrder,
    required this.avgRating,
    required this.totalReviews,
    required this.isActive,
    required this.status,
    required this.commissionRate,
    required this.pickupLocations,
  });

  factory CookProfile.fromJson(Map<String, dynamic> json) {
    return CookProfile(
      id: json['id'].toString(),
      userId: json['user'].toString(),
      displayName: json['display_name'] ?? '',
      bio: json['bio'] ?? '',
      kitchenStreet: json['kitchen_street'] ?? '',
      kitchenCity: json['kitchen_city'] ?? '',
      kitchenState: json['kitchen_state'] ?? '',
      kitchenZip: json['kitchen_zip'] ?? '',
      kitchenLatitude: json['kitchen_latitude'] != null
          ? toSafeDouble(json['kitchen_latitude'])
          : null,
      kitchenLongitude: json['kitchen_longitude'] != null
          ? toSafeDouble(json['kitchen_longitude'])
          : null,
      pickupInstructions: json['pickup_instructions'] ?? '',
      deliveryEnabled: json['delivery_enabled'] ?? false,
      deliveryRadiusKm: toSafeDouble(json['delivery_radius_km']),
      deliveryFeeType: json['delivery_fee_type'] ?? 'flat',
      deliveryFeeValue: toSafeDouble(json['delivery_fee_value']),
      deliveryMinOrder: toSafeDouble(json['delivery_min_order']),
      avgRating: toSafeDouble(json['avg_rating']),
      totalReviews: json['total_reviews'] ?? 0,
      isActive: json['is_active'] ?? false,
      status: json['status'] ?? '',
      commissionRate: toSafeDouble(json['commission_rate']),
      pickupLocations: json['pickup_locations'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'display_name': displayName,
      'bio': bio,
      'kitchen_street': kitchenStreet,
      'kitchen_city': kitchenCity,
      'kitchen_state': kitchenState,
      'kitchen_zip': kitchenZip,
      'kitchen_latitude': kitchenLatitude,
      'kitchen_longitude': kitchenLongitude,
      'pickup_instructions': pickupInstructions,
      'delivery_enabled': deliveryEnabled,
      'delivery_radius_km': deliveryRadiusKm,
      'delivery_fee_type': deliveryFeeType,
      'delivery_fee_value': deliveryFeeValue,
      'delivery_min_order': deliveryMinOrder,
      'avg_rating': avgRating,
      'total_reviews': totalReviews,
      'is_active': isActive,
      'status': status,
      'commission_rate': commissionRate,
      'pickup_locations': pickupLocations,
    };
  }
}

class AdminProfile {
  final String id;
  final String userId;
  final String adminRole;
  final List<String> permissions;
  final String status;

  AdminProfile({
    required this.id,
    required this.userId,
    required this.adminRole,
    required this.permissions,
    required this.status,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      id: json['id'].toString(),
      userId: json['user'].toString(),
      adminRole: json['admin_role'] ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'admin_role': adminRole,
      'permissions': permissions,
      'status': status,
    };
  }
}
