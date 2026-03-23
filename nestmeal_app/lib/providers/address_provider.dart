import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/address_model.dart';
import '../services/api_service.dart';

class AddressProvider extends ChangeNotifier {
  List<AddressModel> addresses = [];
  bool isLoading = false;
  String? error;

  final ApiService _apiService;

  AddressProvider(this._apiService);

  void _safeNotify() {
    scheduleMicrotask(() => notifyListeners());
  }

  Future<void> fetchAddresses() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.get('${ApiConfig.accountsUrl}/addresses/');
      final results = response is List ? response : (response['results'] as List);
      addresses = results.map((json) => AddressModel.fromJson(json)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAddress({
    required String label,
    required String street,
    required String city,
    required String state,
    required String zipCode,
    bool isDefault = false,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      'label': label,
      'street': street,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'is_default': isDefault,
    };
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    await _apiService.post('${ApiConfig.accountsUrl}/addresses/', body);
    await fetchAddresses();
  }

  Future<void> updateAddress({
    required String id,
    required String label,
    required String street,
    required String city,
    required String state,
    required String zipCode,
    bool isDefault = false,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      'label': label,
      'street': street,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'is_default': isDefault,
    };
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    await _apiService.patch('${ApiConfig.accountsUrl}/addresses/$id/', body);
    await fetchAddresses();
  }

  Future<void> deleteAddress(String id) async {
    await _apiService.delete('${ApiConfig.accountsUrl}/addresses/$id/');
    addresses.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
