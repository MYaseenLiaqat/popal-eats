import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/restaurant.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';
import '../services/restaurant_service.dart';
import '../theme/app_colors.dart';
import '../utils/price_formatter.dart';
import '../utils/recommendation_copy.dart';
import '../utils/user_display.dart';
import '../widgets/checkout/checkout_constants.dart';
import '../widgets/checkout/checkout_header_sections.dart';
import '../widgets/checkout/checkout_sections.dart';
import 'order_success_screen.dart';

/// Checkout with delivery address (`POST /checkout`).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _orders = OrderService();
  final _restaurants = RestaurantService();
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _addressFocus = FocusNode();

  Restaurant? _restaurant;
  bool _restaurantLoading = false;
  bool _bootstrapping = true;
  bool placing = false;
  String? error;
  CheckoutPaymentMethod _paymentMethod = CheckoutPaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _bootstrapping = true);
    final cart = context.read<CartProvider>();
    await cart.load();
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final city = UserDisplay.cityLine(auth.user?['city']?.toString());
    if (city != null && _addressController.text.trim().isEmpty) {
      _addressController.text = city;
    }

    await _loadRestaurant(cart.cart?.restaurantId);
    if (!mounted) return;
    setState(() => _bootstrapping = false);
  }

  Future<void> _loadRestaurant(int? restaurantId) async {
    if (restaurantId == null) {
      setState(() => _restaurant = null);
      return;
    }
    setState(() => _restaurantLoading = true);
    try {
      final r = await _restaurants.getById(restaurantId);
      if (!mounted) return;
      setState(() {
        _restaurant = r;
        _restaurantLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _restaurantLoading = false);
    }
  }

  Future<void> _placeOrder() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() => error = 'Enter a delivery address');
      _addressFocus.requestFocus();
      return;
    }

    setState(() {
      placing = true;
      error = null;
    });

    try {
      final order = await _orders.checkout(deliveryAddress: address);
      if (!mounted) return;
      await context.read<CartProvider>().clear();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: CheckoutConstants.animDuration,
          reverseTransitionDuration: CheckoutConstants.animDuration,
          pageBuilder: (_, __, ___) => OrderSuccessScreen(order: order),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: CheckoutConstants.animCurve),
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
                  CurvedAnimation(parent: animation, curve: CheckoutConstants.animCurve),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        error = RecommendationCopy.friendlyError(e);
        placing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = RecommendationCopy.friendlyError(e);
        placing = false;
      });
    }
  }

  void _focusAddress() => _addressFocus.requestFocus();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final items = cart.cart?.items ?? [];
    final recipientName = auth.user?['full_name']?.toString().trim();
    final phone = auth.user?['phone']?.toString().trim();
    final restaurantName = _restaurant?.name;
    final orderPreview = items.isEmpty ? null : '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'} · ${PriceFormatter.format(cart.subtotal)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: false,
      ),
      body: _bootstrapping || (cart.loading && items.isEmpty)
          ? const CheckoutLoadingSkeleton()
          : cart.error != null && items.isEmpty
              ? CheckoutNetworkError(
                  message: RecommendationCopy.friendlyError(cart.error),
                  onRetry: _bootstrap,
                )
              : items.isEmpty
                  ? CheckoutEmptyState(onBack: () => Navigator.pop(context))
                  : Column(
                      children: [
                        Expanded(
                          child: RepaintBoundary(
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: 16),
                              children: [
                                CheckoutHeader(
                                  restaurantName: _restaurantLoading
                                      ? 'Loading restaurant…'
                                      : restaurantName,
                                  orderPreview: orderPreview,
                                ),
                                CheckoutAddressCard(
                                  controller: _addressController,
                                  focusNode: _addressFocus,
                                  recipientName: recipientName?.isNotEmpty == true
                                      ? recipientName
                                      : auth.user?['username']?.toString(),
                                  phone: phone,
                                  enabled: !placing,
                                  error: error,
                                  onEditFocus: _focusAddress,
                                ),
                                const CheckoutDeliveryEta(),
                                CheckoutPaymentSection(
                                  selected: _paymentMethod,
                                  enabled: !placing,
                                  onSelected: (method) => setState(() => _paymentMethod = method),
                                ),
                                const CheckoutPromoSection(),
                                CheckoutInstructionsField(
                                  controller: _instructionsController,
                                  enabled: !placing,
                                ),
                                CheckoutOrderReview(
                                  restaurantName: restaurantName,
                                  items: items,
                                ),
                                CheckoutOrderSummary(
                                  subtotal: cart.subtotal,
                                  itemCount: cart.itemCount,
                                ),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                        CheckoutPlaceOrderCta(
                          totalLabel: PriceFormatter.format(cart.subtotal),
                          loading: placing,
                          enabled: !placing,
                          onPressed: _placeOrder,
                        ),
                      ],
                    ),
    );
  }
}
