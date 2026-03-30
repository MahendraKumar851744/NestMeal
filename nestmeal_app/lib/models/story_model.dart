class StoryModel {
  final String id;
  final String cookId;
  final String cookDisplayName;
  final String imageUrl;
  final String caption;
  final String createdAt;
  final String expiresAt;

  StoryModel({
    required this.id,
    required this.cookId,
    required this.cookDisplayName,
    required this.imageUrl,
    this.caption = '',
    required this.createdAt,
    required this.expiresAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'].toString(),
      cookId: json['cook_id'].toString(),
      cookDisplayName: json['cook_display_name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      caption: json['caption'] ?? '',
      createdAt: json['created_at'] ?? '',
      expiresAt: json['expires_at'] ?? '',
    );
  }
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

  factory CookStoryGroup.fromStories(List<StoryModel> stories) {
    return CookStoryGroup(
      cookId: stories.first.cookId,
      cookDisplayName: stories.first.cookDisplayName,
      stories: stories,
    );
  }
}
