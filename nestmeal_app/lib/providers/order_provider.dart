import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/order_model.dart';
import '../models/order_list_item.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderListItem> orders = [];
  OrderModel? selectedOrder;
  bool isLoading = false;
  String? error;
  Map<String, dynamic>? cookStats;

  final ApiService _apiService;

  OrderProvider(this._apiService);

  void _safeNotify() {
    scheduleMicrotask(() => notifyListeners());
  }

  Future<void> fetchOrders({
    String? status,
    String? fulfillmentType,
    String? dateFrom,
    String? dateTo,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (fulfillmentType != null) {
        queryParams['fulfillment_type'] = fulfillmentType;
      }
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = queryString.isNotEmpty
          ? '${ApiConfig.ordersUrl}/?$queryString'
          : '${ApiConfig.ordersUrl}/';

      final response = await _apiService.get(url);
      final results = response is List ? response : (response['results'] as List);
      orders =
          results.map((json) => OrderListItem.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrderDetail(String id) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.get('${ApiConfig.ordersUrl}/$id/');
      selectedOrder = OrderModel.fromJson(response);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createOrder(
    String cookId,
    String fulfillmentType,
    List<Map<String, dynamic>> items,
    String? slotId, {
    String? deliveryAddressStreet,
    String? deliveryAddressCity,
    String? deliveryAddressState,
    String? deliveryAddressZip,
    double? deliveryAddressLat,
    double? deliveryAddressLng,
    String? couponCode,
    String? specialInstructions,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final body = <String, dynamic>{
        'cook_id': cookId,
        'fulfillment_type': fulfillmentType,
        'items': items.map((item) {
          return {
            'meal_id': item['mealId'],
            'quantity': item['quantity'],
          };
        }).toList(),
      };

      // Send correct slot field based on fulfillment type
      if (slotId != null) {
        if (fulfillmentType == 'pickup') {
          body['pickup_slot_id'] = slotId;
        } else {
          body['delivery_slot_id'] = slotId;
        }
      }

      // Delivery address fields
      if (deliveryAddressStreet != null) {
        body['delivery_address_street'] = deliveryAddressStreet;
      }
      if (deliveryAddressCity != null) {
        body['delivery_address_city'] = deliveryAddressCity;
      }
      if (deliveryAddressState != null) {
        body['delivery_address_state'] = deliveryAddressState;
      }
      if (deliveryAddressZip != null) {
        body['delivery_address_zip'] = deliveryAddressZip;
      }
      if (deliveryAddressLat != null) {
        body['delivery_address_lat'] = deliveryAddressLat;
      }
      if (deliveryAddressLng != null) {
        body['delivery_address_lng'] = deliveryAddressLng;
      }

      if (couponCode != null) body['coupon_code'] = couponCode;
      if (specialInstructions != null) {
        body['special_instructions'] = specialInstructions;
      }

      final response = await _apiService.post(
        '${ApiConfig.ordersUrl}/',
        body,
      );
      selectedOrder = OrderModel.fromJson(response);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String id, String status) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post(
        '${ApiConfig.ordersUrl}/$id/update-status/',
        {'status': status},
      );
      selectedOrder = OrderModel.fromJson(response);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String id, String reason) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post(
        '${ApiConfig.ordersUrl}/$id/cancel/',
        {'reason': reason},
      );
      selectedOrder = OrderModel.fromJson(response);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyPickup(String id, String pickupCode) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post(
        '${ApiConfig.ordersUrl}/$id/verify-pickup/',
        {'pickup_code': pickupCode},
      );
      selectedOrder = OrderModel.fromJson(response);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCookStats() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response =
          await _apiService.get('${ApiConfig.ordersUrl}/stats/');
      cookStats = response;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
