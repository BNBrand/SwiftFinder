import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._api);
  final ApiService _api;
  List<FinderNotification> notifications = [];
  bool loading = false;
  String? error;
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    loading = true; error = null; notifyListeners();
    try {
      final result = await _api.get('/notifications');
      final data = result['data'];
      final records = data is List ? data : data is Map && data['data'] is List ? data['data'] as List : const [];
      notifications = records.whereType<Map>().map((e) => FinderNotification.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) { error = e.toString(); }
    finally { loading = false; notifyListeners(); }
  }

  Future<void> markRead(String id) async {
    await _api.patch('/notifications/$id/read', {});
    final i = notifications.indexWhere((n) => n.id == id);
    if (i >= 0) {
      final old = notifications[i];
      notifications[i] = FinderNotification(id: old.id, type: old.type, title: old.title, message: old.message, data: old.data, createdAt: old.createdAt, readAt: DateTime.now());
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _api.patch('/notifications/read-all', {});
    final now = DateTime.now();
    notifications = notifications.map((n) => n.isRead ? n : FinderNotification(id:n.id,type:n.type,title:n.title,message:n.message,data:n.data,createdAt:n.createdAt,readAt:now)).toList();
    notifyListeners();
  }
}
