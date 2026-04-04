import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isSending = false;
  String? error;

  final ApiService _apiService;
  Timer? _pollTimer;
  String? _currentOrderId;

  ChatProvider(this._apiService);

  /// Start polling messages for [orderId] every 4 seconds.
  void startPolling(String orderId) {
    _currentOrderId = orderId;
    messages = [];
    fetchMessages(orderId);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      fetchMessages(orderId, silent: true);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _currentOrderId = null;
  }

  Future<void> fetchMessages(String orderId, {bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      scheduleMicrotask(() => notifyListeners());
    }

    try {
      final response =
          await _apiService.get(ApiConfig.orderMessagesUrl(orderId));
      final results = response is List ? response : response['results'] as List;
      final fetched =
          results.map((j) => ChatMessage.fromJson(j)).toList();

      // Only update if messages changed to avoid unnecessary rebuilds
      if (fetched.length != messages.length ||
          (fetched.isNotEmpty &&
              fetched.last.id != messages.last.id)) {
        messages = fetched;
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      if (!silent) notifyListeners();
    } finally {
      if (!silent) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> sendMessage(String orderId, String text) async {
    if (text.trim().isEmpty) return false;
    isSending = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConfig.orderMessagesUrl(orderId),
        {'message': text.trim()},
      );
      final newMsg = ChatMessage.fromJson(response);
      messages = [...messages, newMsg];
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
