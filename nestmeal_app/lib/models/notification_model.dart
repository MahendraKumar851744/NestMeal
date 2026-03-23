class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String channel;
  final String eventType;
  final String? referenceId;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.channel,
    required this.eventType,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      userId: json['user']?.toString() ?? json['user_id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      channel: json['channel'] ?? '',
      eventType: json['event_type'] ?? '',
      referenceId: json['reference_id']?.toString(),
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'title': title,
      'message': message,
      'channel': channel,
      'event_type': eventType,
      'reference_id': referenceId,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }
}
