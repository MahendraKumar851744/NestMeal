class StoryModel {
  final String id;
  final String cookId;
  final String cookDisplayName;
  final String imageUrl;
  final String caption;
  final String createdAt;
  final String expiresAt;
  final bool isViewed;
  final bool isActive;
  final int viewCount;

  StoryModel({
    required this.id,
    required this.cookId,
    required this.cookDisplayName,
    required this.imageUrl,
    this.caption = '',
    required this.createdAt,
    required this.expiresAt,
    this.isViewed = false,
    this.isActive = true,
    this.viewCount = 0,
  });

  bool get isExpired {
    try {
      return DateTime.parse(expiresAt).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'].toString(),
      cookId: json['cook_id'].toString(),
      cookDisplayName: json['cook_display_name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      caption: json['caption'] ?? '',
      createdAt: json['created_at'] ?? '',
      expiresAt: json['expires_at'] ?? '',
      isViewed: json['is_viewed'] ?? false,
      isActive: json['is_active'] ?? true,
      viewCount: json['view_count'] ?? 0,
    );
  }

  StoryModel copyWithViewed() => StoryModel(
        id: id,
        cookId: cookId,
        cookDisplayName: cookDisplayName,
        imageUrl: imageUrl,
        caption: caption,
        createdAt: createdAt,
        expiresAt: expiresAt,
        isViewed: true,
        isActive: isActive,
        viewCount: viewCount,
      );
}

class CookStoryGroup {
  final String cookId;
  final String cookDisplayName;
  final List<StoryModel> stories;

  CookStoryGroup({
    required this.cookId,
    required this.cookDisplayName,
    required this.stories,
  });

  bool get hasUnviewed => stories.any((s) => !s.isViewed);

  factory CookStoryGroup.fromStories(List<StoryModel> stories) {
    return CookStoryGroup(
      cookId: stories.first.cookId,
      cookDisplayName: stories.first.cookDisplayName,
      stories: stories,
    );
  }
}
