import 'cuisine_assets.dart';

/// Canonical cuisine catalog for onboarding and preference screens.
///
/// Storage keys are lowercase slugs sent to `favorite_cuisines` (API normalizes).
class CuisineDefinition {
  const CuisineDefinition({
    required this.key,
    required this.name,
    this.description,
  });

  final String key;
  final String name;
  final String? description;

  String get imageAsset => CuisineAssets.pathFor(key);
}

abstract final class CuisineCatalog {
  static const maxSelections = 10;

  static const cuisines = <CuisineDefinition>[
    CuisineDefinition(
      key: 'pakistani',
      name: 'Pakistani',
      description: 'Traditional biryani, karahi & kebabs',
    ),
    CuisineDefinition(
      key: 'afghan',
      name: 'Afghan',
      description: 'Kabuli pulao, mantu & bolani',
    ),
    CuisineDefinition(
      key: 'turkish',
      name: 'Turkish',
      description: 'Doner, pide & kebabs',
    ),
    CuisineDefinition(
      key: 'chinese',
      name: 'Chinese',
      description: 'Noodles, fried rice & dumplings',
    ),
    CuisineDefinition(
      key: 'korean',
      name: 'Korean',
      description: 'Bibimbap, bulgogi & kimchi',
    ),
    CuisineDefinition(
      key: 'italian',
      name: 'Italian',
      description: 'Pizza, pasta & risotto',
    ),
    CuisineDefinition(
      key: 'arabic',
      name: 'Arabic',
      description: 'Shawarma, falafel & mandi',
    ),
    CuisineDefinition(
      key: 'persian',
      name: 'Persian',
      description: 'Kabob, tahdig & ghormeh sabzi',
    ),
    CuisineDefinition(
      key: 'fast_food',
      name: 'Fast Food',
      description: 'Burgers, fries & quick bites',
    ),
    CuisineDefinition(
      key: 'desserts',
      name: 'Desserts',
      description: 'Cakes, pastries & ice cream',
    ),
    CuisineDefinition(
      key: 'bbq',
      name: 'BBQ',
      description: 'Grilled meats, kebabs & smoky flavors',
    ),
    CuisineDefinition(
      key: 'beverages',
      name: 'Beverages',
      description: 'Juices, shakes, coffee & tea',
    ),
  ];

  static CuisineDefinition? byKey(String key) {
    final normalized = key.trim().toLowerCase();
    for (final cuisine in cuisines) {
      if (cuisine.key == normalized) return cuisine;
    }
    return null;
  }

  static String labelFor(String key) {
    return byKey(key)?.name ??
        key.replaceAll('_', ' ').split(' ').map(_titleWord).join(' ');
  }

  static String _titleWord(String word) {
    if (word.isEmpty) return word;
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }
}
