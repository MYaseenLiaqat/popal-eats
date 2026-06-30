import '../../models/order.dart';



/// Timeline stages aligned with backend order status values.

enum DeliveryTimelineStage {

  orderPlaced,

  restaurantAccepted,

  preparing,

  ready,

  pickedUp,

  delivered,

}



/// Live status chip shown above the map.

enum DeliveryLiveStatus {

  placed,

  accepted,

  preparing,

  ready,

  pickedUp,

  delivered,

}



/// Order status snapshot — driven only by backend [Order.status].

class DeliveryTrackingSnapshot {

  const DeliveryTrackingSnapshot({

    required this.stage,

    required this.liveStatus,

    required this.statusLabel,

    required this.canCancel,

  });



  final DeliveryTimelineStage stage;

  final DeliveryLiveStatus liveStatus;

  final String statusLabel;

  final bool canCancel;



  bool get isDelivered => stage == DeliveryTimelineStage.delivered;



  static DeliveryTrackingSnapshot fromOrder(Order order) {

    final stage = _stageFromStatus(order.status);

    return DeliveryTrackingSnapshot(

      stage: stage,

      liveStatus: _liveStatusForStage(stage),

      statusLabel: _labelForStatus(order.status),

      canCancel: stage.index < DeliveryTimelineStage.pickedUp.index &&

          !order.status.toLowerCase().contains('cancel'),

    );

  }

}



DeliveryTimelineStage _stageFromStatus(String status) {

  final s = status.toLowerCase();

  if (s.contains('deliver')) return DeliveryTimelineStage.delivered;

  if (s.contains('pick')) return DeliveryTimelineStage.pickedUp;

  if (s.contains('way')) return DeliveryTimelineStage.pickedUp;

  if (s.contains('ready')) return DeliveryTimelineStage.ready;

  if (s.contains('prep') || s.contains('cook')) return DeliveryTimelineStage.preparing;

  if (s.contains('confirm') || s.contains('accept')) return DeliveryTimelineStage.restaurantAccepted;

  if (s.contains('cancel')) return DeliveryTimelineStage.orderPlaced;

  return DeliveryTimelineStage.orderPlaced;

}



String _labelForStatus(String status) {

  final s = status.toLowerCase();

  if (s.contains('deliver')) return 'Delivered';

  if (s.contains('pick')) return 'Picked up';

  if (s.contains('way')) return 'On the way';

  if (s.contains('ready')) return 'Ready for pickup';

  if (s.contains('prep') || s.contains('cook')) return 'Preparing your order';

  if (s.contains('confirm') || s.contains('accept')) return 'Restaurant accepted';

  if (s.contains('cancel')) return 'Cancelled';

  return 'Order placed';

}



DeliveryLiveStatus _liveStatusForStage(DeliveryTimelineStage stage) {

  switch (stage) {

    case DeliveryTimelineStage.orderPlaced:

      return DeliveryLiveStatus.placed;

    case DeliveryTimelineStage.restaurantAccepted:

      return DeliveryLiveStatus.accepted;

    case DeliveryTimelineStage.preparing:

      return DeliveryLiveStatus.preparing;

    case DeliveryTimelineStage.ready:

      return DeliveryLiveStatus.ready;

    case DeliveryTimelineStage.pickedUp:

      return DeliveryLiveStatus.pickedUp;

    case DeliveryTimelineStage.delivered:

      return DeliveryLiveStatus.delivered;

  }

}



/// Estimated order breakdown from order total (no fabricated delivery metrics).

class DeliveryOrderBreakdown {

  const DeliveryOrderBreakdown({

    required this.subtotal,

    required this.deliveryFee,

    required this.tax,

    required this.total,

    this.paymentMethod = 'Cash on delivery',

  });



  final double subtotal;

  final double deliveryFee;

  final double tax;

  final double total;

  final String paymentMethod;



  static DeliveryOrderBreakdown fromOrder(Order order) {

    return DeliveryOrderBreakdown(

      subtotal: order.totalPrice,

      deliveryFee: 0,

      tax: 0,

      total: order.totalPrice,

    );

  }

}



String formatOrderDate(DateTime? dt) {

  if (dt == null) return '—';

  final local = dt.toLocal();

  final months = [

    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',

    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',

  ];

  final h = local.hour.toString().padLeft(2, '0');

  final min = local.minute.toString().padLeft(2, '0');

  return '${months[local.month - 1]} ${local.day}, ${local.year} · $h:$min';

}



bool isOrderCompleted(Order order) =>

    order.status.toLowerCase().contains('deliver');



bool isOrderCancelled(Order order) =>
    order.status.toLowerCase().contains('cancel');

/// Legacy types for unused route/rider widgets (no demo coordinates).
class DeliveryRiderProfile {
  const DeliveryRiderProfile({
    required this.name,
    this.vehicle = '',
    this.plateNumber = '',
    this.rating = 0,
    this.completedDeliveries = 0,
  });
  final String name;
  final String vehicle;
  final String plateNumber;
  final double rating;
  final int completedDeliveries;
}

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class DeliveryCoordinates {
  const DeliveryCoordinates({
    required this.restaurant,
    required this.customer,
    required this.rider,
  });
  final GeoPoint restaurant;
  final GeoPoint customer;
  final GeoPoint rider;
}

