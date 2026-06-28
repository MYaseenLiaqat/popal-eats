import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recommendation.dart';
import '../models/restaurant.dart';
import '../providers/cart_provider.dart';
import '../providers/recommendation_provider.dart';
import '../services/restaurant_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/home/home_constants.dart';
import '../widgets/home/home_cuisine_strip.dart';
import '../widgets/home/home_dish_horizontal_card.dart';
import '../widgets/home/home_featured_restaurant_card.dart';
import '../widgets/home/home_promo_carousel.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/home_section_header.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'cart_screen.dart';
import 'dish_detail_screen.dart';
import 'restaurant_detail_screen.dart';

/// Food ordering hub — restaurants, dishes, and cart access.
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, this.isTabActive = false});

  final bool isTabActive;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _restaurants = RestaurantService();
  bool _activated = false;
  bool _loadingRestaurants = true;
  String? _restaurantError;
  List<Restaurant> _allRestaurants = [];

  @override
  void initState() {
    super.initState();
    _activateIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isTabActive && widget.isTabActive) {
      _activateIfNeeded();
    }
  }

  void _activateIfNeeded() {
    if (!widget.isTabActive || _activated) return;
    _activated = true;
    _load();
  }

  Future<void> _load({bool forceRec = false}) async {
    setState(() {
      _loadingRestaurants = true;
      _restaurantError = null;
    });

    final recFuture = context.read<RecommendationProvider>().fetchAll(force: forceRec);

    try {
      final raw = await _restaurants.list(limit: 40);
      final parsed = raw
          .whereType<Map<String, dynamic>>()
          .map(Restaurant.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _allRestaurants = parsed;
        _loadingRestaurants = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _restaurantError = RecommendationCopy.friendlyError(e);
        _loadingRestaurants = false;
      });
    }

    await recFuture;
  }

  void _openRestaurant(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurantId: id)),
    );
  }

  void _openDish(int dishId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DishDetailScreen(dishId: dishId)),
    );
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  int _matchPercent(Recommendation rec) {
    if (rec.score <= 10) {
      return (rec.score * 10).round().clamp(0, 100);
    }
    return rec.score.round().clamp(0, 100);
  }

  Widget _restaurantCarousel({
    required String title,
    required String subtitle,
    required List<Restaurant> items,
    required String heroScope,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        HomeSectionHeader(title: title, subtitle: subtitle, icon: Icons.storefront_outlined),
        SizedBox(
          height: 290,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final r = items[index];
              return HomeFeaturedRestaurantCard(
                restaurant: r,
                width: HomeConstants.carouselItemWidth(context),
                heroTag: '${heroScope}_restaurant_${r.id}',
                isFavorite: false,
                onTap: () => _openRestaurant(r.id),
                onFavoriteToggle: () {},
              );
            },
          ),
        ),
        const SizedBox(height: HomeConstants.sectionSpacing),
      ],
    );
  }

  Widget _recommendedDishesSection(RecommendationProvider rec) {
    if (rec.loadingPersonalized) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (rec.personalized.isEmpty) return const SizedBox.shrink();

    final cardWidth = HomeConstants.dishCardWidth(context);

    return Column(
      children: [
        HomeSectionHeader(
          title: 'Recommended for you',
          subtitle: '${rec.personalized.length} dishes picked for you',
          icon: Icons.auto_awesome_outlined,
        ),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rec.personalized.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = rec.personalized[index];
              return HomeDishHorizontalCard(
                recommendation: item,
                width: cardWidth,
                matchPercent: _matchPercent(item),
                onTap: () => _openDish(item.dishId),
              );
            },
          ),
        ),
        const SizedBox(height: HomeConstants.sectionSpacing),
      ],
    );
  }

  Widget _restaurantGrid(List<Restaurant> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'All restaurants',
          subtitle: '${items.length} places to order from',
          icon: Icons.grid_view_rounded,
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No restaurants available right now'),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = HomeConstants.gridColumns(context).clamp(1, 3);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final r = items[index];
                    return HomeFeaturedRestaurantCard(
                      restaurant: r,
                      width: constraints.maxWidth / columns,
                      heroTag: 'home_grid_restaurant_${r.id}',
                      isFavorite: false,
                      onTap: () => _openRestaurant(r.id),
                      onFavoriteToggle: () {},
                    );
                  },
                );
              },
            ),
          ),
        const SizedBox(height: HomeConstants.sectionSpacing),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final rec = context.watch<RecommendationProvider>();
    final popular = _allRestaurants.take(8).toList();
    final nearby = _allRestaurants.length > 8
        ? _allRestaurants.sublist(8, _allRestaurants.length.clamp(0, 16))
        : _allRestaurants.reversed.take(6).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order'),
        centerTitle: false,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: _openCart,
                tooltip: 'Cart',
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${cart.itemCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.onAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: !_activated
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: () => _load(forceRec: true),
              color: AppColors.accent,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  HomeSearchBar(onTap: () {}, onFilterTap: () {}),
                  HomeCuisineStrip(onCuisineTap: (_) {}),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: HomePromoCarousel(),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingRestaurants)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                    )
                  else if (_restaurantError != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          EmptyState(
                            icon: Icons.cloud_off_outlined,
                            title: 'Could not load restaurants',
                            subtitle: _restaurantError,
                          ),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    )
                  else ...[
                    _restaurantCarousel(
                      title: 'Popular restaurants',
                      subtitle: 'Top picks near you',
                      items: popular,
                      heroScope: 'home_popular',
                    ),
                    _restaurantCarousel(
                      title: 'Nearby',
                      subtitle: 'Delivering to your area',
                      items: nearby,
                      heroScope: 'home_nearby',
                    ),
                    _recommendedDishesSection(rec),
                    _restaurantGrid(_allRestaurants),
                  ],
                ],
              ),
            ),
    );
  }
}
