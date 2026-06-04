import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:popal_eats_mobile/models/recommendation.dart';

/// Thrown when the Popal Eats API returns an error or invalid payload.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const ApiException(this.message, {this.statusCode, this.cause});

  @override
  String toString() {
    final buffer = StringBuffer();
    if (statusCode != null) {
      buffer.write('ApiException ($statusCode): ');
    } else {
      buffer.write('ApiException: ');
    }
    buffer.write(message);
    if (cause != null) {
      buffer.write('\nCause: $cause');
    }
    return buffer.toString();
  }
}

/// HTTP client for Popal Eats backend APIs.
class ApiService {
  /// Use localhost for Flutter web (same-site friendly); 127.0.0.1 for mobile/desktop.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static const Duration _timeout = Duration(seconds: 30);

  String? _accessToken;

  Map<String, String> get _authHeaders => {
        'Accept': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  void _log(String message) {
    debugPrint('[PopalEats API] $message');
  }

  /// POST /login — stores JWT for subsequent recommendation requests.
  Future<void> login({required String email, required String password}) async {
    final uri = Uri.parse('$baseUrl/login');
    _log('POST $uri');

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);
    } catch (e, st) {
      _log('Login network error: $e\n$st');
      throw _wrapNetworkError('login', e);
    }

    _log('Login status: ${response.statusCode}');
    _log('Login body: ${_truncate(response.body)}');

    if (response.statusCode != 200) {
      throw ApiException(
        _errorMessage(response, fallback: 'Login failed'),
        statusCode: response.statusCode,
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['access_token'];
      if (token is! String || token.isEmpty) {
        throw const FormatException('access_token missing or empty');
      }
      _accessToken = token;
      _log('Login OK — token stored (${token.length} chars)');
    } catch (e, st) {
      _log('Login parse error: $e\n$st');
      throw ApiException('Failed to parse login response: $e', cause: e);
    }
  }

  /// POST /register — dev helper when test user does not exist.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/register');
    _log('POST $uri (register)');

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'full_name': fullName,
              'email': email,
              'password': password,
            }),
          )
          .timeout(_timeout);
    } catch (e, st) {
      _log('Register network error: $e\n$st');
      throw _wrapNetworkError('register', e);
    }

    _log('Register status: ${response.statusCode}');
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException(
        _errorMessage(response, fallback: 'Registration failed'),
        statusCode: response.statusCode,
      );
    }
  }

  /// Ensures a JWT is available (register + login for dev account if needed).
  Future<void> ensureAuthenticated({
    String email = 'metrics3@example.com',
    String password = 'Test1234!',
    String fullName = 'Mobile Dev User',
  }) async {
    try {
      await login(email: email, password: password);
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 401 && e.statusCode != 404) rethrow;
      _log('Login failed (${e.statusCode}), attempting register…');
    }

    try {
      await register(fullName: fullName, email: email, password: password);
    } on ApiException catch (e) {
      if (e.statusCode != 400) rethrow;
      _log('Register returned 400 (user may already exist), retrying login…');
    }

    await login(email: email, password: password);
  }

  /// GET /recommendations/v2?strategy=hybrid
  Future<List<Recommendation>> getRecommendations() async {
    if (_accessToken == null) {
      throw const ApiException(
        'Not authenticated. Call login() or ensureAuthenticated() first.',
      );
    }

    final uri = Uri.parse('$baseUrl/recommendations/v2').replace(
      queryParameters: {'strategy': 'hybrid'},
    );
    _log('GET $uri');

    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders).timeout(_timeout);
    } catch (e, st) {
      _log('Recommendations network error: $e\n$st');
      throw _wrapNetworkError('recommendations', e);
    }

    _log('Recommendations status: ${response.statusCode}');
    _log('Recommendations body: ${_truncate(response.body)}');

    if (response.statusCode != 200) {
      throw ApiException(
        _errorMessage(response, fallback: 'Failed to load recommendations'),
        statusCode: response.statusCode,
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final strategy = data['strategy'];
      final engineVersion = data['engine_version'];
      _log('Parsed envelope: strategy=$strategy engine_version=$engineVersion');

      final items = data['items'];
      if (items is! List) {
        throw const FormatException('items is not a List');
      }

      final results = <Recommendation>[];
      for (var i = 0; i < items.length; i++) {
        try {
          final raw = items[i];
          if (raw is! Map<String, dynamic>) {
            throw FormatException('item[$i] is not an object');
          }
          results.add(Recommendation.fromJson(raw));
        } catch (e, st) {
          _log('Parse error at items[$i]: $e\n$st');
          throw ApiException('Failed to parse recommendation item[$i]: $e', cause: e);
        }
      }

      _log('Loaded ${results.length} recommendations');
      return results;
    } catch (e, st) {
      if (e is ApiException) rethrow;
      _log('Recommendations parse error: $e\n$st');
      throw ApiException('Failed to parse recommendations response: $e', cause: e);
    }
  }

  ApiException _wrapNetworkError(String operation, Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('connection failed')) {
      return ApiException(
        'Cannot reach backend at $baseUrl during $operation.\n'
        'Start the API: cd backend && python -m uvicorn app.main:app --reload',
        cause: error,
      );
    }
    if (kIsWeb &&
        (text.contains('xmlhttprequest') ||
            text.contains('failed to fetch') ||
            text.contains('networkerror'))) {
      return ApiException(
        'Browser blocked the $operation request (likely CORS).\n'
        'Ensure backend CORS allows your Flutter web origin '
        '(e.g. http://localhost:<port>) and restart uvicorn.',
        cause: error,
      );
    }
    return ApiException('Network error during $operation: $error', cause: error);
  }

  String _errorMessage(http.Response response, {required String fallback}) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] != null) {
        return body['detail'].toString();
      }
    } catch (_) {
      // ignore parse errors
    }
    final snippet = _truncate(response.body, max: 200);
    if (snippet.isNotEmpty) {
      return '$fallback (${response.statusCode}): $snippet';
    }
    return '$fallback (HTTP ${response.statusCode})';
  }

  String _truncate(String text, {int max = 500}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}…';
  }
}
