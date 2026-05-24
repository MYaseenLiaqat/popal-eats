import 'api_client.dart';

/// Admin API client (requires admin JWT).
class AdminService {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> analyticsOverview() async {
    final r = await _api.get('/admin/analytics/overview');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<List<dynamic>> listReviews({String? processingStatus, int page = 1}) async {
    final query = {
      'page': '$page',
      'limit': '20',
      if (processingStatus != null) 'processing_status': processingStatus,
    };
    final r = await _api.get('/admin/reviews', query: query);
    _api.throwIfError(r);
    return _api.decodeList(r);
  }

  Future<List<dynamic>> listMenuUploads({int page = 1}) async {
    final r = await _api.get('/admin/menu/uploads', query: {'page': '$page', 'limit': '20'});
    _api.throwIfError(r);
    return _api.decodeList(r);
  }

  Future<List<dynamic>> listUsers({int page = 1}) async {
    final r = await _api.get('/admin/users', query: {'page': '$page', 'limit': '20'});
    _api.throwIfError(r);
    return _api.decodeList(r);
  }
}
