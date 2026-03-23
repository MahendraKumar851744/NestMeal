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

  Future<void> fetchPickupSlots({
    String? cookId,
    String? date,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final queryParams = <String, String>{};
      if (cookId != null) queryParams['cook_id'] = cookId;
      if (date != null) queryParams['date'] = date;

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

  Future<void> fetchDeliverySlots({
    String? cookId,
    String? date,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final queryParams = <String, String>{};
      if (cookId != null) queryParams['cook_id'] = cookId;
      if (date != null) queryParams['date'] = date;

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
