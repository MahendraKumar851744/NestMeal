import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;
  String? error;

  final ApiService _apiService;

  NotificationProvider(this._apiService);

  void _safeNotify() {
    scheduleMicrotask(() => notifyListeners());
  }

  Future<void> fetchNotifications() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response =
          await _apiService.get('${ApiConfig.notificationsUrl}/');
      final results = response is List ? response : response['results'] as List;
      notifications =
          results.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      await _apiService.patch(
        '${ApiConfig.notificationsUrl}/$id/read/',
        {},
      );
      final index = notifications.indexWhere((n) => n.id == id);
      if (index >= 0) {
        // Refresh notifications to reflect the read status
        await fetchNotifications();
        await fetchUnreadCount();
        return;
      }
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      await _apiService.patch(
        '${ApiConfig.notificationsUrl}/mark-all-read/',
        {},
      );
      unreadCount = 0;
      // Refresh notifications to reflect read status
      await fetchNotifications();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.notificationsUrl}/unread-count/',
      );
      unreadCount = response['count'] ?? 0;
      notifyListeners();
    } catch (e) {
      error = e.toString();
    }
  }
}
