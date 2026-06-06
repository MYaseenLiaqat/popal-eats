import 'cart_item.dart';
import 'json_parse.dart';

/// Cart from `GET /cart` (`CartResponse`).
class Cart {
  const Cart({
    required this.id,
    required this.userId,
    required this.items,
    this.restaurantId,
    this.subtotal = 0,
    this.createdAt,
  });

  final int id;
  final int userId;
  final List<CartItem> items;
  final int? restaurantId;
  final double subtotal;
  final DateTime? createdAt;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(CartItem.fromJson)
            .toList()
        : <CartItem>[];

    return Cart(
      id: parseInt(json['id'], field: 'id'),
      userId: parseInt(json['user_id'], field: 'user_id'),
      items: items,
      restaurantId: parseIntOrNull(json['restaurant_id']),
      subtotal: parseDoubleOrNull(json['subtotal']) ?? 0,
      createdAt: parseDateTimeOrNull(json['created_at']),
    );
  }
}
