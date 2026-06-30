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
        final msg = _extractErrorMessage(err) ?? 'Invalid username format.';
        return UsernameCheckResult.invalid(msg);
      }
      _api.throwIfError(r);
      final data = _api.decodeJson(r);
      final available = data['available'];
      if (available == true) {
        return const UsernameCheckResult.available();
      }
      if (available == false) {
        return const UsernameCheckResult.taken();
      }
      return const UsernameCheckResult.error(
          'Unexpected username check response');
    } on ApiException catch (e) {
      return UsernameCheckResult.error(e.message);
    } catch (_) {
      return const UsernameCheckResult.error();
    }
  }

  String? _extractErrorMessage(Map<String, dynamic> err) {
    final error = err['error'] ?? err['detail'];
    if (error is String && error.isNotEmpty) return error;
    if (error is List && error.isNotEmpty) {
      return error.map((e) => e.toString()).join('\n');
    }
    return null;
  }

  Future<Map<String, dynamic>> register({
    required SignupRole role,
    String? firstName,
    String? lastName,
    String? username,
    required String email,
    required String phone,
    DateTime? dateOfBirth,
    required String password,
    required String confirmPassword,
    String? city,
    Map<String, dynamic>? restaurantProfile,
    Map<String, dynamic>? homeChefProfile,
  }) async {
    final body = <String, dynamic>{
      'role': role.apiValue,
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'password': password,
      'confirm_password': confirmPassword,
      if (firstName != null && firstName.trim().isNotEmpty)
        'first_name': firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty)
        'last_name': lastName.trim(),
      if (username != null && username.trim().isNotEmpty)
        'username': username.trim().toLowerCase(),
      if (dateOfBirth != null)
        'date_of_birth':
            '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
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

  Future<Map<String, dynamic>> loginWithGoogle(
      {required String idToken}) async {
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
