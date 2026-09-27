import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.api) {
    restoreSession();
  }

  final ApiService api;

  FinderUser? user;
  bool initializing = true;
  bool loading = false;

  bool get isSignedIn => api.token != null && api.token!.isNotEmpty;

  Future<void> restoreSession() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString(AppConstants.authTokenKey);
      final userJson = preferences.getString(AppConstants.authUserKey);

      if (token != null && token.isNotEmpty) {
        api.token = token;
        if (userJson != null) {
          user = FinderUser.fromJson(Map<String, dynamic>.from(jsonDecode(userJson) as Map));
        }

        try {
          final result = await api.get('/auth/me');
          if (result['data'] is Map) {
            user = FinderUser.fromJson(Map<String, dynamic>.from(result['data'] as Map));
            await _persistSession();
          }
        } on ApiException catch (error) {
          if (error.statusCode == 401) {
            await _clearSession();
          }
        }
      }
    } catch (_) {
      await _clearSession();
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      final result = await api.post('/auth/login', {
        'email': email,
        'password': password,
      });
      await _setSession(result);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      final result = await api.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });
      await _setSession(result);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> forgotPassword(String email) async {
    await api.post('/auth/forgot-password', {'email': email.trim()});
  }

  Future<void> resetPassword({required String email, required String token, required String password, required String confirmation}) async {
    await api.post('/auth/reset-password', {
      'email': email.trim(), 'token': token.trim(), 'password': password, 'password_confirmation': confirmation,
    });
  }

  Future<void> logout() async {
    loading = true;
    notifyListeners();
    try {
      if (isSignedIn) {
        try {
          await api.post('/auth/logout', {});
        } on ApiException {
          // A local logout should still succeed if the remote token is expired.
        }
      }
    } finally {
      await _clearSession();
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _setSession(Map<String, dynamic> result) async {
    final data = Map<String, dynamic>.from(result['data'] as Map);
    api.token = data['token'] as String;
    user = FinderUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    await _persistSession();
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final preferences = await SharedPreferences.getInstance();
    final token = api.token;
    if (token == null || token.isEmpty || user == null) return;

    await preferences.setString(AppConstants.authTokenKey, token);
    await preferences.setString(AppConstants.authUserKey, jsonEncode(user!.toJson()));
  }

  Future<void> _clearSession() async {
    api.token = null;
    user = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(AppConstants.authTokenKey);
    await preferences.remove(AppConstants.authUserKey);
  }
}
