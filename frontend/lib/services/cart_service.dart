import '../models/cart.dart';
import '../models/cart_item.dart';
import 'api_client.dart';

/// Cart API client (`/cart/*`).
class CartService {
  final _api = ApiClient.instance;

  Future<Cart> getCart() async {
    final r = await _api.get('/cart');
    _api.throwIfError(r);
    return Cart.fromJson(_api.decodeJson(r));
  }

  Future<CartItem> addItem({
    required int dishId,
    required int quantity,
  }) async {
    final r = await _api.post('/cart/add', body: {
      'dish_id': dishId,
      'quantity': quantity,
    });
    _api.throwIfError(r);
    return CartItem.fromJson(_api.decodeJson(r));
  }

  Future<CartItem> updateItem({
    required int itemId,
    required int quantity,
  }) async {
    final r = await _api.put('/cart/items/$itemId', body: {
      'quantity': quantity,
    });
    _api.throwIfError(r);
    return CartItem.fromJson(_api.decodeJson(r));
  }

  Future<void> removeItem(int itemId) async {
    final r = await _api.delete('/cart/items/$itemId');
    _api.throwIfError(r);
  }

  Future<void> clearCart() async {
    final r = await _api.delete('/cart/clear');
    _api.throwIfError(r);
  }
}
