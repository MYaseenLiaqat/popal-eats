import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/recommendation.dart';
import '../models/restaurant.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/feed_image_loader.dart';
import '../services/recommendation_service.dart';
import '../services/restaurant_service.dart';
import '../theme/app_colors.dart';
import '../utils/price_formatter.dart';
import '../utils/recommendation_copy.dart';
import '../utils/user_display.dart';
import '../widgets/cart/cart_address_preview.dart';
import '../widgets/cart/cart_coupon_instructions.dart';
import '../widgets/cart/cart_item_card.dart';
import '../widgets/cart/cart_restaurant_summary.dart';
import '../widgets/cart/cart_summary_sections.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'checkout_screen.dart';
import 'main_shell.dart';

/// Cart contents with quantity controls (`CartProvider`).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _restaurants = RestaurantService();
  final _recommendations = RecommendationService();
  final _imageLoader = FeedImageLoader();
  final _instructionsController = TextEditingController();

  Restaurant? _restaurant;
  bool _restaurantLoading = false;
  List<Recommendation> _addons = [];
  Map<int, String?> _addonImages = {};
  bool _addonsLoading = false;
  final Set<int> _favoriteItems = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final cart = context.read<CartProvider>();
    await cart.load();
    if (!mounted) return;
    await _loadRestaurant(cart.cart?.restaurantId);
    await _loadAddons(cart.cart?.items ?? []);
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

  Future<void> _loadAddons(List<CartItem> items) async {
    setState(() => _addonsLoading = true);
    try {
      final list = await _recommendations.list();
      final inCart = items.map((i) => i.dishId).toSet();
      final filtered = list.where((r) => !inCart.contains(r.dishId)).take(8).toList();
      final images = await _imageLoader.loadImages(filtered.map((r) => r.dishId));
      if (!mounted) return;
      setState(() {
        _addons = filtered;
        _addonImages = images;
        _addonsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _addonsLoading = false);
    }
  }

  Future<void> _changeQuantity(CartItem item, int delta) async {
    final cart = context.read<CartProvider>();
    final next = item.quantity + delta;
    if (next < 1) {
      await cart.removeItem(item.id);
    } else {
      await cart.updateQuantity(item.id, next);
    }
    if (!mounted) return;
    _showCartError();
    await _loadAddons(cart.cart?.items ?? []);
  }

  Future<void> _removeItem(CartItem item) async {
    await context.read<CartProvider>().removeItem(item.id);
    if (!mounted) return;
    _showCartError();
    final items = context.read<CartProvider>().cart?.items ?? [];
    await _loadAddons(items);
  }

  Future<void> _addAddon(int dishId) async {
    final ok = await context.read<CartProvider>().addItem(dishId: dishId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart')),
      );
      await _loadAddons(context.read<CartProvider>().cart?.items ?? []);
    } else {
      _showCartError();
    }
  }

  void _showCartError() {
    final err = context.read<CartProvider>().error;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  void _browseRestaurants() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.findAncestorStateOfType<MainShellState>()?.navigateToTab(MainShellState.orderTab);
  }

  void _goCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final items = cart.cart?.items ?? [];
    final address = UserDisplay.cityLine(auth.user?['city']?.toString());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Cart'),
        centerTitle: false,
      ),
      body: cart.loading && items.isEmpty
          ? const CartLoadingSkeleton()
          : cart.error != null && items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Could not load cart',
                          subtitle: RecommendationCopy.friendlyError(cart.error),
                        ),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _bootstrap, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : items.isEmpty
                  ? CartEmptyState(onBrowse: _browseRestaurants)
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _bootstrap,
                            color: AppColors.accent,
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: 24),
                              children: [
                                CartAddressPreview(
                                  address: address,
                                  onEdit: _goCheckout,
                                ),
                                CartRestaurantSummary(
                                  restaurant: _restaurant,
                                  loading: _restaurantLoading,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                                  child: Text(
                                    'Your items',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...items.map((item) {
                                  return CartItemCard(
                                    item: item,
                                    enabled: !cart.loading,
                                    isFavorite: _favoriteItems.contains(item.id),
                                    onDecrease: () => _changeQuantity(item, -1),
                                    onIncrease: () => _changeQuantity(item, 1),
                                    onRemove: () => _removeItem(item),
                                    onFavoriteToggle: () {
                                      setState(() {
                                        if (_favoriteItems.contains(item.id)) {
                                          _favoriteItems.remove(item.id);
                                        } else {
                                          _favoriteItems.add(item.id);
                                        }
                                      });
                                    },
                                  );
                                }),
                                const CartCouponSection(),
                                CartInstructionsField(controller: _instructionsController),
                                CartAddonsSection(
                                  items: _addons,
                                  dishImages: _addonImages,
                                  loading: _addonsLoading,
                                  onAdd: _addAddon,
                                ),
                                CartOrderSummary(
                                  subtotal: cart.subtotal,
                                  itemCount: cart.itemCount,
                                ),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                        CartCheckoutCta(
                          totalLabel: PriceFormatter.format(cart.subtotal),
                          enabled: !cart.isEmpty && !cart.loading,
                          onCheckout: _goCheckout,
                        ),
                      ],
                    ),
    );
  }
}
