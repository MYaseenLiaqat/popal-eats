import 'api_client.dart';

class DishService {
  final _api = ApiClient.instance;

  Future<List<dynamic>> list({
    int page = 1,
    int limit = 20,
    int? restaurantId,
    int? categoryId,
  }) async {
    final query = {
      'page': '$page',
      'limit': '$limit',
      if (restaurantId != null) 'restaurant_id': '$restaurantId',
      if (categoryId != null) 'category_id': '$categoryId',
    };
    final r = await _api.get('/dishes', query: query, auth: false);
    _api.throwIfError(r);
    return _api.decodeList(r);
  }
}
