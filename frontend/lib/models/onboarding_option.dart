class OnboardingOption {
  const OnboardingOption({required this.key, required this.displayName});

  final String key;
  final String displayName;

  factory OnboardingOption.fromJson(Map<String, dynamic> json) {
    return OnboardingOption(
      key: json['key']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
    );
  }
}

class OnboardingOptions {
  const OnboardingOptions({
    required this.foodInterests,
    required this.allergies,
  });

  final List<OnboardingOption> foodInterests;
  final List<OnboardingOption> allergies;

  factory OnboardingOptions.fromJson(Map<String, dynamic> json) {
    final food = (json['food_interests'] as List? ?? [])
        .whereType<Map>()
        .map((e) => OnboardingOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final allergy = (json['allergies'] as List? ?? [])
        .whereType<Map>()
        .map((e) => OnboardingOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return OnboardingOptions(foodInterests: food, allergies: allergy);
  }
}

class OnboardingStatus {
  const OnboardingStatus({required this.completed});

  final bool completed;

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(completed: json['completed'] == true);
  }
}
