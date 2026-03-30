class PendingCook {
  final String id;
  final String displayName;
  final String kitchenCity;
  final String status;
  final DateTime createdAt;

  PendingCook({
    required this.id,
    required this.displayName,
    required this.kitchenCity,
    required this.status,
    required this.createdAt,
  });

  factory PendingCook.fromJson(Map<String, dynamic> json) {
    return PendingCook(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name'] ?? 'Unknown Cook',
      kitchenCity: json['kitchen_city'] ?? 'Unknown Location',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  // Helper to format "2 days ago" style dates
  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}