import 'package:shared_preferences/shared_preferences.dart';

import '../models/username_check_result.dart';
import '../utils/auth_validation.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient.instance;

  static const _usernameCheckTimeout = Duration(seconds: 8);

  Future<UsernameCheckResult> checkUsernameAvailable(String username) async {
    try {
      final r = await _api.get(
        '/auth/username-available',
        query: {'username': username.trim().toLowerCase()},
        auth: false,
        timeout: _usernameCheckTimeout,
      );
      if (r.statusCode == 400) {
        final err = _api.decodeJson(r);
        final msg = err['error']?.toString() ??
            err['detail']?.toString() ??
            'Invalid username format.';
        return UsernameCheckResult.invalid(msg);
      }
      _api.throwIfError(r);
      final data = _api.decodeJson(r);
      return data['available'] == true
          ? const UsernameCheckResult.available()
          : const UsernameCheckResult.taken();
    } on ApiException {
      return const UsernameCheckResult.error();
    } catch (_) {
      return const UsernameCheckResult.error();
    }
  }

  Future<Map<String, dynamic>> register({
    required SignupRole role,
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phone,
    required DateTime dateOfBirth,
    required String password,
    required String confirmPassword,
    String? city,
    Map<String, dynamic>? restaurantProfile,
    Map<String, dynamic>? homeChefProfile,
  }) async {
    final dob =
        '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';

    final body = <String, dynamic>{
      'role': role.apiValue,
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'username': username.trim().toLowerCase(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'date_of_birth': dob,
      'password': password,
      'confirm_password': confirmPassword,
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (restaurantProfile != null) 'restaurant_profile': restaurantProfile,
      if (homeChefProfile != null) 'home_chef_profile': homeChefProfile,
    };

    final r = await _api.post('/register', body: body, auth: false);
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final r = await _api.post(
      '/login',
      body: {'email': email.trim().toLowerCase(), 'password': password},
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
