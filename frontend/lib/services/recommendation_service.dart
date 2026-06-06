import '../models/recommendation.dart';
import 'api_client.dart';

/// Recommendation Engine V2 API client.
class RecommendationService {
  final _api = ApiClient.instance;

  Future<List<Recommendation>> list({
    String strategy = 'hybrid',
  }) async {
    final r = await _api.get('/recommendations/v2', query: {
      'strategy': strategy,
    });
    _api.throwIfError(r);
    return _parseItems(_api.decodeJson(r), strategy: strategy);
  }

  Future<List<Recommendation>> trending({int limit = 10}) async {
    final r = await _api.get('/recommendations/v2/trending', query: {
      'limit': '$limit',
    });
    _api.throwIfError(r);
    return _parseTrendingPopular(_api.decodeJson(r), kind: 'trending');
  }

  Future<List<Recommendation>> popular({int limit = 10}) async {
    final r = await _api.get('/recommendations/v2/popular', query: {
      'limit': '$limit',
    });
    _api.throwIfError(r);
    return _parseTrendingPopular(_api.decodeJson(r), kind: 'popular');
  }

  Future<Map<String, dynamic>> profile() async {
    final r = await _api.get('/recommendations/v2/profile');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<void> logEvent({
    required int dishId,
    required String eventType,
    String strategy = 'hybrid',
  }) async {
    final r = await _api.post('/recommendations/v2/event', body: {
      'dish_id': dishId,
      'event_type': eventType,
      'strategy': strategy,
    });
    _api.throwIfError(r);
  }

  List<Recommendation> _parseItems(
    Map<String, dynamic> data, {
    String? strategy,
  }) {
    final engineVersion = data['engine_version']?.toString();
    final responseStrategy = data['strategy']?.toString() ?? strategy;
    final items = data['items'];
    if (items is! List) return [];

    return items.whereType<Map<String, dynamic>>().map((json) {
      final rec = Recommendation.fromJson(json);
      return Recommendation(
        dishId: rec.dishId,
        dishName: rec.dishName,
        restaurantName: rec.restaurantName,
        price: rec.price,
        score: rec.score,
        explanation: rec.explanation,
        calories: rec.calories,
        scoreBreakdown: rec.scoreBreakdown,
        signalsUsed: rec.signalsUsed,
        strategy: responseStrategy,
        engineVersion: engineVersion,
      );
    }).toList();
  }

  List<Recommendation> _parseTrendingPopular(
    Map<String, dynamic> data, {
    required String kind,
  }) {
    final engineVersion = data['engine_version']?.toString();
    final items = data['items'];
    if (items is! List) return [];

    return items.whereType<Map<String, dynamic>>().map((json) {
      final score = kind == 'trending'
          ? (json['trending_score'] as num?)?.toDouble() ?? 0
          : (json['total_orders'] as num?)?.toDouble() ?? 0;
      return Recommendation(
        dishId: json['dish_id'] as int,
        dishName: json['dish_name']?.toString() ?? '',
        restaurantName: json['restaurant_name']?.toString() ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        score: score,
        explanation: kind == 'trending' ? 'Trending dish' : 'Popular dish',
        strategy: kind,
        engineVersion: engineVersion,
      );
    }).toList();
  }
}
