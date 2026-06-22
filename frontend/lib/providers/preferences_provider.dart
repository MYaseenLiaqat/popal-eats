import 'package:flutter/foundation.dart';

import '../models/user_preferences.dart';
import '../services/api_client.dart';
import '../services/preferences_service.dart';
import '../utils/recommendation_copy.dart';

class PreferencesProvider extends ChangeNotifier {
  PreferencesProvider({PreferencesService? service})
      : _service = service ?? PreferencesService();

  final PreferencesService _service;

  UserPreferences? preferences;
  bool loading = false;
  bool saving = false;
  String? error;

  Future<void> reset() async {
    preferences = null;
    loading = false;
    saving = false;
    error = null;
    notifyListeners();
  }

  Future<void> fetch({bool force = false}) async {
    if (!ApiClient.instance.isAuthenticated) {
      await reset();
      return;
    }
    if (!force && preferences != null) return;
    if (loading) return;

    loading = true;
    error = null;
    notifyListeners();

    try {
      preferences = await _service.getPreferences();
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateNutrition({
    required List<String> favoriteCuisines,
    required List<String> dietaryPreferences,
    String? nutritionGoal,
  }) async {
    return _save(
      UserPreferencesUpdate(
        favoriteCuisines: favoriteCuisines,
        dietaryPreferences: dietaryPreferences,
        nutritionGoal: nutritionGoal,
      ),
    );
  }

  Future<bool> updateBudget({required String budgetLevel}) async {
    return _save(UserPreferencesUpdate(budgetLevel: budgetLevel));
  }

  Future<bool> _save(UserPreferencesUpdate update) async {
    saving = true;
    error = null;
    notifyListeners();

    try {
      preferences = await _service.updatePreferences(update);
      return true;
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
