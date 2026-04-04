class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'customer' | 'cook'
  final String message;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      senderId: json['sender']?.toString() ?? '',
      senderName: json['sender_name'] ?? '',
      senderRole: json['sender_role'] ?? 'customer',
      message: json['message'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
