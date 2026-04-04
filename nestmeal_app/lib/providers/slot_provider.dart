import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/pickup_slot_model.dart';
import '../models/delivery_slot_model.dart';
import '../services/api_service.dart';

class SlotProvider extends ChangeNotifier {
  List<PickupSlotModel> pickupSlots = [];
  List<DeliverySlotModel> deliverySlots = [];
  Map<String, dynamic>? deliveryFeeResult;
  bool isLoading = false;
  String? error;

  final ApiService _apiService;

  SlotProvider(this._apiService);

  void _safeNotify() {
    scheduleMicrotask(() => notifyListeners());
  }

  /// For customers: only shows available/open slots.
  Future<void> fetchPickupSlots({
    String? cookId,
    String? date,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final queryParams = <String, String>{};
      if (cookId != null) queryParams['cook'] = cookId;
      if (date != null) queryParams['date'] = date;
      queryParams['is_available'] = 'true';

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = queryString.isNotEmpty
          ? '${ApiConfig.pickupSlotsUrl}/?$queryString'
          : '${ApiConfig.pickupSlotsUrl}/';

      final response = await _apiService.get(url);
      final results = response is List ? response : response['results'] as List;
      pickupSlots =
          results.map((json) => PickupSlotModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// For the cook's management screen: shows ALL their slots (no availability filter).
  Future<void> fetchCookOwnPickupSlots(String cookId) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final url = '${ApiConfig.pickupSlotsUrl}/?cook=$cookId';
      final response = await _apiService.get(url);
      final results = response is List ? response : response['results'] as List;
      pickupSlots =
          results.map((json) => PickupSlotModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// For the cook's management screen: shows ALL their delivery slots.
  Future<void> fetchCookOwnDeliverySlots(String cookId) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final url = '${ApiConfig.deliverySlotsUrl}/?cook=$cookId';
      final response = await _apiService.get(url);
      final results = response is List ? response : response['results'] as List;
      deliverySlots =
          results.map((json) => DeliverySlotModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSlot({
    required String slotType,
    required String slotId,
  }) async {
    try {
      final url = slotType == 'pickup'
          ? '${ApiConfig.pickupSlotsUrl}/$slotId/'
          : '${ApiConfig.deliverySlotsUrl}/$slotId/';
      await _apiService.delete(url);
      if (slotType == 'pickup') {
        pickupSlots.removeWhere((s) => s.id == slotId);
      } else {
        deliverySlots.removeWhere((s) => s.id == slotId);
      }
      notifyListeners();
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  /// For customers: only shows available delivery slots.
  Future<void> fetchDeliverySlots({
    String? cookId,
    String? date,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final queryParams = <String, String>{};
      if (cookId != null) queryParams['cook'] = cookId;
      if (date != null) queryParams['date'] = date;
      queryParams['is_available'] = 'true';

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = queryString.isNotEmpty
          ? '${ApiConfig.deliverySlotsUrl}/?$queryString'
          : '${ApiConfig.deliverySlotsUrl}/';

      final response = await _apiService.get(url);
      final results = response is List ? response : response['results'] as List;
      deliverySlots =
          results.map((json) => DeliverySlotModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createSlot({
    required String slotType,
    required String cookId,
    required String date,
    required String startTime,
    required String endTime,
    required int maxOrders,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final url = slotType == 'pickup'
          ? '${ApiConfig.pickupSlotsUrl}/'
          : '${ApiConfig.deliverySlotsUrl}/';

      await _apiService.post(url, {
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'max_orders': maxOrders,
      });
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> calculateDeliveryFee(
    String cookId,
    double customerLat,
    double customerLng,
  ) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post(
        '${ApiConfig.deliveryFeeUrl}/',
        {
          'cook_id': cookId,
          'customer_lat': customerLat,
          'customer_lng': customerLng,
        },
      );
      deliveryFeeResult = response;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
