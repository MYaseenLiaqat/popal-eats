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

  Future<List<dynamic>> listRestaurants({
    int page = 1,
    String? approvalStatus,
  }) async {
    final r = await _api.get('/admin/restaurants', query: {
      'page': '$page',
      'limit': '20',
      if (approvalStatus != null) 'approval_status': approvalStatus,
    });
    _api.throwIfError(r);
    return _api.decodeList(r);
  }

  Future<Map<String, dynamic>> pendingRestaurantCount() async {
    final r = await _api.get('/admin/restaurants/pending/count');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> updateRestaurantApproval(
    int restaurantId, {
    required String approvalStatus,
    String? rejectionReason,
  }) async {
    final r = await _api.patch(
      '/admin/restaurants/$restaurantId/approval',
      body: {
        'approval_status': approvalStatus,
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      },
    );
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }
}
