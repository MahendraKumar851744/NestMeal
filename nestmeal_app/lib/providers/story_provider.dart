import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../models/story_model.dart';
import '../services/api_service.dart';

class StoryProvider extends ChangeNotifier {
  List<CookStoryGroup> storyFeed = [];
  List<StoryModel> cookStories = [];
  List<StoryModel> myStories = [];
  bool isLoading = false;
  String? error;

  final ApiService _apiService;

  StoryProvider(this._apiService);

  void _safeNotify() {
    scheduleMicrotask(() => notifyListeners());
  }

  /// Fetch story feed — stories from cooks the customer follows, grouped by cook.
  Future<void> fetchStoryFeed() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response =
          await _apiService.get('${ApiConfig.storiesUrl}/feed/');
      final results =
          response is List ? response : response['results'] as List;
      final stories =
          results.map((json) => StoryModel.fromJson(json)).toList();

      // Group by cook
      final Map<String, List<StoryModel>> grouped = {};
      for (final story in stories) {
        grouped.putIfAbsent(story.cookId, () => []).add(story);
      }
      storyFeed = grouped.values
          .map((stories) => CookStoryGroup.fromStories(stories))
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch active stories for a specific cook (public).
  Future<void> fetchCookStories(String cookId) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response =
          await _apiService.get('${ApiConfig.storiesUrl}/cook/$cookId/');
      final results =
          response is List ? response : response['results'] as List;
      cookStories =
          results.map((json) => StoryModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch cook's own stories.
  Future<void> fetchMyStories() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response =
          await _apiService.get('${ApiConfig.storiesUrl}/my/');
      final results =
          response is List ? response : response['results'] as List;
      myStories =
          results.map((json) => StoryModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Upload a new story (cook only).
  Future<void> uploadStory(XFile file, Uint8List bytes, {String caption = ''}) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      await _apiService.uploadFileBytes(
        '${ApiConfig.storiesUrl}/',
        bytes,
        file.name,
        fieldName: 'image',
        fields: caption.isNotEmpty ? {'caption': caption} : null,
      );
      await fetchMyStories();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a story (cook only).
  Future<void> deleteStory(String storyId) async {
    try {
      await _apiService.delete('${ApiConfig.storiesUrl}/$storyId/');
      myStories.removeWhere((s) => s.id == storyId);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Mark a story as viewed and update local state immediately.
  Future<void> markStoryViewed(String storyId) async {
    // Update local state optimistically so the ring changes without waiting
    storyFeed = storyFeed.map((group) {
      final updated = group.stories.map((s) {
        return s.id == storyId ? s.copyWithViewed() : s;
      }).toList();
      return CookStoryGroup(
        cookId: group.cookId,
        cookDisplayName: group.cookDisplayName,
        cookProfileImageUrl: group.cookProfileImageUrl,
        stories: updated,
      );
    }).toList();
    notifyListeners();

    try {
      await _apiService.post('${ApiConfig.storiesUrl}/$storyId/view/', {});
    } catch (_) {
      // Fire-and-forget — local state already updated
    }
  }

  /// Check if a cook has active stories (from the feed data).
  bool cookHasStories(String cookId) {
    return storyFeed.any((group) => group.cookId == cookId);
  }

  /// Get story group for a specific cook from feed.
  CookStoryGroup? getStoryGroup(String cookId) {
    try {
      return storyFeed.firstWhere((group) => group.cookId == cookId);
    } catch (_) {
      return null;
    }
  }
}
