class UserPreferences {
  const UserPreferences({
    this.favoriteCuisines = const [],
    this.dietaryPreferences = const [],
    this.budgetLevel,
    this.dislikedCategories = const [],
    this.allergies = const [],
  });

  final List<String> favoriteCuisines;
  final List<String> dietaryPreferences;
  final String? budgetLevel;
  final List<String> dislikedCategories;
  final List<String> allergies;

  UserPreferences copyWith({
    List<String>? favoriteCuisines,
    List<String>? dietaryPreferences,
    String? budgetLevel,
    List<String>? dislikedCategories,
    List<String>? allergies,
  }) {
    return UserPreferences(
      favoriteCuisines: favoriteCuisines ?? this.favoriteCuisines,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      dislikedCategories: dislikedCategories ?? this.dislikedCategories,
      allergies: allergies ?? this.allergies,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      favoriteCuisines: _stringList(json['favorite_cuisines']),
      dietaryPreferences: _stringList(json['dietary_preferences']),
      budgetLevel: json['budget_level']?.toString(),
      dislikedCategories: _stringList(json['disliked_categories']),
      allergies: _stringList(json['allergies']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => e.toString().trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
  }
}

class UserPreferencesUpdate {
  const UserPreferencesUpdate({
    this.favoriteCuisines,
    this.dietaryPreferences,
    this.budgetLevel,
    this.dislikedCategories,
    this.allergies,
  });

  final List<String>? favoriteCuisines;
  final List<String>? dietaryPreferences;
  final String? budgetLevel;
  final List<String>? dislikedCategories;
  final List<String>? allergies;

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{};
    if (favoriteCuisines != null) body['favorite_cuisines'] = favoriteCuisines;
    if (dietaryPreferences != null) body['dietary_preferences'] = dietaryPreferences;
    if (budgetLevel != null) body['budget_level'] = budgetLevel;
    if (dislikedCategories != null) body['disliked_categories'] = dislikedCategories;
    if (allergies != null) body['allergies'] = allergies;
    return body;
  }
}
