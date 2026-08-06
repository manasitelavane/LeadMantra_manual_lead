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
        'X-User-Id': '${AuthService.instance.currentUserId ?? ''}',
      };

  static void _log(String method, Uri uri, Map<String, dynamic> body, http.Response response) {
    // ignore: avoid_print
    print('── API $method ${uri.path}');
    // ignore: avoid_print
    print('   body    : ${jsonEncode(body)}');
    // ignore: avoid_print
    print('   status  : ${response.statusCode}');
    // ignore: avoid_print
    print('   response: ${response.body}');
  }

  static const _logoutCodes = {
    'account_deleted',
    'company_deleted',
    'session_invalid',
    'user_identity_required',
  };

  static Future<void> _check(http.Response response) async {
    if (response.statusCode == 401) {
      await AuthService.instance.handleUnauthorized();
      return;
    }
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final code = body['code'] as String?;
      if (code != null && _logoutCodes.contains(code)) {
        await AuthService.instance.handleUnauthorized();
      }
    } catch (_) {}
  }

  static Future<http.Response> post(
    Uri uri, {
    required Map<String, dynamic> body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await http
        .post(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);
    _log('POST', uri, body, response);
    await _check(response);
    return response;
  }

  static Future<http.Response> get(
    Uri uri, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await http
        .get(uri, headers: _headers())
        .timeout(timeout);
    _log('GET', uri, {}, response);
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
    _log('PUT', uri, body, response);
    await _check(response);
    return response;
  }
}
