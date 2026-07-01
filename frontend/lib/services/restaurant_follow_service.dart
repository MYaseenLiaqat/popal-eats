import '../models/restaurant.dart';
import 'api_client.dart';

class RestaurantFollowList {
  const RestaurantFollowList({
    required this.restaurantIds,
    required this.restaurants,
    required this.total,
  });

  final List<int> restaurantIds;
  final List<Restaurant> restaurants;
  final int total;

  factory RestaurantFollowList.fromJson(Map<String, dynamic> json) {
    final idsRaw = json['restaurant_ids'];
    final restaurantsRaw = json['restaurants'];
    return RestaurantFollowList(
      restaurantIds: idsRaw is List
          ? idsRaw.map((e) => int.tryParse('$e') ?? 0).where((id) => id > 0).toList()
          : const [],
      restaurants: restaurantsRaw is List
          ? restaurantsRaw
              .whereType<Map>()
              .map((e) => Restaurant.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      total: int.tryParse('${json['total']}') ?? 0,
    );
  }
}

class RestaurantFollowService {
  RestaurantFollowService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<RestaurantFollowList> getFollowing() async {
    final response = await _client.get('/restaurants/following');
    _client.throwIfError(response);
    return RestaurantFollowList.fromJson(_client.decodeJson(response));
  }

  Future<RestaurantFollowList> follow(int restaurantId) async {
    final response = await _client.post('/restaurants/$restaurantId/follow');
    _client.throwIfError(response);
    return RestaurantFollowList.fromJson(_client.decodeJson(response));
  }

  Future<RestaurantFollowList> unfollow(int restaurantId) async {
    final response = await _client.delete('/restaurants/$restaurantId/follow');
    _client.throwIfError(response);
    return RestaurantFollowList.fromJson(_client.decodeJson(response));
  }
}
