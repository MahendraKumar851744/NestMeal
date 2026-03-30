import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? currentUser;
  bool isLoading = false;
  String? error;

  final AuthService _authService;
  final ApiService _apiService;

  AuthProvider(this._authService, this._apiService);

  void _safeNotify() {
    scheduleMicrotask(() => notifyListeners());
  }

  bool get isLoggedIn => currentUser != null;

  bool get isCustomer => currentUser?.role == 'customer';

  bool get isCook => currentUser?.role == 'cook';

  bool get isAdmin => currentUser?.role == 'admin';

  Future<void> register(
    String email,
    String fullName,
    String phone,
    String role,
    String password,
    String passwordConfirm, {
    String? businessName,
    String? kitchenStreet,
    String? kitchenCity,
    String? kitchenState,
    String? kitchenZip,
    double? kitchenLatitude,
    double? kitchenLongitude,
  }) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final body = {
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': role,
        'password': password,
        'password_confirm': passwordConfirm,
      };

      if (role == 'cook') {
        if (businessName != null) body['display_name'] = businessName;
        if (kitchenStreet != null) body['kitchen_street'] = kitchenStreet;
        if (kitchenCity != null) body['kitchen_city'] = kitchenCity;
        if (kitchenState != null) body['kitchen_state'] = kitchenState;
        if (kitchenZip != null) body['kitchen_zip'] = kitchenZip;
        if (kitchenLatitude != null) body['kitchen_latitude'] = kitchenLatitude.toString();
        if (kitchenLongitude != null) body['kitchen_longitude'] = kitchenLongitude.toString();
      }

      final response = await _apiService.post(
        '${ApiConfig.accountsUrl}/register/',
        body,
        requiresAuth: false,
      );

      await _authService.saveTokens(
        response['tokens']['access'],
        response['tokens']['refresh'],
      );

      developer.log('Register response: $response', name: 'AuthProvider');
      currentUser = UserModel.fromJson(response['user']);
    } catch (e, stackTrace) {
      developer.log('Register error: $e', name: 'AuthProvider', error: e, stackTrace: stackTrace);
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post(
        '${ApiConfig.accountsUrl}/login/',
        {'email': email, 'password': password},
        requiresAuth: false,
      );

      developer.log('Login response: $response', name: 'AuthProvider');
      await _authService.saveTokens(
        response['tokens']['access'],
        response['tokens']['refresh'],
      );

      currentUser = UserModel.fromJson(response['user']);
    } catch (e, stackTrace) {
      developer.log('Login error: $e', name: 'AuthProvider', error: e, stackTrace: stackTrace);
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      await _authService.clearTokens();
      currentUser = null;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.get('${ApiConfig.accountsUrl}/me/');
      currentUser = UserModel.fromJson(response);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(
    String fullName,
    String phone,
    String? profilePictureUrl,
  ) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final body = <String, dynamic>{
        'full_name': fullName,
        'phone': phone,
      };
      if (profilePictureUrl != null) {
        body['profile_picture_url'] = profilePictureUrl;
      }

      final response = await _apiService.put(
        '${ApiConfig.accountsUrl}/me/',
        body,
      );
      currentUser = UserModel.fromJson(response);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCookProfile(
    String cookProfileId,
    Map<String, dynamic> data,
  ) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      await _apiService.patch(
        '${ApiConfig.accountsUrl}/cook-profiles/$cookProfileId/',
        data,
      );
      // Refresh user to get updated cook profile
      await fetchProfile();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Pickup Location CRUD
  Future<void> addPickupLocation(Map<String, dynamic> data) async {
    try {
      await _apiService.post('${ApiConfig.pickupLocationsUrl}/', data);
      await fetchProfile();
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> deletePickupLocation(String locationId) async {
    try {
      await _apiService.delete('${ApiConfig.pickupLocationsUrl}/$locationId/');
      await fetchProfile();
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> changePassword(
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      await _apiService.post(
        '${ApiConfig.accountsUrl}/me/change-password/',
        {
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── OTP methods ──────────────────────────────────────────────────

  Future<void> sendOTP(String phone) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      await _apiService.post(
        '${ApiConfig.accountsUrl}/otp/send/',
        {'phone': phone},
        requiresAuth: false,
      );
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOTP(String phone, String otp) async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final response = await _apiService.post(
        '${ApiConfig.accountsUrl}/otp/verify/',
        {'phone': phone, 'otp': otp},
        requiresAuth: false,
      );
      final verified = response['verified'] == true;
      if (verified && currentUser != null) {
        // Refresh user to get updated is_verified flag
        await fetchProfile();
      }
      return verified;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendOTP(String phone) async {
    await sendOTP(phone);
  }

  Future<void> tryAutoLogin() async {
    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      await fetchProfile();
    } on AuthException {
      await _authService.clearTokens();
      currentUser = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
