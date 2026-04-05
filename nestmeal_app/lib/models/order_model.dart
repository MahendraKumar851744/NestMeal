import '../config/api_config.dart';
import 'helpers.dart';

class OrderItemExtra {
  final String name;
  final double price;
  final int quantity;

  OrderItemExtra({
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  factory OrderItemExtra.fromJson(Map<String, dynamic> json) {
    return OrderItemExtra(
      name: json['name'] ?? '',
      price: toSafeDouble(json['price']),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class OrderItem {
  final String id;
  final String mealId;
  final String mealTitle;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final List<OrderItemExtra> extras;

  OrderItem({
    required this.id,
    required this.mealId,
    required this.mealTitle,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.extras = const [],
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'].toString(),
      mealId: json['meal_id']?.toString() ?? json['meal']?.toString() ?? '',
      mealTitle: json['meal_title'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: toSafeDouble(json['unit_price']),
      lineTotal: toSafeDouble(json['line_total']),
      extras: (json['extras'] as List<dynamic>? ?? [])
          .map((e) => OrderItemExtra.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal_id': mealId,
      'meal_title': mealTitle,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
    };
  }
}

class OrderListItem {
  final String id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final String fulfillmentType;
  final String createdAt;
  final String cookDisplayName;
  final String? cookProfileImageUrl;
  final String? pickupCode;
  final String? acceptanceDeadline;

  OrderListItem({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.fulfillmentType,
    required this.createdAt,
    required this.cookDisplayName,
    this.cookProfileImageUrl,
    this.pickupCode,
    this.acceptanceDeadline,
  });

  factory OrderListItem.fromJson(Map<String, dynamic> json) {
    return OrderListItem(
      id: json['id'].toString(),
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? '',
      totalAmount: toSafeDouble(json['total_amount']),
      fulfillmentType: json['fulfillment_type'] ?? '',
      createdAt: json['created_at'] ?? '',
      cookDisplayName: json['cook_display_name'] ?? '',
      cookProfileImageUrl: ApiConfig.absoluteUrl(json['cook_profile_image_url']),
      pickupCode: json['pickup_code'],
      acceptanceDeadline: json['acceptance_deadline'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'status': status,
      'total_amount': totalAmount,
      'fulfillment_type': fulfillmentType,
      'created_at': createdAt,
      'cook_display_name': cookDisplayName,
    };
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String cookId;
  final String cookDisplayName;
  final String? cookProfileImageUrl;
  final String status;
  final String fulfillmentType;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String currency;
  final String? pickupCode;
  final String? couponCode;
  final String? specialInstructions;
  final String? deliveryStreet;
  final String? deliveryCity;
  final String? deliveryState;
  final String? deliveryZip;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? scheduledDate;
  final String? scheduledSlot;
  final String? pickupSlotId;
  final String? deliverySlotId;
  final String? estimatedReadyTime;
  final String? actualReadyTime;
  final String? estimatedDeliveryTime;
  final String? actualDeliveryTime;
  final String? cancelledAt;
  final String? cancellationReason;
  final String? cancelledBy;
  final String? acceptanceDeadline;
  final String paymentStatus;
  final String? paymentMethod;
  final List<OrderItem> items;
  final String createdAt;
  final String updatedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.cookId,
    required this.cookDisplayName,
    this.cookProfileImageUrl,
    required this.status,
    required this.fulfillmentType,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.currency,
    this.pickupCode,
    this.couponCode,
    this.specialInstructions,
    this.deliveryStreet,
    this.deliveryCity,
    this.deliveryState,
    this.deliveryZip,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.scheduledDate,
    this.scheduledSlot,
    this.pickupSlotId,
    this.deliverySlotId,
    this.estimatedReadyTime,
    this.actualReadyTime,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledBy,
    this.acceptanceDeadline,
    required this.paymentStatus,
    this.paymentMethod,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'].toString(),
      orderNumber: json['order_number'] ?? '',
      customerId: json['customer']?.toString() ?? json['customer_id']?.toString() ?? '',
      customerName: json['customer_name'] ?? '',
      cookId: json['cook']?.toString() ?? json['cook_id']?.toString() ?? '',
      cookDisplayName: json['cook_display_name'] ?? '',
      cookProfileImageUrl: ApiConfig.absoluteUrl(json['cook_profile_image_url']),
      status: json['status'] ?? '',
      fulfillmentType: json['fulfillment_type'] ?? '',
      subtotal: toSafeDouble(json['item_total'] ?? json['subtotal']),
      deliveryFee: toSafeDouble(json['delivery_fee']),
      serviceFee: toSafeDouble(json['platform_fee'] ?? json['service_fee']),
      taxAmount: toSafeDouble(json['tax_amount']),
      discountAmount: toSafeDouble(json['discount_amount']),
      totalAmount: toSafeDouble(json['total_amount']),
      currency: json['currency'] ?? 'AUD',
      pickupCode: json['pickup_code'],
      couponCode: json['coupon_code'],
      specialInstructions: json['special_instructions'],
      deliveryStreet: json['delivery_address_street'] ?? json['delivery_street'],
      deliveryCity: json['delivery_address_city'] ?? json['delivery_city'],
      deliveryState: json['delivery_address_state'] ?? json['delivery_state'],
      deliveryZip: json['delivery_address_zip'] ?? json['delivery_zip'],
      deliveryLatitude: (json['delivery_address_lat'] ?? json['delivery_latitude']) != null
          ? toSafeDouble(json['delivery_address_lat'] ?? json['delivery_latitude'])
          : null,
      deliveryLongitude: (json['delivery_address_lng'] ?? json['delivery_longitude']) != null
          ? toSafeDouble(json['delivery_address_lng'] ?? json['delivery_longitude'])
          : null,
      scheduledDate: json['scheduled_date'],
      scheduledSlot: json['scheduled_slot'],
      pickupSlotId: json['pickup_slot']?.toString(),
      deliverySlotId: json['delivery_slot']?.toString(),
      estimatedReadyTime: json['estimated_ready_time'],
      actualReadyTime: json['actual_ready_time'],
      estimatedDeliveryTime: json['estimated_delivery_time'],
      actualDeliveryTime: json['actual_delivery_time'],
      cancelledAt: json['cancelled_at'],
      cancellationReason: json['cancellation_reason'],
      cancelledBy: json['cancelled_by'],
      acceptanceDeadline: json['acceptance_deadline'],
      paymentStatus: json['payment_status'] ?? '',
      paymentMethod: json['payment_method'],
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer': customerId,
      'customer_name': customerName,
      'cook': cookId,
      'cook_display_name': cookDisplayName,
      'status': status,
      'fulfillment_type': fulfillmentType,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'service_fee': serviceFee,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'currency': currency,
      'pickup_code': pickupCode,
      'coupon_code': couponCode,
      'special_instructions': specialInstructions,
      'delivery_street': deliveryStreet,
      'delivery_city': deliveryCity,
      'delivery_state': deliveryState,
      'delivery_zip': deliveryZip,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'scheduled_date': scheduledDate,
      'scheduled_slot': scheduledSlot,
      'pickup_slot': pickupSlotId,
      'delivery_slot': deliverySlotId,
      'estimated_ready_time': estimatedReadyTime,
      'actual_ready_time': actualReadyTime,
      'estimated_delivery_time': estimatedDeliveryTime,
      'actual_delivery_time': actualDeliveryTime,
      'cancelled_at': cancelledAt,
      'cancellation_reason': cancellationReason,
      'cancelled_by': cancelledBy,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
