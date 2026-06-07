import 'dish.dart';
import 'json_parse.dart';

/// Line item from `CartItemResponse`.
class CartItem {
  const CartItem({
    required this.id,
    required this.cartId,
    required this.dishId,
    required this.quantity,
    this.createdAt,
    this.dish,
  });

  final int id;
  final int cartId;
  final int dishId;
  final int quantity;
  final DateTime? createdAt;
  final Dish? dish;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: parseInt(json['id'], field: 'id'),
        cartId: parseInt(json['cart_id'], field: 'cart_id'),
        dishId: parseInt(json['dish_id'], field: 'dish_id'),
        quantity: parseInt(json['quantity'], field: 'quantity'),
        createdAt: parseDateTimeOrNull(json['created_at']),
        dish: json['dish'] is Map<String, dynamic>
            ? Dish.fromJson(json['dish'] as Map<String, dynamic>)
            : null,
      );
}
