import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/constants.dart';

class ApiService {
  String? token;

  Uri _uri(String path) => Uri.parse('${AppConstants.apiBaseUrl}$path');

  void clearToken() => token = null;

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await http.get(_uri(path), headers: _headers);
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Unable to connect to SwiftFinder. Check your internet connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Unable to connect to SwiftFinder. Check your internet connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.patch(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Unable to connect to SwiftFinder. Check your internet connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> multipart(
    String path, {
    required Map<String, String> fields,
    List<MultipartUpload> files = const [],
    String method = 'POST',
  }) async {
    try {
      final request = http.MultipartRequest(method, _uri(path));
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      request.fields.addAll(fields);
      for (final file in files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            file.field,
            file.bytes,
            filename: file.filename,
            contentType: file.mediaType,
          ),
        );
      }
      final response = await http.Response.fromStream(await request.send());
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Unable to upload files to SwiftFinder. Check your internet connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> deleteWithBody(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.delete(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Unable to connect to SwiftFinder. Check your internet connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await http.delete(_uri(path), headers: _headers);
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Unable to connect to SwiftFinder. Check your internet connection and try again.',
      );
    }
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);
      data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      throw ApiException(
        response.statusCode >= 500
            ? 'The server encountered a problem. Please try again.'
            : 'The server returned an invalid response.',
      );
    }

    if (response.statusCode >= 400 || data['success'] == false) {
      throw ApiException(
        data['message']?.toString() ?? 'Something went wrong.',
        statusCode: response.statusCode,
        errors: data['errors'] is Map
            ? Map<String, dynamic>.from(data['errors'] as Map)
            : null,
      );
    }

    return data;
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException(this.message, {this.statusCode, this.errors});

  String get userMessage {
    if (errors != null && errors!.isNotEmpty) {
      final first = errors!.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
    return message;
  }

  @override
  String toString() => message;
}

class MultipartUpload {
  final String field;
  final Uint8List bytes;
  final String filename;
  final http.MediaType? mediaType;

  const MultipartUpload({
    required this.field,
    required this.bytes,
    required this.filename,
    this.mediaType,
  });
}
