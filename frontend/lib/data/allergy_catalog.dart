import '../models/onboarding_option.dart';

/// Canonical allergy catalog for onboarding UI.
///
/// Only allergies listed here appear on the onboarding grid.
/// Storage keys are sent to the API unchanged when selected.
abstract final class AllergyCatalog {
  static const allergyKeys = <String>[
    'celery',
    'dairy',
    'eggs',
    'fish',
    'gluten',
    'lupin',
    'molluscs',
    'mustard',
    'peanuts',
    'sesame',
    'shellfish',
    'soy',
    'sulphites',
    'wheat',
  ];

  static int get count => allergyKeys.length;

  /// Returns API options filtered to [allergyKeys] and sorted for display.
  static List<OnboardingOption> optionsFromApi(List<OnboardingOption> apiOptions) {
    final byKey = {for (final option in apiOptions) option.key: option};
    return [
      for (final key in allergyKeys)
        if (byKey[key] != null) byKey[key]!,
    ];
  }
}
