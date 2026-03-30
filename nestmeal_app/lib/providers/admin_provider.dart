import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart'; // Assuming you have a base URL config
import '../models/cook_profile.dart'; // Import your model

class AdminProvider extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  String? _error;
  List<PendingCook> _pendingCooks = [];

  AdminProvider(this._apiService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PendingCook> get pendingCooks => _pendingCooks;

  Future<void> fetchPendingCooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Adjust the URL if your Django router has an /api/ prefix
      final response = await _apiService.get('${ApiConfig.baseUrl}/accounts/cook-profiles/pending/');

      if (response is List) {
        _pendingCooks = response.map((data) => PendingCook.fromJson(data)).toList();
      } else if (response is Map && response.containsKey('results')) {
        // Handle DRF pagination if enabled
        final results = response['results'] as List;
        _pendingCooks = results.map((data) => PendingCook.fromJson(data)).toList();
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load pending cooks: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveCook(String cookId) async {
    try {
      await _apiService.post('${ApiConfig.baseUrl}/accounts/cook-profiles/$cookId/approve/', {});
      
      // Remove the cook from the local list instantly for snappy UI
      _pendingCooks.removeWhere((cook) => cook.id == cookId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to approve cook';
      notifyListeners();
      return false;
    }
  }
}