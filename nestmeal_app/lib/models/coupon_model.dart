import 'helpers.dart';

class CouponModel {
  final String id;
  final String code;
  final String description;
  final String discountType;
  final double discountValue;
  final double? minOrderAmount;
  final double? maxDiscountAmount;
  final int? usageLimit;
  final int usageCount;
  final int? perUserLimit;
  final String? validFrom;
  final String? validUntil;
  final bool isActive;
  final String? applicableTo;
  final String? cookId;
  final String createdAt;
  final String updatedAt;

  CouponModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.usageLimit,
    required this.usageCount,
    this.perUserLimit,
    this.validFrom,
    this.validUntil,
    required this.isActive,
    this.applicableTo,
    this.cookId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'].toString(),
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discount_type'] ?? '',
      discountValue: toSafeDouble(json['discount_value']),
      minOrderAmount: json['min_order_amount'] != null
          ? toSafeDouble(json['min_order_amount'])
          : null,
      maxDiscountAmount: json['max_discount_amount'] != null
          ? toSafeDouble(json['max_discount_amount'])
          : null,
      usageLimit: json['usage_limit'],
      usageCount: json['usage_count'] ?? 0,
      perUserLimit: json['per_user_limit'],
      validFrom: json['valid_from'],
      validUntil: json['valid_until'],
      isActive: json['is_active'] ?? false,
      applicableTo: json['applicable_to'],
      cookId: json['cook']?.toString(),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_amount': minOrderAmount,
      'max_discount_amount': maxDiscountAmount,
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'per_user_limit': perUserLimit,
      'valid_from': validFrom,
      'valid_until': validUntil,
      'is_active': isActive,
      'applicable_to': applicableTo,
      'cook': cookId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class CouponValidationResult {
  final bool valid;
  final String couponCode;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final String description;

  CouponValidationResult({
    required this.valid,
    required this.couponCode,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.description,
  });

  factory CouponValidationResult.fromJson(Map<String, dynamic> json) {
    return CouponValidationResult(
      valid: json['valid'] ?? false,
      couponCode: json['coupon_code'] ?? '',
      discountType: json['discount_type'] ?? '',
      discountValue: toSafeDouble(json['discount_value']),
      discountAmount: toSafeDouble(json['discount_amount']),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valid': valid,
      'coupon_code': couponCode,
      'discount_type': discountType,
      'discount_value': discountValue,
      'discount_amount': discountAmount,
      'description': description,
    };
  }
}
