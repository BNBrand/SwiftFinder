import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/conversation.dart';
import '../services/api_service.dart';

class ItemProvider extends ChangeNotifier {
  ItemProvider(this._api);
  final ApiService _api;

  List<FinderItem> items = [];
  List<ItemCategory> categories = [];
  List<FinderItem> favorites = [];
  bool loading = false;
  bool categoriesLoading = false;
  bool favoritesLoading = false;
  String? error;
  String? categoriesError;
  String? favoritesError;

  Future<void> load({String? type, String? query, int? categoryId, String? location}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final params = <String>[];
      if (type != null) params.add('type=${Uri.encodeQueryComponent(type)}');
      if (query?.trim().isNotEmpty == true) params.add('q=${Uri.encodeQueryComponent(query!.trim())}');
      if (categoryId != null) params.add('category_id=$categoryId');
      if (location?.trim().isNotEmpty == true) params.add('location=${Uri.encodeQueryComponent(location!.trim())}');
      final result = await _api.get('/items${params.isEmpty ? '' : '?${params.join('&')}'}');
      items = _itemList(result['data']);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<FinderItem> getItem(int id) async {
    final result = await _api.get('/items/$id');
    return FinderItem.fromJson(Map<String, dynamic>.from(result['data'] as Map));
  }

  Future<void> loadCategories() async {
    categoriesLoading = true;
    categoriesError = null;
    notifyListeners();
    try {
      final result = await _api.get('/categories');
      final data = result['data'];
      final records = data is List ? data : const [];
      categories = records.whereType<Map>().map((e) => ItemCategory.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      categoriesError = e.toString();
    } finally {
      categoriesLoading = false;
      notifyListeners();
    }
  }

  Future<FinderItem> createItem({
    required String type, required String title, required String description, required String location, required String occurredOn,
    int? categoryId, String? identifyingDetails, String contactPreference = 'in_app', String? occurredAt, List<MultipartUpload> images = const [],
  }) async {
    final result = images.isEmpty ? await _api.post('/items', {
      'type': type, 'title': title, 'description': description, 'location': location, 'occurred_on': occurredOn, 'contact_preference': contactPreference,
      if (occurredAt != null) 'occurred_at': occurredAt, if (categoryId != null) 'category_id': categoryId,
      if (identifyingDetails?.trim().isNotEmpty == true) 'identifying_details': identifyingDetails!.trim(),
    }) : await _api.multipart('/items', fields: {
      'type': type, 'title': title, 'description': description, 'location': location, 'occurred_on': occurredOn, 'contact_preference': contactPreference,
      if (occurredAt != null) 'occurred_at': occurredAt, if (categoryId != null) 'category_id': '$categoryId',
      if (identifyingDetails?.trim().isNotEmpty == true) 'identifying_details': identifyingDetails!.trim(),
    }, files: images);
    final item = FinderItem.fromJson(Map<String, dynamic>.from(result['data'] as Map));
    items = [item, ...items];
    notifyListeners();
    return item;
  }

  Future<bool> toggleFavorite(FinderItem item) async {
    final nextValue = !item.isFavorited;
    _replaceItem(item.copyWith(isFavorited: nextValue));
    try {
      if (nextValue) {
        await _api.post('/items/${item.id}/favorite', {});
      } else {
        await _api.delete('/items/${item.id}/favorite');
      }
      return nextValue;
    } catch (e) {
      _replaceItem(item);
      rethrow;
    }
  }

  Future<List<FinderItem>> loadMatches(int itemId) async {
    final result = await _api.get('/items/$itemId/matches');
    return _itemList(result['data']);
  }

  Future<void> loadFavorites() async {
    favoritesLoading = true;
    favoritesError = null;
    notifyListeners();
    try {
      final result = await _api.get('/favorites');
      favorites = _itemList(result['data']);
    } catch (e) {
      favoritesError = e.toString();
    } finally {
      favoritesLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitClaim({required int itemId, required String message, String? supportingInformation, MultipartUpload? supportingFile}) async {
    if (supportingFile == null) {
      await _api.post('/items/$itemId/claims', {'message': message.trim(), if (supportingInformation?.trim().isNotEmpty == true) 'supporting_information': supportingInformation!.trim()});
    } else {
      await _api.multipart('/items/$itemId/claims', fields: {'message': message.trim(), if (supportingInformation?.trim().isNotEmpty == true) 'supporting_information': supportingInformation!.trim()}, files: [supportingFile]);
    }
  }

  Future<FinderConversation> startConversation(int itemId) async {
    final result = await _api.post('/items/$itemId/conversations', {});
    return FinderConversation.fromJson(Map<String, dynamic>.from(result['data'] as Map));
  }

  Future<FinderItem> updateItem({required int itemId, required String type, required String title, required String description, required String location, required String occurredOn, int? categoryId, String? identifyingDetails, String contactPreference='in_app', String? occurredAt, List<MultipartUpload> images=const []}) async {
    final fields=<String,String>{'_method':'PATCH','type':type,'title':title,'description':description,'location':location,'occurred_on':occurredOn,'contact_preference':contactPreference,if(occurredAt!=null)'occurred_at':occurredAt,if(categoryId!=null)'category_id':'$categoryId',if(identifyingDetails?.trim().isNotEmpty==true)'identifying_details':identifyingDetails!.trim()};
    final result=images.isEmpty?await _api.patch('/items/$itemId',fields):await _api.multipart('/items/$itemId',fields:fields,files:images);
    final item=FinderItem.fromJson(Map<String,dynamic>.from(result['data'] as Map)); _replaceItem(item); return item;
  }

  Future<void> changeStatus(int itemId, String status) async {
    final result = await _api.patch('/items/$itemId/status', {'status': status});
    final item = FinderItem.fromJson(Map<String, dynamic>.from(result['data'] as Map));
    _replaceItem(item);
  }

  Future<void> deleteItem(int itemId) async {
    await _api.delete('/items/$itemId');
    items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void _replaceItem(FinderItem updated) {
    final index = items.indexWhere((element) => element.id == updated.id);
    if (index != -1) items[index] = updated;
    notifyListeners();
  }

  List<FinderItem> _itemList(dynamic payload) {
    final records = payload is List
        ? payload
        : payload is Map && payload['data'] is List
            ? payload['data'] as List
            : const [];
    return records
        .whereType<Map>()
        .map((e) => FinderItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
