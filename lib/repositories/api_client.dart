import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Object? data;

  const ApiException(this.statusCode, this.message, [this.data]);

  @override
  String toString() => message;
}

class ApiClient {
  static const _tokenKey = 'schedule_access_token';
  static const _storeKey = 'schedule_active_store_id';

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String baseUrl;

  String? _token;
  String? _storeId;

  ApiClient({
    http.Client? client,
    FlutterSecureStorage? storage,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage(),
        baseUrl = (baseUrl ?? dotenv.env['API_BASE_URL'] ?? '').replaceAll(
          RegExp(r'/$'),
          '',
        );

  bool get hasSession => _token != null && _token!.isNotEmpty;
  String? get activeStoreId => _storeId;

  Future<void> restoreSession() async {
    _token = await _storage.read(key: _tokenKey);
    _storeId = await _storage.read(key: _storeKey);
  }

  Future<void> saveSession({required String token, String? storeId}) async {
    _token = token;
    _storeId = storeId;
    await _storage.write(key: _tokenKey, value: token);
    if (storeId == null || storeId.isEmpty) {
      await _storage.delete(key: _storeKey);
    } else {
      await _storage.write(key: _storeKey, value: storeId);
    }
  }

  Future<void> selectStore(String storeId, {String? token}) async {
    await saveSession(token: token ?? _token!, storeId: storeId);
  }

  Future<void> clearSession() async {
    _token = null;
    _storeId = null;
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _storeKey),
    ]);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    if (baseUrl.isEmpty) {
      throw const ApiException(0, 'API_BASE_URL is not configured');
    }
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    if (_storeId != null && _storeId!.isNotEmpty) {
      headers['X-Store-ID'] = _storeId!;
    }

    late http.Response response;
    try {
      switch (method) {
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? <String, dynamic>{}),
          );
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: headers,
            body: jsonEncode(body ?? <String, dynamic>{}),
          );
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
          break;
        default:
          response = await _client.get(uri, headers: headers);
      }
    } on Exception catch (error) {
      throw ApiException(0, 'Could not connect to the service', error);
    }

    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(response.statusCode, 'Invalid service response');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        (envelope['message'] ?? 'Request failed').toString(),
        envelope['data'],
      );
    }
    return envelope['data'];
  }
}
