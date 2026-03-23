import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/meal_model.dart';
import '../services/api_service.dart';

class CookProvider extends ChangeNotifier {
  List<CookCard> cooks = [];
  CookCard? selectedCook;
  bool isLoading = false;
  String? error;

  final ApiService _apiService;

  CookProvider(this._apiService);

  void _safeNotify() {
    scheduleMicrotask(() => notifyListeners());
  }

  Future<void> fetchCooks({
    String? search,
    String? kitchenCity,
    String? ordering,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (kitchenCity != null && kitchenCity.isNotEmpty) {
        queryParams['kitchen_city'] = kitchenCity;
      }
      if (ordering != null && ordering.isNotEmpty) {
        queryParams['ordering'] = ordering;
      }

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = queryString.isNotEmpty
          ? '${ApiConfig.cooksPublicUrl}/?$queryString'
          : '${ApiConfig.cooksPublicUrl}/';

      final response = await _apiService.get(url);
      final results =
          response is List ? response : response['results'] as List;
      cooks = results.map((json) => CookCard.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCookDetail(String cookId) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response =
          await _apiService.get('${ApiConfig.cooksPublicUrl}/$cookId/');
      selectedCook = CookCard.fromJson(response);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
