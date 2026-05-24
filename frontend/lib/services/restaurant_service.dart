import 'api_client.dart';

class RestaurantService {
  final _api = ApiClient.instance;

  Future<List<dynamic>> list({
    int page = 1,
    int limit = 20,
    String? search,
    String? city,
  }) async {
    final query = {
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.isNotEmpty) 'search': search,
      if (city != null && city.isNotEmpty) 'city': city,
    };
    final r = await _api.get('/restaurants', query: query, auth: false);
    _api.throwIfError(r);
    return _api.decodeList(r);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final r = await _api.post('/restaurants', body: body);
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final r = await _api.get('/restaurants/$id', auth: false);
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }
}
