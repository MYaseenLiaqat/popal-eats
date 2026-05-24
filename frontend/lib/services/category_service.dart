import 'api_client.dart';

class CategoryService {
  final _api = ApiClient.instance;

  Future<List<dynamic>> list({int page = 1, int limit = 20, String? search}) async {
    final query = {
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final r = await _api.get('/categories', query: query, auth: false);
    _api.throwIfError(r);
    return _api.decodeList(r);
  }
}
