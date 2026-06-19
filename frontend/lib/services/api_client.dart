import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Central HTTP client with JWT interceptor-style auth headers.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'access_token';

  String? _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('refresh_token');
  }

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  String? get accessToken => _token;

  Map<String, String> _headers({bool auth = true, bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (auth && _token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
    Duration? timeout,
  }) async {
    return http
        .get(_uri(path, query), headers: _headers(auth: auth))
        .timeout(timeout ?? ApiConfig.timeout);
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    return http
        .post(
          _uri(path),
          headers: _headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(ApiConfig.timeout);
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    return http
        .put(
          _uri(path),
          headers: _headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(ApiConfig.timeout);
  }

  Future<http.Response> patch(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    return http
        .patch(
          _uri(path),
          headers: _headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(ApiConfig.timeout);
  }

  Future<http.Response> delete(String path, {bool auth = true}) async {
    return http
        .delete(_uri(path), headers: _headers(auth: auth))
        .timeout(ApiConfig.timeout);
  }

  Map<String, dynamic> decodeJson(http.Response r) {
    if (r.body.isEmpty) return {};
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  List<dynamic> decodeList(http.Response r) {
    final data = jsonDecode(r.body);
    if (data is Map && data['items'] is List) return data['items'] as List;
    if (data is List) return data;
    return [];
  }

  void throwIfError(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    Map<String, dynamic> err = {};
    try {
      err = decodeJson(r);
    } catch (_) {}
    final msg = _formatErrorMessage(err, r.body);
    throw ApiException(r.statusCode, msg);
  }

  String _formatErrorMessage(Map<String, dynamic> err, String fallback) {
    final details = err['details'];
    if (details is List && details.isNotEmpty) {
      final messages = details
          .whereType<Map>()
          .map((item) {
            final field = (item['loc'] is List && (item['loc'] as List).length > 1)
                ? (item['loc'] as List).last.toString()
                : 'field';
            final msg = item['msg']?.toString() ?? 'Invalid value';
            return '${field == 'body' ? 'input' : field}: $msg';
          })
          .where((m) => m.isNotEmpty)
          .toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }

    final error = err['error'] ?? err['detail'];
    if (error != null) return error.toString();
    return fallback;
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
