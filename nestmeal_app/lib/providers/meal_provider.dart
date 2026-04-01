import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/meal_model.dart';
import '../models/meal_detail.dart';
import '../services/api_service.dart';

class MealProvider extends ChangeNotifier {
  List<MealModel> meals = [];
  MealDetail? selectedMeal;
  bool isLoading = false;
  String? error;
  List<MealModel> featuredMeals = [];

  final ApiService _apiService;

  MealProvider(this._apiService);

  void _safeNotify() {
    scheduleMicrotask(() => notifyListeners());
  }

  Future<void> fetchMeals({
    String? category,
    String? mealType,
    String? cuisineType,
    String? spiceLevel,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? search,
    String? ordering,
    String? fulfillmentModes,
    String? availableDays,
    String? cook,
    int? page,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (mealType != null) queryParams['meal_type'] = mealType;
      if (cuisineType != null) queryParams['cuisine_type'] = cuisineType;
      if (spiceLevel != null) queryParams['spice_level'] = spiceLevel;
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (minRating != null) queryParams['min_rating'] = minRating.toString();
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (fulfillmentModes != null) {
        queryParams['fulfillment_modes'] = fulfillmentModes;
      }
      if (availableDays != null) {
        queryParams['available_days'] = availableDays;
      }
      if (cook != null) queryParams['cook'] = cook;
      if (page != null) queryParams['page'] = page.toString();

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = queryString.isNotEmpty
          ? '${ApiConfig.mealsUrl}/?$queryString'
          : '${ApiConfig.mealsUrl}/';

      final response = await _apiService.get(url);
      final results = response is List ? response : response['results'] as List;
      meals = results.map((json) => MealModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMealDetail(String id) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.get('${ApiConfig.mealsUrl}/$id/');
      selectedMeal = MealDetail.fromJson(response);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFeaturedMeals() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response =
          await _apiService.get('${ApiConfig.mealsUrl}/featured/');
      final results = response is List ? response : response['results'] as List;
      featuredMeals =
          results.map((json) => MealModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableNow() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response =
          await _apiService.get('${ApiConfig.mealsUrl}/available-now/');
      final results = response is List ? response : response['results'] as List;
      meals = results.map((json) => MealModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createMeal(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post('${ApiConfig.mealsUrl}/', data);
      return response as Map<String, dynamic>;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadMealImage(String mealId, String filePath) async {
    try {
      await _apiService.uploadFile(
        '${ApiConfig.mealsUrl}/$mealId/images/',
        filePath,
        fieldName: 'image',
      );
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> updateMeal(String id, Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      await _apiService.patch('${ApiConfig.mealsUrl}/$id/', data);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch meals by a specific cook (does not overwrite [meals]).
  Future<List<MealModel>> fetchMealsByCook(String cookId) async {
    try {
      final response =
          await _apiService.get('${ApiConfig.mealsUrl}/?cook=$cookId');
      final results = response is List ? response : response['results'] as List;
      return results.map((json) => MealModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  // Add this inside MealProvider (meal_provider.dart)
  Future<void> createMealExtra(String mealId, Map<String, dynamic> data) async {
    try {
      await _apiService.post('${ApiConfig.mealsUrl}/$mealId/extras/', data);
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }
  
  Future<void> deleteMeal(String id) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      await _apiService.delete('${ApiConfig.mealsUrl}/$id/');
      meals.removeWhere((meal) => meal.id == id);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
