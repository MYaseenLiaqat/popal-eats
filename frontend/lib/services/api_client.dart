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
  }) async {
    return http
        .get(_uri(path, query), headers: _headers(auth: auth))
        .timeout(ApiConfig.timeout);
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
    final msg = err['error'] ?? err['detail'] ?? r.body;
    throw ApiException(r.statusCode, msg.toString());
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
