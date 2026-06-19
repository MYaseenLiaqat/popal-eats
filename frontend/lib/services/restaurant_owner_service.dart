import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/dish.dart';
import '../models/restaurant.dart';
import '../models/restaurant_dashboard.dart';
import 'api_client.dart';

/// Restaurant owner operations — dashboard, my restaurants, dish CRUD.
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

  Future<Restaurant> createRestaurant(Map<String, dynamic> body) async {
    final r = await _api.post('/restaurants', body: body);
    _api.throwIfError(r);
    return Restaurant.fromJson(_api.decodeJson(r));
  }

  Future<RestaurantDashboard> dashboard(int restaurantId) async {
    final r = await _api.get('/restaurants/$restaurantId/dashboard');
    _api.throwIfError(r);
    return RestaurantDashboard.fromJson(_api.decodeJson(r));
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
}
