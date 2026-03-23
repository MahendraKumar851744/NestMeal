class PickupSlotModel {
  final String id;
  final String cookId;
  final String date;
  final String startTime;
  final String endTime;
  final int maxOrders;
  final int bookedOrders;
  final bool isActive;
  final bool isAvailableFlag;
  final String locationLabel;
  final String status;
  final String createdAt;

  PickupSlotModel({
    required this.id,
    required this.cookId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.maxOrders,
    required this.bookedOrders,
    required this.isActive,
    required this.isAvailableFlag,
    required this.locationLabel,
    required this.status,
    required this.createdAt,
  });

  bool get isAvailable => isAvailableFlag && isActive && status == 'open';

  int get slotsRemaining => maxOrders - bookedOrders;

  String get displayTime {
    final start = startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
    final end = endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
    return '$start - $end';
  }

  String get displayDate {
    return date;
  }

  factory PickupSlotModel.fromJson(Map<String, dynamic> json) {
    return PickupSlotModel(
      id: json['id'].toString(),
      cookId: json['cook']?.toString() ?? json['cook_id']?.toString() ?? '',
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      maxOrders: json['max_orders'] ?? 0,
      bookedOrders: json['booked_orders'] ?? json['current_orders'] ?? 0,
      isActive: json['is_active'] ?? json['is_available'] ?? false,
      isAvailableFlag: json['is_available'] ?? true,
      locationLabel: json['location_label'] ?? '',
      status: json['status'] ?? 'open',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cook': cookId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'max_orders': maxOrders,
      'booked_orders': bookedOrders,
      'is_available': isAvailableFlag,
      'location_label': locationLabel,
      'status': status,
      'created_at': createdAt,
    };
  }
}
