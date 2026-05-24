import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = AuthService();
  Map<String, dynamic>? user;
  bool loading = false;
  String? error;

  bool get isLoggedIn => ApiClient.instance.isAuthenticated;

  Future<void> init() async {
    await ApiClient.instance.loadToken();
    if (isLoggedIn) {
      try {
        user = await _auth.me();
      } catch (_) {
        await _auth.logout();
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _auth.login(email: email, password: password);
      user = await _auth.me();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _auth.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      return await login(email, password);
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    user = null;
    notifyListeners();
  }
}
