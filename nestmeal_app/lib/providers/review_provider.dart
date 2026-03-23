import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';

class ReviewProvider extends ChangeNotifier {
  List<ReviewModel> reviews = [];
  bool isLoading = false;
  String? error;

  final ApiService _apiService;

  ReviewProvider(this._apiService);

  void _safeNotify() {
    scheduleMicrotask(() => notifyListeners());
  }

  Future<void> fetchReviews({
    String? cookId,
    String? mealId,
    int? minRating,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final queryParams = <String, String>{};
      if (cookId != null) queryParams['cook_id'] = cookId;
      if (mealId != null) queryParams['meal_id'] = mealId;
      if (minRating != null) queryParams['min_rating'] = minRating.toString();

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = queryString.isNotEmpty
          ? '${ApiConfig.reviewsUrl}/?$queryString'
          : '${ApiConfig.reviewsUrl}/';

      final response = await _apiService.get(url);
      final results = response is List ? response : response['results'] as List;
      reviews =
          results.map((json) => ReviewModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createReview(
    String orderId,
    int rating, {
    int? deliveryRating,
    String? comment,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final body = <String, dynamic>{
        'order_id': orderId,
        'rating': rating,
      };
      if (deliveryRating != null) body['delivery_rating'] = deliveryRating;
      if (comment != null) body['comment'] = comment;

      await _apiService.post('${ApiConfig.reviewsUrl}/', body);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReview(
    String id, {
    int? rating,
    String? comment,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final body = <String, dynamic>{};
      if (rating != null) body['rating'] = rating;
      if (comment != null) body['comment'] = comment;

      await _apiService.patch('${ApiConfig.reviewsUrl}/$id/', body);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> replyToReview(String id, String reply) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      await _apiService.patch(
        '${ApiConfig.reviewsUrl}/$id/reply/',
        {'reply': reply},
      );
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
