import '../models/review.dart';
import 'api_client.dart';

class ReviewService {
  final _api = ApiClient.instance;

  Future<List<Review>> listForRestaurant(
    int restaurantId, {
    int page = 1,
    int limit = 20,
  }) async {
    final query = {
      'page': '$page',
      'limit': '$limit',
      'restaurant_id': '$restaurantId',
      'sort': 'desc',
    };
    final r = await _api.get('/reviews', query: query, auth: false);
    _api.throwIfError(r);
    final items = _api.decodeList(r);
    return items
        .whereType<Map>()
        .map((e) => Review.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> getProcessingStatus(int reviewId) async {
    final r = await _api.get('/reviews/$reviewId/processing');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Review> create({
    required int restaurantId,
    required int rating,
    String? comment,
  }) async {
    final r = await _api.post(
      '/reviews',
      body: {
        'restaurant_id': restaurantId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      },
    );
    _api.throwIfError(r);
    return Review.fromJson(_api.decodeJson(r));
  }
}
