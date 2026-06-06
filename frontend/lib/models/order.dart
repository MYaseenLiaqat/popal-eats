import 'json_parse.dart';

/// Single line on an order (`OrderItemResponse`).
class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.dishId,
    required this.quantity,
    required this.price,
    this.createdAt,
  });

  final int id;
  final int orderId;
  final int dishId;
  final int quantity;
  final double price;
  final DateTime? createdAt;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: parseInt(json['id'], field: 'id'),
        orderId: parseInt(json['order_id'], field: 'order_id'),
        dishId: parseInt(json['dish_id'], field: 'dish_id'),
        quantity: parseInt(json['quantity'], field: 'quantity'),
        price: parseDouble(json['price'], field: 'price'),
        createdAt: parseDateTimeOrNull(json['created_at']),
      );
}

/// Order from `OrderResponse` / checkout.
class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    required this.deliveryAddress,
    required this.items,
    this.riderName,
    this.createdAt,
  });

  final int id;
  final int userId;
  final int restaurantId;
  final double totalPrice;
  final String status;
  final String paymentStatus;
  final String deliveryAddress;
  final List<OrderItem> items;
  final String? riderName;
  final DateTime? createdAt;

  bool get isActive =>
      !const {'delivered', 'cancelled'}.contains(status.toLowerCase());

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(OrderItem.fromJson)
            .toList()
        : <OrderItem>[];

    return Order(
      id: parseInt(json['id'], field: 'id'),
      userId: parseInt(json['user_id'], field: 'user_id'),
      restaurantId: parseInt(json['restaurant_id'], field: 'restaurant_id'),
      totalPrice: parseDouble(json['total_price'], field: 'total_price'),
      status: parseString(json['status'], fallback: 'pending'),
      paymentStatus: parseString(json['payment_status'], fallback: 'pending'),
      deliveryAddress: parseString(json['delivery_address']),
      items: items,
      riderName: json['rider_name']?.toString(),
      createdAt: parseDateTimeOrNull(json['created_at']),
    );
  }
}
