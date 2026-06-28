import 'json_parse.dart';

/// Per-signal contribution from `V2SignalContribution`.
class RecommendationContribution {
  const RecommendationContribution({
    required this.signal,
    required this.label,
    required this.points,
  });

  final String signal;
  final String label;
  final double points;

  factory RecommendationContribution.fromJson(Map<String, dynamic> json) =>
      RecommendationContribution(
        signal: parseString(json['signal']),
        label: parseString(json['label']),
        points: parseDoubleOrNull(json['points']) ?? 0,
      );
}

/// Component scores from `V2ScoreBreakdown`.
class RecommendationScoreBreakdown {
  const RecommendationScoreBreakdown({
    this.cuisineScore = 0,
    this.nutritionScore = 0,
    this.budgetScore = 0,
    this.popularityScore = 0,
    this.collaborativeScore = 0,
    this.feedbackScore = 0,
    this.contentScore = 0,
    this.hybridScore = 0,
    this.totalScore = 0,
  });

  final double cuisineScore;
  final double nutritionScore;
  final double budgetScore;
  final double popularityScore;
  final double collaborativeScore;
  final double feedbackScore;
  final double contentScore;
  final double hybridScore;
  final double totalScore;

  factory RecommendationScoreBreakdown.fromJson(Map<String, dynamic> json) =>
      RecommendationScoreBreakdown(
        cuisineScore: parseDoubleOrNull(json['cuisine_score']) ?? 0,
        nutritionScore: parseDoubleOrNull(json['nutrition_score']) ?? 0,
        budgetScore: parseDoubleOrNull(json['budget_score']) ?? 0,
        popularityScore: parseDoubleOrNull(json['popularity_score']) ?? 0,
        collaborativeScore: parseDoubleOrNull(json['collaborative_score']) ?? 0,
        feedbackScore: parseDoubleOrNull(json['feedback_score']) ?? 0,
        contentScore: parseDoubleOrNull(json['content_score']) ?? 0,
        hybridScore: parseDoubleOrNull(json['hybrid_score']) ?? 0,
        totalScore: parseDoubleOrNull(json['total_score']) ?? 0,
      );
}

/// Dish recommendation from `GET /recommendations/v2` (`V2DishRecommendationItem`).
class Recommendation {
  const Recommendation({
    required this.dishId,
    required this.dishName,
    required this.restaurantName,
    required this.price,
    required this.score,
    required this.explanation,
    this.calories,
    this.scoreBreakdown,
    this.signalsUsed = const [],
    this.strategy,
    this.engineVersion,
    this.confidencePercent,
    this.explanationBullets = const [],
    this.contributions = const [],
  });

  final int dishId;
  final String dishName;
  final String restaurantName;
  final double price;
  final double score;
  final String explanation;
  final int? calories;
  final RecommendationScoreBreakdown? scoreBreakdown;
  final List<String> signalsUsed;
  final String? strategy;
  final String? engineVersion;
  final int? confidencePercent;
  final List<String> explanationBullets;
  final List<RecommendationContribution> contributions;

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        dishId: parseInt(json['dish_id'], field: 'dish_id'),
        dishName: parseString(json['dish_name']),
        restaurantName: parseString(json['restaurant_name']),
        price: parseDouble(json['price'], field: 'price'),
        score: parseDouble(json['score'], field: 'score'),
        explanation: parseString(json['explanation']),
        calories: parseIntOrNull(json['calories']),
        scoreBreakdown: json['score_breakdown'] is Map<String, dynamic>
            ? RecommendationScoreBreakdown.fromJson(
                json['score_breakdown'] as Map<String, dynamic>,
              )
            : null,
        signalsUsed: json['signals_used'] is List
            ? (json['signals_used'] as List).map((e) => e.toString()).toList()
            : const [],
        confidencePercent: parseIntOrNull(json['confidence_percent']),
        explanationBullets: json['explanation_bullets'] is List
            ? (json['explanation_bullets'] as List).map((e) => e.toString()).toList()
            : const [],
        contributions: json['contributions'] is List
            ? (json['contributions'] as List)
                .whereType<Map<String, dynamic>>()
                .map(RecommendationContribution.fromJson)
                .toList()
            : const [],
        strategy: json['strategy']?.toString(),
        engineVersion: json['engine_version']?.toString(),
      );
}
