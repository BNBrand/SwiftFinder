import 'package:flutter/foundation.dart';
import '../models/claim.dart';
import '../models/conversation.dart';
import '../models/item.dart';
import '../services/api_service.dart';

class ActivityProvider extends ChangeNotifier {
  ActivityProvider(this._api);
  final ApiService _api;

  List<FinderItem> myItems = [];
  List<FinderClaim> myClaims = [];
  List<FinderConversation> conversations = [];
  bool loading = false;
  String? error;

  Future<void> loadAll() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await Future.wait([loadMyItems(notify: false), loadMyClaims(notify: false), loadConversations(notify: false)]);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyItems({bool notify = true}) async {
    try {
      final result = await _api.get('/my-items');
      myItems = _itemList(result['data']);
    } catch (e) {
      error = e.toString();
      if (notify) notifyListeners();
      rethrow;
    }
    if (notify) notifyListeners();
  }

  Future<void> loadMyClaims({bool notify = true}) async {
    try {
      final result = await _api.get('/my-claims');
      myClaims = _claimList(result['data']);
    } catch (e) {
      error = e.toString();
      if (notify) notifyListeners();
      rethrow;
    }
    if (notify) notifyListeners();
  }

  Future<void> loadConversations({bool notify = true}) async {
    try {
      final result = await _api.get('/conversations');
      conversations = _conversationList(result['data']);
    } catch (e) {
      error = e.toString();
      if (notify) notifyListeners();
      rethrow;
    }
    if (notify) notifyListeners();
  }

  Future<List<FinderClaim>> loadClaimsForItem(int itemId) async {
    final result = await _api.get('/items/$itemId/claims');
    return _claimList(result['data']);
  }

  Future<FinderClaim> reviewClaim(int claimId, String status) async {
    final result = await _api.patch('/claims/$claimId', {'status': status});
    final claim = FinderClaim.fromJson(Map<String, dynamic>.from(result['data'] as Map));
    final index = myClaims.indexWhere((c) => c.id == claim.id);
    if (index != -1) myClaims[index] = claim;
    notifyListeners();
    return claim;
  }

  Future<List<FinderMessage>> loadMessages(int conversationId) async {
    final result = await _api.get('/conversations/$conversationId/messages');
    return _messageList(result['data']);
  }

  Future<FinderMessage> sendMessage(int conversationId, String body) async {
    final result = await _api.post('/conversations/$conversationId/messages', {'body': body.trim()});
    final message = FinderMessage.fromJson(Map<String, dynamic>.from(result['data'] as Map));
    await loadConversations();
    return message;
  }

  Future<void> deleteMessage(int conversationId, int messageId) async {
    await _api.delete('/conversations/$conversationId/messages/$messageId');
  }

  List<FinderItem> _itemList(dynamic payload) {
    final records = payload is List ? payload : payload is Map && payload['data'] is List ? payload['data'] as List : const [];
    return records.whereType<Map>().map((e) => FinderItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  List<FinderClaim> _claimList(dynamic payload) {
    final records = payload is List ? payload : payload is Map && payload['data'] is List ? payload['data'] as List : const [];
    return records.whereType<Map>().map((e) => FinderClaim.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  List<FinderConversation> _conversationList(dynamic payload) {
    final records = payload is List ? payload : payload is Map && payload['data'] is List ? payload['data'] as List : const [];
    return records.whereType<Map>().map((e) => FinderConversation.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  List<FinderMessage> _messageList(dynamic payload) {
    final records = payload is List ? payload : const [];
    return records.whereType<Map>().map((e) => FinderMessage.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
