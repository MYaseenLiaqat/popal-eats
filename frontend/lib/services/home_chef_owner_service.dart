import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/order.dart';
import '../models/post.dart';
import '../models/restaurant.dart';
import '../models/restaurant_dashboard.dart';
import 'api_client.dart';
import 'restaurant_owner_service.dart';

/// Home chef operations — profile via /home-chef, recipes/orders via kitchen restaurant.
class HomeChefOwnerService {
  final _api = ApiClient.instance;
  final _kitchen = RestaurantOwnerService();

  Future<Map<String, dynamic>> getMe() async {
    final r = await _api.get('/home-chef/me');
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<int> kitchenRestaurantId() async {
    final me = await getMe();
    return me['kitchen_restaurant_id'] as int;
  }

  Future<RestaurantDashboard> dashboard() async {
    final r = await _api.get('/home-chef/dashboard');
    _api.throwIfError(r);
    return RestaurantDashboard.fromJson(_api.decodeJson(r));
  }

  Future<RestaurantDashboard> analytics() async {
    final r = await _api.get('/home-chef/analytics');
    _api.throwIfError(r);
    return RestaurantDashboard.fromJson(_api.decodeJson(r));
  }

  Future<List<Order>> listOrders({String? status, int skip = 0, int limit = 50}) async {
    final r = await _api.get('/home-chef/orders', query: {
      'skip': '$skip',
      'limit': '$limit',
      if (status != null) 'status': status,
    });
    _api.throwIfError(r);
    final parsed = jsonDecode(r.body);
    if (parsed is List) {
      return parsed.whereType<Map<String, dynamic>>().map(Order.fromJson).toList();
    }
    return [];
  }

  Future<Order> updateOrderStatus(int orderId, String status, {String? riderName}) =>
      _kitchen.updateOrderStatus(orderId, status, riderName: riderName);

  Future<List<Post>> listPosts({int page = 1, int limit = 20}) async {
    final r = await _api.get('/home-chef/posts', query: {
      'page': '$page',
      'limit': '$limit',
    });
    _api.throwIfError(r);
    final data = _api.decodeJson(r);
    final items = data['items'];
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final r = await _api.put('/home-chef/me/profile', body: body);
    _api.throwIfError(r);
    return _api.decodeJson(r);
  }

  Future<Map<String, dynamic>> uploadProfileImage({
    required List<int> bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/home-chef/me/profile/image');
    final request = http.MultipartRequest('POST', uri);
    final token = _api.accessToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamed);
    _api.throwIfError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Recipe CRUD — delegates to kitchen restaurant dish APIs.
  Future<List<dynamic>> listRecipes() async {
    final kitchenId = await kitchenRestaurantId();
    return _kitchen.listDishes(restaurantId: kitchenId);
  }

  RestaurantOwnerService get kitchenService => _kitchen;

  Future<Restaurant> kitchenAsRestaurant() async {
    final kitchenId = await kitchenRestaurantId();
    return _kitchen.getRestaurant(kitchenId);
  }
}
