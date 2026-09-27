import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._api);
  final ApiService _api;
  FinderProfile? profile;
  bool loading = false;
  bool saving = false;
  String? error;

  Future<void> load() async {
    loading = true; error = null; notifyListeners();
    try {
      final result = await _api.get('/profile');
      profile = FinderProfile.fromJson(Map<String, dynamic>.from(result['data'] as Map));
    } catch (e) { error = e.toString(); }
    finally { loading = false; notifyListeners(); }
  }

  Future<void> update({required String name, String? phone}) async {
    saving = true; error = null; notifyListeners();
    try {
      final result = await _api.patch('/profile', {'name': name.trim(), 'phone': phone?.trim()});
      profile = FinderProfile.fromJson(Map<String, dynamic>.from(result['data'] as Map));
    } catch (e) { error = e.toString(); rethrow; }
    finally { saving = false; notifyListeners(); }
  }

  Future<void> uploadPhoto(Uint8List bytes, String filename) async {
    saving = true; error = null; notifyListeners();
    try {
      final result = await _api.multipart('/profile/photo', fields: {}, files: [MultipartUpload(field: 'photo', bytes: bytes, filename: filename)]);
      profile = FinderProfile.fromJson(Map<String, dynamic>.from(result['data'] as Map));
    } catch (e) { error = e.toString(); rethrow; }
    finally { saving = false; notifyListeners(); }
  }

  Future<void> changePassword({required String currentPassword, required String password, required String confirmation}) async {
    await _api.patch('/profile/password', {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': confirmation,
    });
  }

  Future<void> deleteAccount(String password) async {
    await _api.deleteWithBody('/profile', {'password': password});
  }

  Future<void> reportUser(int userId, String reason, String details) async {
    await _api.post('/users/$userId/reports', {'reason': reason, if (details.trim().isNotEmpty) 'details': details.trim()});
  }

  Future<void> blockUser(int userId) async => _api.post('/users/$userId/block', {});
  Future<void> reportItem(int itemId, String reason, String details) async => _api.post('/items/$itemId/reports', {'reason': reason, if (details.trim().isNotEmpty) 'details': details.trim()});
}
