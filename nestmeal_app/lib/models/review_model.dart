class ReviewModel {
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String cookId;
  final String cookName;
  final String mealId;
  final String mealTitle;
  final int rating;
  final int? deliveryRating;
  final String comment;
  final String? cookReply;
  final String? cookRepliedAt;
  final bool isVisible;
  final bool isFlagged;
  final List<dynamic> images;
  final String createdAt;
  final String updatedAt;

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.cookId,
    required this.cookName,
    required this.mealId,
    required this.mealTitle,
    required this.rating,
    this.deliveryRating,
    required this.comment,
    this.cookReply,
    this.cookRepliedAt,
    required this.isVisible,
    required this.isFlagged,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'].toString(),
      orderId: json['order']?.toString() ?? json['order_id']?.toString() ?? '',
      customerId: json['customer']?.toString() ?? json['customer_id']?.toString() ?? '',
      customerName: json['customer_name'] ?? '',
      cookId: json['cook']?.toString() ?? json['cook_id']?.toString() ?? '',
      cookName: json['cook_name'] ?? '',
      mealId: json['meal']?.toString() ?? json['meal_id']?.toString() ?? '',
      mealTitle: json['meal_title'] ?? '',
      rating: json['rating'] ?? 0,
      deliveryRating: json['delivery_rating'],
      comment: json['comment'] ?? '',
      cookReply: json['cook_reply'],
      cookRepliedAt: json['cook_replied_at'],
      isVisible: json['is_visible'] ?? true,
      isFlagged: json['is_flagged'] ?? false,
      images: json['images'] ?? [],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': orderId,
      'customer': customerId,
      'customer_name': customerName,
      'cook': cookId,
      'cook_name': cookName,
      'meal': mealId,
      'meal_title': mealTitle,
      'rating': rating,
      'delivery_rating': deliveryRating,
      'comment': comment,
      'cook_reply': cookReply,
      'cook_replied_at': cookRepliedAt,
      'is_visible': isVisible,
      'is_flagged': isFlagged,
      'images': images,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
