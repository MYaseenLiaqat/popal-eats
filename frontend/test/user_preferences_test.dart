import 'package:flutter_test/flutter_test.dart';

import 'package:popal_eats/models/user_preferences.dart';
import 'package:popal_eats/utils/preference_display.dart';

void main() {
  test('UserPreferences parses backend payload', () {
    final prefs = UserPreferences.fromJson({
      'favorite_cuisines': ['pizza', 'biryani'],
      'dietary_preferences': ['vegetarian'],
      'budget_level': 'medium',
      'disliked_categories': ['spicy'],
      'allergies': ['peanuts'],
    });

    expect(prefs.favoriteCuisines, ['pizza', 'biryani']);
    expect(prefs.dietaryPreferences, ['vegetarian']);
    expect(prefs.budgetLevel, 'medium');
    expect(prefs.allergies, ['peanuts']);
  });

  test('PreferenceDisplay maps diet and budget labels', () {
    expect(PreferenceDisplay.dietLabelFromBackend(['vegetarian']), 'Vegetarian');
    expect(PreferenceDisplay.dietToBackend('Keto'), ['keto']);
    expect(PreferenceDisplay.budgetLabelFromBackend('low'), 'Economy');
    expect(PreferenceDisplay.budgetToBackend('Balanced'), 'medium');
    expect(PreferenceDisplay.cuisineLabel('biryani'), 'Biryani');
  });
}
