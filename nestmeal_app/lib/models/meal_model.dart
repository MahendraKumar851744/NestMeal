import 'helpers.dart';
import 'user_model.dart' show PickupLocationModel;

class MealExtra {
  final String id;
  final String meal;
  final String name;
  final double price;
  final bool isAvailable;
  final int displayOrder;

  MealExtra({
    required this.id,
    required this.meal,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.displayOrder,
  });

  factory MealExtra.fromJson(Map<String, dynamic> json) {
    return MealExtra(
      id: json['id'].toString(),
      meal: json['meal']?.toString() ?? '',
      name: json['name'] ?? '',
      price: toSafeDouble(json['price']),
      isAvailable: json['is_available'] ?? true,
      displayOrder: json['display_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal': meal,
      'name': name,
      'price': price,
      'is_available': isAvailable,
      'display_order': displayOrder,
    };
  }
}

class MealImage {
  final String id;
  final String meal;
  final String imageUrl;
  final int displayOrder;

  MealImage({
    required this.id,
    required this.meal,
    required this.imageUrl,
    required this.displayOrder,
  });

  factory MealImage.fromJson(Map<String, dynamic> json) {
    return MealImage(
      id: json['id'].toString(),
      meal: json['meal'].toString(),
      imageUrl: json['image_url'] ?? json['image'] ?? '',
      displayOrder: json['display_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal': meal,
      'image_url': imageUrl,
      'display_order': displayOrder,
    };
  }
}

class CookCard {
  final String id;
  final String displayName;
  final String bio;
  final double avgRating;
  final int totalReviews;
  final int followersCount;
  final bool isFollowed;
  final String kitchenCity;
  final String kitchenState;
  final bool deliveryEnabled;
  final double deliveryRadiusKm;
  final bool isActive;
  final String status;
  final List<PickupLocationModel> pickupLocations;

  CookCard({
    required this.id,
    required this.displayName,
    required this.bio,
    required this.avgRating,
    required this.totalReviews,
    this.followersCount = 0,
    this.isFollowed = false,
    required this.kitchenCity,
    required this.kitchenState,
    required this.deliveryEnabled,
    required this.deliveryRadiusKm,
    required this.isActive,
    required this.status,
    this.pickupLocations = const [],
  });

  factory CookCard.fromJson(Map<String, dynamic> json) {
    return CookCard(
      id: json['id'].toString(),
      displayName: json['display_name'] ?? '',
      bio: json['bio'] ?? '',
      avgRating: toSafeDouble(json['avg_rating']),
      totalReviews: json['total_reviews'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      isFollowed: json['is_followed'] ?? false,
      kitchenCity: json['kitchen_city'] ?? '',
      kitchenState: json['kitchen_state'] ?? '',
      deliveryEnabled: json['delivery_enabled'] ?? false,
      deliveryRadiusKm: toSafeDouble(json['delivery_radius_km']),
      isActive: json['is_active'] ?? false,
      status: json['status'] ?? '',
      pickupLocations: (json['pickup_locations'] as List?)
              ?.map((loc) => PickupLocationModel.fromJson(loc))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'bio': bio,
      'avg_rating': avgRating,
      'total_reviews': totalReviews,
      'followers_count': followersCount,
      'is_followed': isFollowed,
      'kitchen_city': kitchenCity,
      'kitchen_state': kitchenState,
      'delivery_enabled': deliveryEnabled,
      'delivery_radius_km': deliveryRadiusKm,
      'is_active': isActive,
      'status': status,
    };
  }
}

class MealModel {
  final String id;
  final String cookId;
  final String title;
  final String description;
  final String shortDescription;
  final double price;
  final double discountPercentage;
  final double effectivePrice;
  final String currency;
  final String category;
  final String cuisineType;
  final String mealType;
  final List<String> dietaryTags;
  final List<String> allergenInfo;
  final String spiceLevel;
  final String servingSize;
  final int? caloriesApprox;
  final int preparationTimeMins;
  final List<String> fulfillmentModes;
  final bool isAvailable;
  final List<String> availableDays;
  final int totalOrders;
  final double avgRating;
  final List<String> tags;
  final bool isFeatured;
  final String status;
  final List<MealImage> images;
  final List<MealExtra> extras;
  final String? orderCutoffTime;
  final bool isPastCutoff;
  final String cookDisplayName;
  final String createdAt;
  final String updatedAt;

