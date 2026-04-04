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

  // Stripe payment intent data
  String? _clientSecret;
  String? _paymentIntentId;

  String? get clientSecret => _clientSecret;
  String? get paymentIntentId => _paymentIntentId;

  final ApiService _apiService;

  PaymentProvider(this._apiService);

  void _safeNotify() {
    scheduleMicrotask(() => notifyListeners());
  }

  /// Step 1: Create a PaymentIntent on the backend, returns client_secret.
  Future<Map<String, dynamic>> createPaymentIntent(String orderId) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post(
        '${ApiConfig.paymentsUrl}/',
        {
          'order_id': orderId,
          'method': 'card',
          'gateway': 'stripe',
        },
      );
      _clientSecret = response['client_secret'];
      _paymentIntentId = response['stripe_payment_intent_id'];
      return response;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Step 2: After Stripe payment sheet succeeds, confirm with backend.
  Future<void> confirmPayment(String paymentIntentId) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post(
        '${ApiConfig.paymentsUrl}/confirm/',
        {'payment_intent_id': paymentIntentId},
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

  /// Legacy method kept for backward compatibility.
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

  /// Pay for an order directly from the wallet (no Stripe).
  Future<Map<String, dynamic>> payWithWallet(String orderId) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post(
        '${ApiConfig.paymentsUrl}/wallet-pay/',
        {'order_id': orderId},
      );
      return response;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Top up the customer's wallet balance.
  Future<Map<String, dynamic>> topUpWallet(double amount) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post(
        '${ApiConfig.walletTopUpUrl}/',
        {'amount': amount},
      );
      return response;
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
