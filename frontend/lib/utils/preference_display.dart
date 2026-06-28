import '../data/cuisine_catalog.dart';

/// Maps backend preference keys to human-readable labels for UI.
class PreferenceDisplay {
  PreferenceDisplay._();

  static final nutritionCuisineOptions = <String, String>{
    for (final c in CuisineCatalog.cuisines) c.key: c.name,
  };

  static const foodInterestLabels = <String, String>{
    'burger': 'Burger',
    'pizza': 'Pizza',
    'biryani': 'Biryani',
    'bbq': 'BBQ',
    'chinese': 'Chinese',
    'italian': 'Italian',
    'shawarma': 'Shawarma',
    'desserts': 'Desserts',
    'healthy': 'Healthy',
    'cafe': 'Cafe',
    'sushi': 'Sushi',
    'pakistani': 'Pakistani',
    'fast_food': 'Fast Food',
    'seafood': 'Seafood',
    'sandwiches': 'Sandwiches',
  };

  static const allergyLabels = <String, String>{
    'peanuts': 'Peanuts',
    'tree_nuts': 'Tree Nuts',
    'shellfish': 'Shellfish',
    'fish': 'Fish',
    'eggs': 'Eggs',
    'milk': 'Milk',
    'dairy': 'Dairy',
    'soy': 'Soy',
    'wheat': 'Wheat',
    'gluten': 'Gluten',
    'sesame': 'Sesame',
    'mustard': 'Mustard',
    'celery': 'Celery',
    'sulphites': 'Sulphites',
    'lupin': 'Lupin',
    'molluscs': 'Molluscs',
    'lactose': 'Lactose',
    'nuts': 'Nuts',
  };

  static const dietTypes = ['None', 'Vegetarian', 'Vegan', 'Keto', 'High Protein'];

  static const budgetModes = [
    ('Economy', 'low'),
    ('Balanced', 'medium'),
    ('Premium', 'premium'),
  ];

  static const nutritionGoals = <String, String>{
    'maintain': 'Maintain',
    'weight_loss': 'Weight Loss',
    'bulking': 'Bulking',
    'muscle_gain': 'Muscle Gain',
    'high_protein': 'High Protein',
  };

  static String nutritionGoalLabel(String? key) {
    if (key == null || key.isEmpty) return 'Maintain';
    final normalized = key.trim().toLowerCase().replaceAll(' ', '_');
    return nutritionGoals[normalized] ?? cuisineLabel(normalized);
  }

  static String nutritionGoalToBackend(String label) {
    for (final entry in nutritionGoals.entries) {
      if (entry.value == label) return entry.key;
    }
    return label.trim().toLowerCase().replaceAll(' ', '_');
  }

  static String cuisineLabel(String key) {
    return CuisineCatalog.labelFor(key);
  }

  static String allergyLabel(String key) => allergyLabels[key] ?? cuisineLabel(key);

  static String dietLabelFromBackend(List<String> dietary) {
    if (dietary.isEmpty) return 'None';
    final primary = dietary.first;
    return switch (primary) {
      'vegetarian' => 'Vegetarian',
      'vegan' => 'Vegan',
      'keto' => 'Keto',
      'low_carb' => 'High Protein',
      _ => cuisineLabel(primary),
    };
  }

  static List<String> dietToBackend(String dietType) {
    return switch (dietType) {
      'Vegetarian' => ['vegetarian'],
      'Vegan' => ['vegan'],
      'Keto' => ['keto'],
      'High Protein' => ['low_carb'],
      _ => [],
    };
  }

  static String budgetLabelFromBackend(String? level) {
    return switch (level) {
      'low' => 'Economy',
      'medium' => 'Balanced',
      'high' => 'Premium',
      'premium' => 'Premium',
      _ => 'Balanced',
    };
  }

  static String budgetToBackend(String mode) {
    return switch (mode) {
      'Economy' => 'low',
      'Balanced' => 'medium',
      'Premium' => 'premium',
      _ => 'medium',
    };
  }

  static String summarizeCuisines(List<String> cuisines, {int max = 3}) {
    if (cuisines.isEmpty) return 'Not set';
    final labels = cuisines.map(cuisineLabel).toList();
    if (labels.length <= max) return labels.join(', ');
    return '${labels.take(max).join(', ')} +${labels.length - max}';
  }
}
