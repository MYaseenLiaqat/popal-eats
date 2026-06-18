import '../models/recommendation.dart';

/// Consumer-friendly recommendation labels — hides ML/engine terminology.
class RecommendationCopy {
  RecommendationCopy._();

  static const _blockedTerms = [
    'hybrid',
    'collaborative',
    'content',
    'fusion',
    'popularity score',
    'recommendation score',
    'content-based',
    'content score',
    'collaborative score',
    'hybrid score',
    'signals',
    'engine',
    'nutrition engine',
    'ai nutrition',
  ];

  static String matchLabel(int percent) => '$percent% match';

  static String sectionHeroTitle = 'Picked for you';
  static String sectionHeroSubtitle =
      'Dishes matched to your taste, budget, and what\'s popular nearby';

  static List<String> humanReasons(Recommendation rec) {
    final reasons = <String>[];
    final breakdown = rec.scoreBreakdown;

    if (breakdown != null) {
      if (breakdown.cuisineScore >= 1) {
        reasons.add('Because you like similar cuisines');
      }
      if (breakdown.budgetScore >= 1) {
        reasons.add('Matches your budget');
      }
      if (breakdown.nutritionScore >= 1) {
        reasons.add('Fits your nutrition goals');
      }
      if (breakdown.popularityScore >= 1 && reasons.length < 4) {
        reasons.add('Popular with other food lovers');
      }
      if (breakdown.contentScore >= 1 && reasons.length < 4) {
        reasons.add('Based on dishes you enjoy');
      }
    }

    for (final signal in rec.signalsUsed) {
      if (reasons.length >= 4) break;
      final human = _mapSignal(signal);
      if (human != null && !reasons.contains(human)) {
        reasons.add(human);
      }
    }

    if (reasons.isEmpty && rec.explanation.isNotEmpty) {
      final cleaned = _sanitize(rec.explanation);
      if (cleaned != null) reasons.add(cleaned);
    }

    if (reasons.isEmpty) {
      return const [
        'Trending this week',
        'Popular nearby',
      ];
    }

    return reasons.take(4).toList();
  }

  static String? _mapSignal(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty || _containsBlocked(lower)) return null;

    if (lower.contains('cuisine') || lower.contains('burger') || lower.contains('biryani')) {
      return 'Because you like similar food';
    }
    if (lower.contains('budget')) return 'Matches your budget';
    if (lower.contains('popular') || lower.contains('trending')) {
      return 'Trending this week';
    }
    if (lower.contains('friend') || lower.contains('group')) {
      return 'Popular with your friends';
    }
    if (lower.contains('near') || lower.contains('distance') || lower.contains('location')) {
      return 'Near your group';
    }
    if (lower.contains('nutrition') || lower.contains('protein')) {
      return 'Fits your nutrition goals';
    }

    return _sanitize(raw);
  }

  static String? _sanitize(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _containsBlocked(trimmed.toLowerCase())) return null;
    // Strip parenthetical point values from backend explanations.
    final cleaned = trimmed
        .replaceAll(RegExp(r'\(\+\d+(\.\d+)?\s*pts?\)'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty || _containsBlocked(cleaned.toLowerCase())) return null;
    if (!cleaned.endsWith('.')) return cleaned;
    return cleaned.substring(0, cleaned.length - 1);
  }

  static bool _containsBlocked(String lower) {
    return _blockedTerms.any((term) => lower.contains(term));
  }
}
