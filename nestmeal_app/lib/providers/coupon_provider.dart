import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/coupon_model.dart';
import '../services/api_service.dart';

class CouponProvider extends ChangeNotifier {
  List<CouponModel> coupons = [];
  Map<String, dynamic>? validationResult;
  bool isLoading = false;
  String? error;

  final ApiService _apiService;

  CouponProvider(this._apiService);

  void _safeNotify() {
    scheduleMicrotask(() => notifyListeners());
  }

  Future<void> fetchCoupons() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.get('${ApiConfig.couponsUrl}/');
      final results = response is List ? response : response['results'] as List;
      coupons =
          results.map((json) => CouponModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> validateCoupon(
    String code,
    double orderValue,
    String fulfillmentType,
  ) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post(
        '${ApiConfig.couponsUrl}/validate/',
        {
          'code': code,
          'order_value': orderValue,
          'fulfillment_type': fulfillmentType,
        },
      );
      validationResult = response;
      return response;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
