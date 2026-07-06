import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';

import '../core/apiendpoint.dart';
import '../core/app_navigator.dart';
import '../screens/login_screen.dart';

class AuthResult {
  final bool success;
  final String? token;
  final String? tokenType;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? company;
  final String? error;
  final bool requiresAdminContact;

  AuthResult({
    required this.success,
    this.token,
    this.tokenType,
    this.user,
    this.company,
    this.error,
    this.requiresAdminContact = false,
  });
}

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  static const String _prefUserId = 'user_id';
  static const String _prefToken = 'token';
  static const String _prefTokenType = 'token_type';
  static const String _prefUser = 'user';
  static const String _prefCompany = 'company';
  static const String _prefPolicyAccepted = 'policy_accepted';

  int? currentUserId;
  String? token;
  String? tokenType;
  Map<String, dynamic>? user;
  Map<String, dynamic>? company;
  bool policyAccepted = false;

  bool get isLoggedIn => currentUserId != null && token != null && token!.isNotEmpty;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt(_prefUserId);
    token = prefs.getString(_prefToken);
    tokenType = prefs.getString(_prefTokenType);
    policyAccepted = prefs.getBool(_prefPolicyAccepted) ?? false;

    final userJson = prefs.getString(_prefUser);
    final companyJson = prefs.getString(_prefCompany);
    user = userJson != null ? jsonDecode(userJson) as Map<String, dynamic> : null;
    company = companyJson != null ? jsonDecode(companyJson) as Map<String, dynamic> : null;
  }

  Future<void> setSession({
    required int userId,
    String? token,
    String? tokenType,
    Map<String, dynamic>? user,
    Map<String, dynamic>? company,
  }) async {
    currentUserId = userId;
    this.token = token;
    this.tokenType = tokenType;
    this.user = user;
    this.company = company;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefUserId, userId);
    if (token != null) await prefs.setString(_prefToken, token);
    if (tokenType != null) await prefs.setString(_prefTokenType, tokenType);
    if (user != null) await prefs.setString(_prefUser, jsonEncode(user));
    if (company != null) await prefs.setString(_prefCompany, jsonEncode(company));
  }

  bool _handlingUnauthorized = false;

  Future<void> handleUnauthorized() async {
    if (_handlingUnauthorized || !isLoggedIn) return;
    _handlingUnauthorized = true;
    await clearSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlingUnauthorized = false;
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  Future<void> clearSession() async {
    currentUserId = null;
    token = null;
    tokenType = null;
    user = null;
    company = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUserId);
    await prefs.remove(_prefToken);
    await prefs.remove(_prefTokenType);
    await prefs.remove(_prefUser);
    await prefs.remove(_prefCompany);
  }

  Future<void> setPolicyAccepted(bool accepted) async {
    policyAccepted = accepted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefPolicyAccepted, accepted);
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiEndpoint.login),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return AuthResult(
            success: false, error: 'Invalid email or password.');
      }
      if (response.statusCode == 403) {
        String msg = 'API token is not generated for your account. Please contact your administrator.';
        try {
          final b = jsonDecode(response.body) as Map<String, dynamic>;
          msg = b['message'] as String? ?? msg;
        } catch (_) {}
        return AuthResult(
            success: false, error: msg, requiresAdminContact: true);
      }
      if (response.statusCode != 200) {
        return AuthResult(
            success: false,
            error: 'Server error (${response.statusCode}). Please try again.');
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['success'] == true) {
        final userMap = body['user'] as Map<String, dynamic>?;
        final companyMap = body['company'] as Map<String, dynamic>?;
        final userId = userMap != null ? (userMap['id'] as int?) : null;
        if (userId != null) {
          await setSession(
            userId: userId,
            token: body['token'] as String?,
            tokenType: body['token_type'] as String?,
            user: userMap,
            company: companyMap,
          );
        }
        return AuthResult(
          success: true,
          token: body['token'] as String?,
          tokenType: body['token_type'] as String?,
          user: userMap,
          company: companyMap,
        );
      }

      return AuthResult(
        success: false,
        error: body['message'] as String? ?? 'Invalid email or password.',
      );
    } on TimeoutException {
      return AuthResult(
          success: false,
          error: 'Connection timed out. Please check your internet and try again.');
    } on SocketException {
      return AuthResult(
          success: false,
          error: 'No internet connection. Please check your network and try again.');
    } catch (error) {
      return AuthResult(
          success: false,
          error: 'Login failed. Please try again.');
    }
  }

  Future<AuthResult> deleteAccount(int userId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoint.deleteAccount),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode != 200) {
        return AuthResult(
          success: false,
          error: 'Delete failed: ${response.statusCode}',
        );
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['success'] == true) {
        return AuthResult(success: true);
      }

      return AuthResult(
        success: false,
        error: body['message'] as String? ?? 'Invalid delete response',
      );
    } catch (error) {
      return AuthResult(
        success: false,
        error: 'Unable to delete account. Please try again.',
      );
    }
  }
}
