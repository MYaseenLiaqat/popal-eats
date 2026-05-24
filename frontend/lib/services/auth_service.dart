import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthService {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final r = await _api.post(
      '/register',
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
      },
      auth: false,
    );
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final r = await _api.post(
      '/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    _api.throwIfError(r);
    final data = _api.decodeJson(r);
    await _api.saveToken(data['access_token'] as String);
    final refresh = data['refresh_token'] as String?;
    if (refresh != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('refresh_token', refresh);
    }
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final r = await _api.get('/me');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<void> logout() => _api.clearToken();
}
