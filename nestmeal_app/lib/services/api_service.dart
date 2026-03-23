import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;

  ApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class AuthException implements Exception {
  final String message;

  AuthException([this.message = 'Authentication failed. Please log in again.']);

  @override
  String toString() => 'AuthException: $message';
}

class ApiService {
  final AuthService _authService;
  final http.Client _client;

  ApiService({AuthService? authService, http.Client? client})
      : _authService = authService ?? AuthService(),
        _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _authService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String url, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    final headers = await _getHeaders();

    var response = await _client.get(uri, headers: headers);

    if (response.statusCode == 401) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final newHeaders = await _getHeaders();
        response = await _client.get(uri, headers: newHeaders);
      } else {
        throw AuthException();
      }
    }

    return _handleResponse(response);
  }

  Future<dynamic> post(String url, Map<String, dynamic> body,
      {bool requiresAuth = true}) async {
    final uri = Uri.parse(url);
    final headers = await _getHeaders(requiresAuth: requiresAuth);

    var response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 && requiresAuth) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final newHeaders = await _getHeaders();
        response = await _client.post(
          uri,
          headers: newHeaders,
          body: jsonEncode(body),
        );
      } else {
        throw AuthException();
      }
    }

    return _handleResponse(response);
  }

  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    final uri = Uri.parse(url);
    final headers = await _getHeaders();

    var response = await _client.put(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final newHeaders = await _getHeaders();
        response = await _client.put(
          uri,
          headers: newHeaders,
          body: jsonEncode(body),
        );
      } else {
        throw AuthException();
      }
    }

    return _handleResponse(response);
  }

  Future<dynamic> patch(String url, Map<String, dynamic> body) async {
    final uri = Uri.parse(url);
    final headers = await _getHeaders();

    var response = await _client.patch(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final newHeaders = await _getHeaders();
        response = await _client.patch(
          uri,
          headers: newHeaders,
          body: jsonEncode(body),
        );
      } else {
        throw AuthException();
      }
    }

    return _handleResponse(response);
  }

  Future<dynamic> delete(String url) async {
    final uri = Uri.parse(url);
    final headers = await _getHeaders();

    var response = await _client.delete(uri, headers: headers);

    if (response.statusCode == 401) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final newHeaders = await _getHeaders();
        response = await _client.delete(uri, headers: newHeaders);
      } else {
        throw AuthException();
      }
    }

    return _handleResponse(response);
  }

  Future<dynamic> uploadFile(String url, String filePath, {String fieldName = 'image', Map<String, String>? fields}) async {
    final uri = Uri.parse(url);
    final token = await _authService.getAccessToken();

    var request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    if (fields != null) {
      request.fields.addAll(fields);
    }

    var streamedResponse = await _client.send(request);
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final newToken = await _authService.getAccessToken();
        request = http.MultipartRequest('POST', uri);
        if (newToken != null && newToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $newToken';
        }
        request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
        if (fields != null) {
          request.fields.addAll(fields);
        }
        streamedResponse = await _client.send(request);
        response = await http.Response.fromStream(streamedResponse);
      } else {
        throw AuthException();
      }
    }

    return _handleResponse(response);
  }

  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _authService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final uri = Uri.parse('${ApiConfig.accountsUrl}/token/refresh/');
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['access'] as String;
        final newRefresh = data['refresh'] as String? ?? refreshToken;
        await _authService.saveTokens(newAccess, newRefresh);
        return true;
      }

      await _authService.clearTokens();
      return false;
    } catch (_) {
      await _authService.clearTokens();
      return false;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String message;
    dynamic body;
    try {
      body = jsonDecode(response.body);
      if (body is Map) {
        // Check for common DRF error keys first
        if (body.containsKey('detail')) {
          message = body['detail'].toString();
        } else if (body.containsKey('message')) {
          message = body['message'].toString();
        } else if (body.containsKey('error')) {
          message = body['error'].toString();
        } else if (body.containsKey('non_field_errors')) {
          final errors = body['non_field_errors'];
          message = errors is List ? errors.join(', ') : errors.toString();
        } else {
          // DRF field-level validation errors: {"email": ["..."]}
          final fieldErrors = <String>[];
          body.forEach((key, value) {
            if (value is List) {
              fieldErrors.add('$key: ${value.join(', ')}');
            } else {
              fieldErrors.add('$key: $value');
            }
          });
          message = fieldErrors.isNotEmpty
              ? fieldErrors.join('\n')
              : 'Request failed with status ${response.statusCode}';
        }
      } else {
        message = 'Request failed with status ${response.statusCode}';
      }
    } catch (_) {
      message = 'Request failed with status ${response.statusCode}';
      body = response.body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message.toString(),
      body: body,
    );
  }
}
