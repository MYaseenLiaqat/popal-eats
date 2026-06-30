import 'dart:async';

import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/restaurant.dart';
import '../services/dish_service.dart';
import '../services/order_service.dart';
import '../services/restaurant_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/delivery/delivery_action_buttons.dart';
import '../widgets/delivery/delivery_constants.dart';
import '../widgets/delivery/delivery_empty_state.dart';
import '../widgets/delivery/delivery_eta_card.dart';
import '../widgets/delivery/delivery_header.dart';
import '../widgets/delivery/delivery_history_card.dart';
import '../widgets/delivery/delivery_loading_skeleton.dart';
import '../widgets/delivery/delivery_order_summary.dart';
import '../widgets/delivery/delivery_status_card.dart';
import '../widgets/delivery/delivery_success_overlay.dart';
import '../widgets/delivery/delivery_timeline.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'main_shell.dart';
import 'order_detail_screen.dart';
import 'restaurant_detail_screen.dart';

/// Premium delivery tracking hub — Foodpanda / Uber Eats style.
class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key, this.isTabActive = false});

  final bool isTabActive;

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _orderService = OrderService();
  final _restaurants = RestaurantService();
  final _dishes = DishService();

  bool _activated = false;
  bool _loading = true;
  String? _error;
  List<Order> _orderList = [];
  final Map<int, Restaurant> _restaurantsById = {};
  final Map<int, Map<int, String>> _dishLabelsByOrder = {};

  Timer? _tickTimer;
  DeliveryTrackingSnapshot? _snapshot;
  int? _celebratedOrderId;

  @override
  void initState() {
    super.initState();
    _activateIfNeeded();
  }

  @override
  void didUpdateWidget(covariant DeliveryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isTabActive && widget.isTabActive) {
      _activateIfNeeded();
    }
    if (oldWidget.isTabActive && !widget.isTabActive) {
      _stopTicker();
    }
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  void _activateIfNeeded() {
    if (!widget.isTabActive) return;
    if (!_activated) _activated = true;
    _load();
    _startTicker();
  }

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted || _activeOrder == null) return;
      _load();
    });
  }

  void _stopTicker() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _orderService.myOrders();
      final restaurants = <int, Restaurant>{};
      final dishLabels = <int, Map<int, String>>{};

      for (final order in list) {
        if (!restaurants.containsKey(order.restaurantId)) {
          try {
            restaurants[order.restaurantId] =
                await _restaurants.getById(order.restaurantId);
          } catch (_) {
            restaurants[order.restaurantId] = Restaurant(
              id: order.restaurantId,
              name: 'Restaurant #${order.restaurantId}',
            );
          }
        }

        final labels = <int, String>{};
        for (final item in order.items) {
          if (labels.containsKey(item.dishId)) continue;
          try {
            final dish = await _dishes.getById(item.dishId);
            labels[item.dishId] = dish.name;
          } catch (_) {
            labels[item.dishId] = 'Menu item';
          }
        }
        dishLabels[order.id] = labels;
      }

      if (!mounted) return;
      Order? active;
      for (final o in list) {
        if (o.isActive) {
          active = o;
          break;
        }
      }
      setState(() {
        _orderList = list;
        _restaurantsById
          ..clear()
          ..addAll(restaurants);
        _dishLabelsByOrder
          ..clear()
          ..addAll(dishLabels);
        _loading = false;
        _snapshot = active != null ? DeliveryTrackingSnapshot.fromOrder(active) : null;
      });

      if (active != null && _snapshot != null) {
        _maybeCelebrate(active, _snapshot!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = RecommendationCopy.friendlyError(e);
        _loading = false;
      });
    }
  }

  Order? get _activeOrder {
    for (final o in _orderList) {
      if (o.isActive) return o;
    }
    return null;
  }

  List<Order> get _completedOrders =>
      _orderList.where(isOrderCompleted).toList();

  List<Order> get _cancelledOrders =>
      _orderList.where(isOrderCancelled).toList();

  void _maybeCelebrate(Order order, DeliveryTrackingSnapshot snap) {
    if (!snap.isDelivered || _celebratedOrderId == order.id) return;
    _celebratedOrderId = order.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DeliverySuccessOverlay.show(
        context,
        order: order,
        restaurantName: _restaurantName(order),
        onRateFood: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailScreen(restaurantId: order.restaurantId),
            ),
          );
        },
        onRateDelivery: () {
          Navigator.of(context).pop();
          _openOrderDetail(order.id);
        },
        onOrderAgain: () {
          Navigator.of(context).pop();
          _reorder(order);
        },
        onGoHome: () {
          Navigator.of(context).pop();
          context.findAncestorStateOfType<MainShellState>()?.navigateToTab(MainShellState.homeTab);
        },
      );
    });
  }

  void _showDeliveryHelp(Order order) {
    final restaurant = _restaurantsById[order.restaurantId];
    final phone = restaurant?.phoneNumber?.trim();
    final message = phone != null && phone.isNotEmpty
        ? 'Contact $phone for delivery updates.'
        : 'Open order details or visit the restaurant page for support.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goOrderTab() {
    context.findAncestorStateOfType<MainShellState>()?.navigateToTab(MainShellState.orderTab);
  }

  void _openOrderDetail(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: id)),
    );
  }

  void _reorder(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(restaurantId: order.restaurantId),
      ),
    );
  }

  String _restaurantName(Order order) =>
      _restaurantsById[order.restaurantId]?.name ?? 'Restaurant #${order.restaurantId}';

  String? _restaurantImage(Order order) => _restaurantsById[order.restaurantId]?.image;

  String _statusLabel(DeliveryTrackingSnapshot snap) => snap.statusLabel;

  @override
  Widget build(BuildContext context) {
    final active = _activeOrder;
    final snap = _snapshot;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DeliveryHeader(onRefresh: _load),
      body: !_activated
          ? const DeliveryLoadingSkeleton()
          : _loading
              ? const DeliveryLoadingSkeleton()
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EmptyState(
                              icon: Icons.cloud_off_outlined,
                              title: 'Could not load deliveries',
                              subtitle: _error,
                            ),
                            TextButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accent,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          if (active != null && snap != null)
                            SliverToBoxAdapter(
                              child: _ActiveOrderView(
                                order: active,
                                snapshot: snap,
                                restaurantName: _restaurantName(active),
                                restaurantImageUrl: _restaurantImage(active),
                                statusLabel: _statusLabel(snap),
                                itemLabels: _dishLabelsByOrder[active.id] ?? {},
                                breakdown: DeliveryOrderBreakdown.fromOrder(active),
                                isWide: isWide,
                                onNeedHelp: () => _showDeliveryHelp(active),
                                onReportIssue: () => _openOrderDetail(active.id),
                              ),
                            )
                          else
                            SliverToBoxAdapter(
                              child: DeliveryEmptyState(onBrowseRestaurants: _goOrderTab),
                            ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppColors.screenPadding,
                              8,
                              AppColors.screenPadding,
                              24,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                if (_completedOrders.isNotEmpty) ...[
                                  const DeliverySectionTitle(
                                    title: 'Completed Orders',
                                    subtitle: 'Your past deliveries',
                                    icon: Icons.check_circle_outline,
                                  ),
                                  ..._completedOrders.map(
                                    (order) => DeliveryHistoryCard(
                                      order: order,
                                      restaurantName: _restaurantName(order),
                                      restaurantImageUrl: _restaurantImage(order),
                                      onViewDetails: () => _openOrderDetail(order.id),
                                      onReorder: () => _reorder(order),
                                    ),
                                  ),
                                ],
                                if (_cancelledOrders.isNotEmpty) ...[
                                  const DeliverySectionTitle(
                                    title: 'Cancelled Orders',
                                    subtitle: 'Orders that did not complete',
                                    icon: Icons.cancel_outlined,
                                  ),
                                  ..._cancelledOrders.map(
                                    (order) => DeliveryHistoryCard(
                                      order: order,
                                      restaurantName: _restaurantName(order),
                                      restaurantImageUrl: _restaurantImage(order),
                                      onViewDetails: () => _openOrderDetail(order.id),
                                    ),
                                  ),
                                ],
                                if (_orderList.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(
                                      'No order history yet',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _ActiveOrderView extends StatelessWidget {
  const _ActiveOrderView({
    required this.order,
    required this.snapshot,
    required this.restaurantName,
    this.restaurantImageUrl,
    required this.statusLabel,
    required this.itemLabels,
    required this.breakdown,
    required this.isWide,
    required this.onNeedHelp,
    required this.onReportIssue,
  });

  final Order order;
  final DeliveryTrackingSnapshot snapshot;
  final String restaurantName;
  final String? restaurantImageUrl;
  final String statusLabel;
  final Map<int, String> itemLabels;
  final DeliveryOrderBreakdown breakdown;
  final bool isWide;
  final VoidCallback onNeedHelp;
  final VoidCallback onReportIssue;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.fromLTRB(
      AppColors.screenPadding,
      8,
      AppColors.screenPadding,
      0,
    );

    if (isWide) {
      return Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  DeliveryStatusCard(
                    order: order,
                    restaurantName: restaurantName,
                    restaurantImageUrl: restaurantImageUrl,
                    snapshot: snapshot,
                    countdownLabel: statusLabel,
                  ),
                  const SizedBox(height: 16),
                  DeliveryTimeline(current: snapshot.stage),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  DeliveryEtaCard(snapshot: snapshot),
                  const SizedBox(height: 16),
                  DeliveryOrderSummary(
                    order: order,
                    restaurantName: restaurantName,
                    itemLabels: itemLabels,
                    breakdown: breakdown,
                  ),
                  const SizedBox(height: 16),
                  DeliveryActionButtons(
                    canCancel: snapshot.canCancel,
                    riderFeaturesEnabled: false,
                    onNeedHelp: onNeedHelp,
                    onReportIssue: onReportIssue,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Column(
        children: [
          DeliveryStatusCard(
            order: order,
            restaurantName: restaurantName,
            restaurantImageUrl: restaurantImageUrl,
            snapshot: snapshot,
            countdownLabel: statusLabel,
          ),
          const SizedBox(height: 16),
          DeliveryEtaCard(snapshot: snapshot),
          const SizedBox(height: 16),
          DeliveryTimeline(current: snapshot.stage),
          const SizedBox(height: 16),
          DeliveryOrderSummary(
            order: order,
            restaurantName: restaurantName,
            itemLabels: itemLabels,
            breakdown: breakdown,
          ),
          const SizedBox(height: 16),
          DeliveryActionButtons(
            canCancel: snapshot.canCancel,
            riderFeaturesEnabled: false,
            onNeedHelp: onNeedHelp,
            onReportIssue: onReportIssue,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}