  MealModel({
    required this.id,
    required this.cookId,
    required this.title,
    required this.description,
    required this.shortDescription,
    required this.price,
    required this.discountPercentage,
    required this.effectivePrice,
    required this.currency,
    required this.category,
    required this.cuisineType,
    required this.mealType,
    required this.dietaryTags,
    required this.allergenInfo,
    required this.spiceLevel,
    required this.servingSize,
    this.caloriesApprox,
    required this.preparationTimeMins,
    required this.fulfillmentModes,
    required this.isAvailable,
    required this.availableDays,
    this.orderCutoffTime,
    this.isPastCutoff = false,
    required this.totalOrders,
    required this.avgRating,
    required this.tags,
    required this.isFeatured,
    required this.status,
    required this.images,
    this.extras = const [],
    required this.cookDisplayName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'].toString(),
      cookId: (json['cook'] is Map) ? json['cook']['id'].toString() : json['cook'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['short_description'] ?? '',
      price: toSafeDouble(json['price']),
      discountPercentage: toSafeDouble(json['discount_percentage']),
      effectivePrice: toSafeDouble(json['effective_price'] ?? json['price']),
      currency: json['currency'] ?? 'AUD',
      category: json['category'] ?? '',
      cuisineType: json['cuisine_type'] ?? '',
      mealType: json['meal_type'] ?? '',
      dietaryTags: List<String>.from(json['dietary_tags'] ?? []),
      allergenInfo: List<String>.from(json['allergen_info'] ?? []),
      spiceLevel: json['spice_level'] ?? '',
      servingSize: json['serving_size'] ?? '',
      caloriesApprox: json['calories_approx'],
      preparationTimeMins: json['preparation_time_mins'] ?? 0,
      fulfillmentModes: List<String>.from(json['fulfillment_modes'] ?? []),
      isAvailable: json['is_available'] ?? false,
      availableDays: List<String>.from(json['available_days'] ?? []),
      totalOrders: json['total_orders'] ?? 0,
      avgRating: toSafeDouble(json['avg_rating']),
      tags: List<String>.from(json['tags'] ?? []),
      isFeatured: json['is_featured'] ?? false,
      status: json['status'] ?? '',
      images: (json['images'] as List?)
              ?.map((img) => MealImage.fromJson(img))
              .toList() ??
          [],
      extras: (json['extras'] as List?)
              ?.map((e) => MealExtra.fromJson(e))
              .toList() ??
          [],
      orderCutoffTime: json['order_cutoff_time'],
      isPastCutoff: json['is_past_cutoff'] ?? false,
      cookDisplayName: json['cook_display_name'] ??
          ((json['cook'] is Map) ? (json['cook']['display_name'] ?? '') : ''),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cook': cookId,
      'title': title,
      'description': description,
      'short_description': shortDescription,
      'price': price,
      'discount_percentage': discountPercentage,
      'effective_price': effectivePrice,
      'currency': currency,
      'category': category,
      'cuisine_type': cuisineType,
      'meal_type': mealType,
      'dietary_tags': dietaryTags,
      'allergen_info': allergenInfo,
      'spice_level': spiceLevel,
      'serving_size': servingSize,
      'calories_approx': caloriesApprox,
      'preparation_time_mins': preparationTimeMins,
      'fulfillment_modes': fulfillmentModes,
      'is_available': isAvailable,
      'available_days': availableDays,
      'order_cutoff_time': orderCutoffTime,
      'total_orders': totalOrders,
      'avg_rating': avgRating,
      'tags': tags,
      'is_featured': isFeatured,
      'status': status,
      'images': images.map((img) => img.toJson()).toList(),
      'extras': extras.map((e) => e.toJson()).toList(),
      'cook_display_name': cookDisplayName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class MealDetail extends MealModel {
  final CookCard cookCard;

  MealDetail({
    required super.id,
    required super.cookId,
    required super.title,
    required super.description,
    required super.shortDescription,
    required super.price,
    required super.discountPercentage,
    required super.effectivePrice,
    required super.currency,
    required super.category,
    required super.cuisineType,
    required super.mealType,
    required super.dietaryTags,
    required super.allergenInfo,
    required super.spiceLevel,
    required super.servingSize,
    super.caloriesApprox,
    required super.preparationTimeMins,
    required super.fulfillmentModes,
    required super.isAvailable,
    required super.availableDays,
    super.orderCutoffTime,
    super.isPastCutoff,
    required super.totalOrders,
    required super.avgRating,
    required super.tags,
    required super.isFeatured,
    required super.status,
    required super.images,
    super.extras,
    required super.cookDisplayName,
    required super.createdAt,
    required super.updatedAt,
    required this.cookCard,
  });

  factory MealDetail.fromJson(Map<String, dynamic> json) {
    final cookData = json['cook'] is Map<String, dynamic>
        ? json['cook'] as Map<String, dynamic>
        : <String, dynamic>{};

    return MealDetail(
      id: json['id'].toString(),
      cookId: cookData.isNotEmpty ? cookData['id'].toString() : json['cook'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['short_description'] ?? '',
      price: toSafeDouble(json['price']),
      discountPercentage: toSafeDouble(json['discount_percentage']),
      effectivePrice: toSafeDouble(json['effective_price'] ?? json['price']),
      currency: json['currency'] ?? 'AUD',
      category: json['category'] ?? '',
      cuisineType: json['cuisine_type'] ?? '',
      mealType: json['meal_type'] ?? '',
      dietaryTags: List<String>.from(json['dietary_tags'] ?? []),
      allergenInfo: List<String>.from(json['allergen_info'] ?? []),
      spiceLevel: json['spice_level'] ?? '',
      servingSize: json['serving_size'] ?? '',
      caloriesApprox: json['calories_approx'],
      preparationTimeMins: json['preparation_time_mins'] ?? 0,
      fulfillmentModes: List<String>.from(json['fulfillment_modes'] ?? []),
      isAvailable: json['is_available'] ?? false,
      availableDays: List<String>.from(json['available_days'] ?? []),
      orderCutoffTime: json['order_cutoff_time'],
      isPastCutoff: json['is_past_cutoff'] ?? false,
      totalOrders: json['total_orders'] ?? 0,
      avgRating: toSafeDouble(json['avg_rating']),
      tags: List<String>.from(json['tags'] ?? []),
      isFeatured: json['is_featured'] ?? false,
      status: json['status'] ?? '',
      images: (json['images'] as List?)
              ?.map((img) => MealImage.fromJson(img))
              .toList() ??
          [],
      extras: (json['extras'] as List?)
              ?.map((e) => MealExtra.fromJson(e))
              .toList() ??
          [],
      cookDisplayName: json['cook_display_name'] ??
          (cookData.isNotEmpty ? (cookData['display_name'] ?? '') : ''),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      cookCard: cookData.isNotEmpty
          ? CookCard.fromJson(cookData)
          : CookCard(
              id: '',
              displayName: '',
              bio: '',
              avgRating: 0,
              totalReviews: 0,
              kitchenCity: '',
              kitchenState: '',
              deliveryEnabled: false,
              deliveryRadiusKm: 0,
              isActive: false,
              status: '',
            ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['cook'] = cookCard.toJson();
    return map;
  }
}
