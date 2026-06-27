import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/onboarding_option.dart';
import '../models/user_preferences.dart';
import '../services/api_client.dart';
import '../services/preferences_service.dart';
import '../utils/recommendation_copy.dart';

class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({PreferencesService? service})
      : _service = service ?? PreferencesService();

  static const _cacheKey = 'onboarding_completed';

  final PreferencesService _service;

  bool? completed;
  bool loading = false;
  bool optionsLoading = false;
  String? error;
  OnboardingOptions? options;

  bool get needsOnboarding => completed == false;

  Future<void> reset() async {
    completed = null;
    options = null;
    error = null;
    notifyListeners();
  }

  Future<void> checkStatus({bool forceRefresh = false}) async {
    if (!ApiClient.instance.isAuthenticated) {
      completed = null;
      notifyListeners();
      return;
    }

    if (!forceRefresh) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_cacheKey)) {
        completed = prefs.getBool(_cacheKey);
        notifyListeners();
      }
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final status = await _service.getOnboardingStatus();
      completed = status.completed;
      await _cacheStatus(status.completed);
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadOptions() async {
    if (options != null || optionsLoading) return;
    optionsLoading = true;
    error = null;
    notifyListeners();
    try {
      options = await _service.getOnboardingOptions();
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
    } finally {
      optionsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> complete({
    required List<String> favoriteCuisines,
    required List<String> allergies,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      // Onboarding POST validates legacy food_interest keys only; persist cuisine
      // slugs via PUT /preferences immediately after marking onboarding complete.
      final status = await _service.completeOnboarding(
        favoriteCuisines: const [],
        allergies: allergies,
      );
      await _service.updatePreferences(
        UserPreferencesUpdate(
          favoriteCuisines: favoriteCuisines,
          allergies: allergies,
        ),
      );
      completed = status.completed;
      await _cacheStatus(status.completed);
      return true;
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> skip() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final status = await _service.skipOnboarding();
      completed = status.completed;
      await _cacheStatus(status.completed);
      return true;
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _cacheStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cacheKey, value);
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
