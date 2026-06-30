import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Paginated admin list response.
class AdminPage<T> {
  const AdminPage({
    required this.items,
    required this.page,
    required this.totalCount,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int totalCount;
  final int totalPages;
}

/// Admin API client (requires admin JWT).
class AdminService {
  final _api = ApiClient.instance;

  AdminPage<Map<String, dynamic>> _decodePage(http.Response r) {
    final data = jsonDecode(r.body);
    if (data is Map<String, dynamic>) {
      final rawItems = data['items'];
      final items = rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      return AdminPage(
        items: items,
        page: data['page'] as int? ?? 1,
        totalCount: data['total_count'] as int? ?? items.length,
        totalPages: data['total_pages'] as int? ?? 1,
      );
    }
    return const AdminPage(items: [], page: 1, totalCount: 0, totalPages: 1);
  }

  List<Map<String, dynamic>> _decodeRawList(http.Response r) {
    return _api.decodeList(r).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> analyticsOverview() async {
    final r = await _api.get('/admin/analytics/overview');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> platformHealth() async {
    final r = await _api.get('/admin/analytics/health');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<AdminPage<Map<String, dynamic>>> listOrders({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    final r = await _api.get('/admin/orders', query: {
      'page': '$page',
      'limit': '$limit',
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    _api.throwIfError(r);
    return _decodePage(r);
  }

  Future<AdminPage<Map<String, dynamic>>> listContentPosts({
    String contentType = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final r = await _api.get('/admin/content/posts', query: {
      'content_type': contentType,
      'page': '$page',
      'limit': '$limit',
    });
    _api.throwIfError(r);
    return _decodePage(r);
  }

  Future<AdminPage<Map<String, dynamic>>> listContentStories({
    int page = 1,
    int limit = 20,
  }) async {
    final r = await _api.get('/admin/content/stories', query: {
      'page': '$page',
      'limit': '$limit',
    });
    _api.throwIfError(r);
    return _decodePage(r);
  }

  Future<void> deleteContentPost(int postId) async {
    final r = await _api.delete('/admin/content/posts/$postId');
    _api.throwIfError(r);
  }

  Future<Map<String, dynamic>> globalSearch(String query) async {
    final r = await _api.get('/admin/search', query: {'q': query.trim()});
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<List<Map<String, dynamic>>> listNotifications({int limit = 20}) async {
    final r = await _api.get('/admin/notifications', query: {'limit': '$limit'});
    _api.throwIfError(r);
    final data = _api.decodeJson(r);
    final items = data['items'];
    if (items is List) {
      return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> recommendationMetrics() async {
    final r = await _api.get('/admin/recommendations/metrics');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> updateUserAccountStatus(int userId, String status) async {
    final r = await _api.patch(
      '/admin/users/$userId/account-status',
      body: {'account_status': status},
    );
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<void> reprocessReview(int reviewId) async {
    final r = await _api.post('/admin/reviews/$reviewId/reprocess');
    _api.throwIfError(r);
  }

  Future<AdminPage<Map<String, dynamic>>> listReviews({
    String? processingStatus,
    int page = 1,
    int limit = 20,
  }) async {
    final r = await _api.get('/admin/reviews', query: {
      'page': '$page',
      'limit': '$limit',
      if (processingStatus != null) 'processing_status': processingStatus,
    });
    _api.throwIfError(r);
    return _decodePage(r);
  }

  Future<AdminPage<Map<String, dynamic>>> listMenuUploads({int page = 1, int limit = 20}) async {
    final r = await _api.get('/admin/menu/uploads', query: {'page': '$page', 'limit': '$limit'});
    _api.throwIfError(r);
    return _decodePage(r);
  }

  Future<AdminPage<Map<String, dynamic>>> listUsers({
    int page = 1,
    int limit = 20,
    String? role,
  }) async {
    final r = await _api.get('/admin/users', query: {
      'page': '$page',
      'limit': '$limit',
      if (role != null) 'role': role,
    });
    _api.throwIfError(r);
    return _decodePage(r);
  }

  Future<int> countUsers({String? role}) async {
    final page = await listUsers(page: 1, limit: 1, role: role);
    return page.totalCount;
  }

  Future<AdminPage<Map<String, dynamic>>> listRestaurants({
    int page = 1,
    int limit = 20,
    String? approvalStatus,
  }) async {
    final r = await _api.get('/admin/restaurants', query: {
      'page': '$page',
      'limit': '$limit',
      if (approvalStatus != null) 'approval_status': approvalStatus,
    });
    _api.throwIfError(r);
    return _decodePage(r);
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

  Future<List<Map<String, dynamic>>> listBusinessAccounts({
    String? accountStatus,
    String? role,
  }) async {
    final r = await _api.get('/admin/business-accounts', query: {
      if (accountStatus != null) 'account_status': accountStatus,
      if (role != null) 'role': role,
    });
    _api.throwIfError(r);
    return _decodeRawList(r);
  }

  Future<List<Map<String, dynamic>>> listPendingBusinessAccounts({String? role}) async {
    final r = await _api.get('/admin/business-accounts/pending', query: {
      if (role != null) 'role': role,
    });
    _api.throwIfError(r);
    return _decodeRawList(r);
  }

  Future<Map<String, dynamic>> getBusinessAccount(int userId) async {
    final r = await _api.get('/admin/business-accounts/$userId');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> approveBusinessAccount(int userId) async {
    final r = await _api.post('/admin/business-accounts/$userId/approve');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> rejectBusinessAccount(
    int userId, {
    String? reason,
  }) async {
    final r = await _api.post(
      '/admin/business-accounts/$userId/reject',
      body: {if (reason != null) 'reason': reason},
    );
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> suspendBusinessAccount(
    int userId, {
    String? reason,
  }) async {
    final r = await _api.post(
      '/admin/business-accounts/$userId/suspend',
      body: {if (reason != null) 'reason': reason},
    );
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> reactivateBusinessAccount(int userId) async {
    final r = await _api.post('/admin/business-accounts/$userId/reactivate');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> updateUserRole(int userId, String role) async {
    final r = await _api.patch('/admin/users/$userId/role', body: {'role': role});
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<void> deleteReview(int reviewId) async {
    final r = await _api.delete('/admin/reviews/$reviewId');
    _api.throwIfError(r);
  }

  /// Aggregated dashboard metrics from platform overview API.
  Future<AdminDashboardMetrics> loadDashboardMetrics() async {
    final platform = await analyticsOverview();
    final health = await platformHealth();
    final pendingAccounts = await listPendingBusinessAccounts();
    final recentUsers = await listUsers(page: 1, limit: 8);
    final recentRestaurants = await listRestaurants(page: 1, limit: 8);
    final recentReviews = await listReviews(page: 1, limit: 6);
    final notifications = await listNotifications(limit: 8);

    final kpis = platform['kpis'] as Map<String, dynamic>? ?? {};

    return AdminDashboardMetrics(
      platform: platform,
      health: health,
      pendingAccounts: pendingAccounts,
      recentUsers: recentUsers.items,
      recentRestaurants: recentRestaurants.items,
      recentReviews: recentReviews.items,
      notifications: notifications,
      kpis: kpis,
    );
  }

  /// Analytics page data from platform overview.
  Future<AdminAnalyticsData> loadAnalyticsData() async {
    final platform = await analyticsOverview();
    final restaurants = await listRestaurants(page: 1, limit: 100);
    final users = await listUsers(page: 1, limit: 100);

    final cuisineCounts = <String, int>{};
    for (final r in restaurants.items) {
      final tags = r['tags'];
      if (tags is List && tags.isNotEmpty) {
        for (final t in tags) {
          final label = t.toString();
          cuisineCounts[label] = (cuisineCounts[label] ?? 0) + 1;
        }
      }
    }

    final topRestaurants = [...restaurants.items]
      ..sort((a, b) {
        final ar = (a['average_rating'] as num?) ?? 0;
        final br = (b['average_rating'] as num?) ?? 0;
        return br.compareTo(ar);
      });

    return AdminAnalyticsData(
      platform: platform,
      cuisineCounts: cuisineCounts,
      topRestaurants: topRestaurants.take(8).toList(),
      users: users.items,
      restaurantTotal: restaurants.totalCount,
      userTotal: users.totalCount,
    );
  }
}

class AdminDashboardMetrics {
  const AdminDashboardMetrics({
    required this.platform,
    required this.health,
    required this.pendingAccounts,
    required this.recentUsers,
    required this.recentRestaurants,
    required this.recentReviews,
    required this.notifications,
    required this.kpis,
  });

  final Map<String, dynamic> platform;
  final Map<String, dynamic> health;
  final List<Map<String, dynamic>> pendingAccounts;
  final List<Map<String, dynamic>> recentUsers;
  final List<Map<String, dynamic>> recentRestaurants;
  final List<Map<String, dynamic>> recentReviews;
  final List<Map<String, dynamic>> notifications;
  final Map<String, dynamic> kpis;

  int kpi(String key) => (kpis[key] as num?)?.toInt() ?? 0;
  Map<String, dynamic> get timeseries => platform['timeseries'] as Map<String, dynamic>? ?? {};
  Map<String, dynamic> get recommendations => platform['recommendations'] as Map<String, dynamic>? ?? {};
  Map<String, dynamic> get topEntities => platform['top_entities'] as Map<String, dynamic>? ?? {};

  int get pendingApprovals => kpi('pending_restaurant_approvals') + kpi('pending_home_chef_approvals');
}

class AdminAnalyticsData {
  const AdminAnalyticsData({
    required this.platform,
    required this.cuisineCounts,
    required this.topRestaurants,
    required this.users,
    required this.restaurantTotal,
    required this.userTotal,
  });

  final Map<String, dynamic> platform;
  final Map<String, int> cuisineCounts;
  final List<Map<String, dynamic>> topRestaurants;
  final List<Map<String, dynamic>> users;
  final int restaurantTotal;
  final int userTotal;

  Map<String, dynamic> get kpis => platform['kpis'] as Map<String, dynamic>? ?? {};
  List<dynamic> series(String key) => (platform['timeseries'] as Map?)?[key] as List? ?? [];
}
