import 'dart:convert';

import 'package:http/http.dart' as http;

import '../services/auth_service.dart';

/// Central HTTP client for all authenticated API calls.
/// Automatically detects 401/403 and triggers logout + redirect to login.
class ApiClient {
  ApiClient._();

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.instance.token ?? ''}',
      };

  static Future<void> _check(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      await AuthService.instance.handleUnauthorized();
    }
  }

  static Future<http.Response> post(
    Uri uri, {
    required Map<String, dynamic> body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await http
        .post(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);
    await _check(response);
    return response;
  }

  static Future<http.Response> put(
    Uri uri, {
    required Map<String, dynamic> body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final response = await http
        .put(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);
    await _check(response);
    return response;
  }
}
