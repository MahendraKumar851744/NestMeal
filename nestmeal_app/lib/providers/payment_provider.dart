import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/payment_model.dart';
import '../services/api_service.dart';

class PaymentProvider extends ChangeNotifier {
  List<PaymentModel> payments = [];
  PaymentModel? lastCreatedPayment;
  bool isLoading = false;
  String? error;

  final ApiService _apiService;

  PaymentProvider(this._apiService);

  void _safeNotify() {
    scheduleMicrotask(() => notifyListeners());
  }

  Future<void> createPayment(String orderId, String method) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post(
        '${ApiConfig.paymentsUrl}/',
        {
          'order_id': orderId,
          'method': method,
        },
      );
      lastCreatedPayment = PaymentModel.fromJson(response);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayments() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.get('${ApiConfig.paymentsUrl}/');
      final results = response is List ? response : response['results'] as List;
      payments =
          results.map((json) => PaymentModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
