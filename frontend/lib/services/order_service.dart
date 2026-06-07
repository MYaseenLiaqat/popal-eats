import 'dart:convert';

import '../models/order.dart';
import 'api_client.dart';

/// Checkout and order history APIs.
class OrderService {
  final _api = ApiClient.instance;

  Future<Order> checkout({required String deliveryAddress}) async {
    final r = await _api.post('/checkout', body: {
      'delivery_address': deliveryAddress,
    });
    _api.throwIfError(r);
    return Order.fromJson(_api.decodeJson(r));
  }

  Future<List<Order>> myOrders({int skip = 0, int limit = 50}) async {
    final r = await _api.get('/orders/my-orders', query: {
      'skip': '$skip',
      'limit': '$limit',
    });
    _api.throwIfError(r);
    return _parseOrderList(r.body);
  }

  Future<Order> getById(int orderId) async {
    final r = await _api.get('/orders/$orderId');
    _api.throwIfError(r);
    return Order.fromJson(_api.decodeJson(r));
  }

  List<Order> _parseOrderList(String body) {
    if (body.isEmpty) return [];
    final parsed = jsonDecode(body);
    if (parsed is List) {
      return parsed
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();
    }
    if (parsed is Map && parsed['items'] is List) {
      return (parsed['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();
    }
    return [];
  }
}
