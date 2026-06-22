import 'package:flutter/foundation.dart';

import '../providers/onboarding_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../utils/recommendation_copy.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = AuthService();
  Map<String, dynamic>? user;
  bool loading = false;
  bool initializing = true;
  String? error;

  bool get isLoggedIn => ApiClient.instance.isAuthenticated;
  bool get googleSignInAvailable => GoogleAuthService.isConfigured;

  Future<void> init() async {
    try {
      await ApiClient.instance.loadToken();
      if (isLoggedIn) {
        try {
          user = await _auth.me();
        } catch (_) {
          await _auth.logout();
        }
      }
    } finally {
      initializing = false;
      notifyListeners();
    }
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
      error = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final idToken = await GoogleAuthService.instance.signInAndGetIdToken();
      if (idToken == null) return false;
      await _auth.loginWithGoogle(idToken: idToken);
      user = await _auth.me();
      return true;
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
      return false;
    } catch (e) {
      error = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? phone,
    String? city,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _auth.register(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
        phone: phone,
        city: city,
      );
      return await login(email, password);
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> checkUsernameAvailable(String username) async {
    try {
      return await _auth.checkUsernameAvailable(username);
    } on ApiException {
      return false;
    }
  }

  Future<void> logout() async {
    await GoogleAuthService.instance.signOut();
    await _auth.logout();
    await OnboardingProvider.clearCache();
    user = null;
    notifyListeners();
  }
}
