import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/order.dart';

/// Timeline stages for premium delivery tracking UI.
enum DeliveryTimelineStage {
  orderPlaced,
  restaurantAccepted,
  preparing,
  riderAssigned,
  pickedUp,
  nearYou,
  delivered,
}

/// Live status chip shown above the map.
enum DeliveryLiveStatus {
  preparing,
  cooking,
  pickedUp,
  onTheWay,
  nearYou,
  delivered,
}

/// Demo rider profile when backend fields are unavailable.
class DeliveryRiderProfile {
  const DeliveryRiderProfile({
    required this.name,
    this.vehicle = 'Motorcycle',
    this.plateNumber = 'ISB-4821',
    this.rating = 4.9,
    this.completedDeliveries = 1240,
  });

  final String name;
  final String vehicle;
  final String plateNumber;
  final double rating;
  final int completedDeliveries;

  static DeliveryRiderProfile fromOrder(Order order) => DeliveryRiderProfile(
        name: order.riderName ?? 'Ahmed Khan',
      );
}

/// Map coordinates — swap [DeliveryCoordinates.demo] with live API data later.
class DeliveryCoordinates {
  const DeliveryCoordinates({
    required this.restaurant,
    required this.customer,
    required this.rider,
  });

  final LatLng restaurant;
  final LatLng customer;
  final LatLng rider;

  /// Islamabad demo route — replace with backend lat/lng when available.
  static DeliveryCoordinates demo({double routeProgress = 0.55}) {
    const restaurant = LatLng(33.6844, 73.0479);
    const customer = LatLng(33.7077, 73.0551);
    final rider = LatLng(
      restaurant.latitude + (customer.latitude - restaurant.latitude) * routeProgress,
      restaurant.longitude + (customer.longitude - restaurant.longitude) * routeProgress,
    );
    return DeliveryCoordinates(
      restaurant: restaurant,
      customer: customer,
      rider: rider,
    );
  }

  DeliveryCoordinates withRiderProgress(double progress) => DeliveryCoordinates(
        restaurant: restaurant,
        customer: customer,
        rider: LatLng(
          restaurant.latitude + (customer.latitude - restaurant.latitude) * progress,
          restaurant.longitude + (customer.longitude - restaurant.longitude) * progress,
        ),
      );
}

/// Simulated tracking state derived from order status + elapsed time.
class DeliveryTrackingSnapshot {
  const DeliveryTrackingSnapshot({
    required this.stage,
    required this.liveStatus,
    required this.remainingMinutes,
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.routeProgress,
    required this.canCancel,
  });

  final DeliveryTimelineStage stage;
  final DeliveryLiveStatus liveStatus;
  final int remainingMinutes;
  final double distanceKm;
  final double avgSpeedKmh;
  final double routeProgress;
  final bool canCancel;

  bool get isDelivered => stage == DeliveryTimelineStage.delivered;

  static DeliveryTrackingSnapshot fromOrder(Order order, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final placedAt = order.createdAt ?? clock.subtract(const Duration(minutes: 8));
    final elapsed = clock.difference(placedAt);

    final backendStage = _stageFromStatus(order.status);
    final simulatedStage = _simulatedStage(elapsed);
    final stage = _maxStage(backendStage, simulatedStage);

    final totalEtaMinutes = 27;
    final remaining = (totalEtaMinutes - elapsed.inMinutes).clamp(0, totalEtaMinutes);
    final progress = (elapsed.inMinutes / totalEtaMinutes).clamp(0.0, 1.0);

    return DeliveryTrackingSnapshot(
      stage: stage,
      liveStatus: _liveStatusForStage(stage),
      remainingMinutes: stage == DeliveryTimelineStage.delivered ? 0 : remaining,
      distanceKm: (2.4 * (1 - progress)).clamp(0.1, 2.4),
      avgSpeedKmh: 22,
      routeProgress: progress.clamp(0.15, 0.95),
      canCancel: stage.index < DeliveryTimelineStage.pickedUp.index,
    );
  }
}

DeliveryTimelineStage _stageFromStatus(String status) {
  final s = status.toLowerCase();
  if (s.contains('deliver')) return DeliveryTimelineStage.delivered;
  if (s.contains('near')) return DeliveryTimelineStage.nearYou;
  if (s.contains('pick')) return DeliveryTimelineStage.pickedUp;
  if (s.contains('rider') || s.contains('assign')) return DeliveryTimelineStage.riderAssigned;
  if (s.contains('prep') || s.contains('cook') || s.contains('ready')) {
    return DeliveryTimelineStage.preparing;
  }
  if (s.contains('accept') || s.contains('confirm')) return DeliveryTimelineStage.restaurantAccepted;
  if (s.contains('cancel')) return DeliveryTimelineStage.orderPlaced;
  return DeliveryTimelineStage.orderPlaced;
}

DeliveryTimelineStage _simulatedStage(Duration elapsed) {
  final m = elapsed.inMinutes;
  if (m >= 27) return DeliveryTimelineStage.delivered;
  if (m >= 22) return DeliveryTimelineStage.nearYou;
  if (m >= 18) return DeliveryTimelineStage.pickedUp;
  if (m >= 15) return DeliveryTimelineStage.riderAssigned;
  if (m >= 5) return DeliveryTimelineStage.preparing;
  if (m >= 2) return DeliveryTimelineStage.restaurantAccepted;
  return DeliveryTimelineStage.orderPlaced;
}

DeliveryTimelineStage _maxStage(DeliveryTimelineStage a, DeliveryTimelineStage b) {
  return a.index >= b.index ? a : b;
}

DeliveryLiveStatus _liveStatusForStage(DeliveryTimelineStage stage) {
  switch (stage) {
    case DeliveryTimelineStage.orderPlaced:
    case DeliveryTimelineStage.restaurantAccepted:
      return DeliveryLiveStatus.preparing;
    case DeliveryTimelineStage.preparing:
      return DeliveryLiveStatus.cooking;
    case DeliveryTimelineStage.riderAssigned:
      return DeliveryLiveStatus.preparing;
    case DeliveryTimelineStage.pickedUp:
      return DeliveryLiveStatus.pickedUp;
    case DeliveryTimelineStage.nearYou:
      return DeliveryLiveStatus.nearYou;
    case DeliveryTimelineStage.delivered:
      return DeliveryLiveStatus.delivered;
  }
}

/// Estimated order breakdown for expandable summary (UI demo when API lacks fields).
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
    const fee = 99.0;
    const taxRate = 0.05;
    final subtotal = (order.totalPrice - fee) / (1 + taxRate);
    final tax = subtotal * taxRate;
    return DeliveryOrderBreakdown(
      subtotal: subtotal,
      deliveryFee: fee,
      tax: tax,
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
