import 'api_client.dart';

class ReviewService {
  final _api = ApiClient.instance;

  Future<List<dynamic>> list({int? restaurantId, int page = 1}) async {
    final query = {
      'page': '$page',
      'limit': '20',
      if (restaurantId != null) 'restaurant_id': '$restaurantId',
    };
    final r = await _api.get('/reviews', query: query, auth: false);
    _api.throwIfError(r);
    return _api.decodeList(r);
  }

  Future<Map<String, dynamic>> getProcessingStatus(int reviewId) async {
    final r = await _api.get('/reviews/$reviewId/processing');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> create({
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
    return _api.decodeJson(r);
  }
}
