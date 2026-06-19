import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthService {
  final _api = ApiClient.instance;

  Future<bool> checkUsernameAvailable(String username) async {
    final r = await _api.get(
      '/auth/username-available',
      query: {'username': username.trim().toLowerCase()},
      auth: false,
    );
    _api.throwIfError(r);
    final data = _api.decodeJson(r);
    return data['available'] == true;
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? phone,
    String? city,
  }) async {
    final r = await _api.post(
      '/register',
      body: {
        'full_name': fullName,
        'username': username.trim().toLowerCase(),
        'email': email,
        'password': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
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
    await _saveTokens(data);
    return data;
  }

  Future<Map<String, dynamic>> loginWithGoogle({required String idToken}) async {
    final r = await _api.post(
      '/auth/google',
      body: {'id_token': idToken},
      auth: false,
    );
    _api.throwIfError(r);
    final data = _api.decodeJson(r);
    await _saveTokens(data);
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final r = await _api.get('/me');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<void> logout() => _api.clearToken();

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _api.saveToken(data['access_token'] as String);
    final refresh = data['refresh_token'] as String?;
    if (refresh != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('refresh_token', refresh);
    }
  }
}
