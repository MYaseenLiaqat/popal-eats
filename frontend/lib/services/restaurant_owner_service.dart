import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/dish.dart';
import '../models/order.dart';
import '../models/post.dart';
import '../models/restaurant.dart';
import '../models/restaurant_dashboard.dart';
import 'api_client.dart';

/// Restaurant owner operations — dashboard, my restaurants, dish CRUD, orders.
class RestaurantOwnerService {
  final _api = ApiClient.instance;

  Future<List<Restaurant>> listMine({int page = 1, int limit = 20}) async {
    final r = await _api.get('/restaurants/mine', query: {
      'page': '$page',
      'limit': '$limit',
    });
    _api.throwIfError(r);
    return _api
        .decodeList(r)
        .whereType<Map>()
        .map((e) => Restaurant.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Restaurant> getRestaurant(int restaurantId) async {
    final r = await _api.get('/restaurants/$restaurantId');
    _api.throwIfError(r);
    return Restaurant.fromJson(_api.decodeJson(r));
  }

  Future<Restaurant> createRestaurant(Map<String, dynamic> body) async {
    final r = await _api.post('/restaurants', body: body);
    _api.throwIfError(r);
    return Restaurant.fromJson(_api.decodeJson(r));
  }

  Future<Restaurant> updateRestaurant(int restaurantId, Map<String, dynamic> body) async {
    final r = await _api.put('/restaurants/$restaurantId', body: body);
    _api.throwIfError(r);
    return Restaurant.fromJson(_api.decodeJson(r));
  }

  Future<RestaurantDashboard> dashboard(int restaurantId) async {
    final r = await _api.get('/restaurants/$restaurantId/dashboard');
    _api.throwIfError(r);
    return RestaurantDashboard.fromJson(_api.decodeJson(r));
  }

  Future<RestaurantDashboard> analytics(int restaurantId) async {
    final r = await _api.get('/restaurants/$restaurantId/analytics');
    _api.throwIfError(r);
    return RestaurantDashboard.fromJson(_api.decodeJson(r));
  }

  Future<List<Order>> listOrders({
    required int restaurantId,
    String? status,
    int skip = 0,
    int limit = 50,
  }) async {
    final r = await _api.get('/restaurants/$restaurantId/orders', query: {
      'skip': '$skip',
      'limit': '$limit',
      if (status != null) 'status': status,
    });
    _api.throwIfError(r);
    final parsed = jsonDecode(r.body);
    if (parsed is List) {
      return parsed
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();
    }
    return [];
  }

  Future<Order> updateOrderStatus(int orderId, String status, {String? riderName}) async {
    final r = await _api.put('/orders/$orderId/status', body: {
      'status': status,
      if (riderName != null) 'rider_name': riderName,
    });
    _api.throwIfError(r);
    return Order.fromJson(_api.decodeJson(r));
  }

  Future<List<Post>> listPosts({
    required int restaurantId,
    int page = 1,
    int limit = 20,
  }) async {
    final r = await _api.get('/restaurants/$restaurantId/posts', query: {
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

  Future<Dish> createDish(Map<String, dynamic> body) async {
    final r = await _api.post('/dishes', body: body);
    _api.throwIfError(r);
    return Dish.fromJson(_api.decodeJson(r));
  }

  Future<Dish> updateDish(int dishId, Map<String, dynamic> body) async {
    final r = await _api.put('/dishes/$dishId', body: body);
    _api.throwIfError(r);
    return Dish.fromJson(_api.decodeJson(r));
  }

  Future<void> deleteDish(int dishId) async {
    final r = await _api.delete('/dishes/$dishId');
    _api.throwIfError(r);
  }

  Future<List<Dish>> listDishes({
    required int restaurantId,
    int page = 1,
    int limit = 100,
  }) async {
    final r = await _api.get('/dishes', query: {
      'page': '$page',
      'limit': '$limit',
      'restaurant_id': '$restaurantId',
    });
    _api.throwIfError(r);
    return _api
        .decodeList(r)
        .whereType<Map>()
        .map((e) => Dish.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Dish> uploadDishImage({
    required int dishId,
    required List<int> bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/dishes/$dishId/image');
    final request = http.MultipartRequest('POST', uri);
    final token = _api.accessToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamed);
    _api.throwIfError(response);
    return Dish.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Restaurant> uploadRestaurantImage({
    required int restaurantId,
    required List<int> bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/restaurants/$restaurantId/image');
    final request = http.MultipartRequest('POST', uri);
    final token = _api.accessToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamed);
    _api.throwIfError(response);
    return Restaurant.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
