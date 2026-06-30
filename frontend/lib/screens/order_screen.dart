import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recommendation.dart';
import '../models/restaurant.dart';
import '../providers/cart_provider.dart';
import '../providers/recommendation_provider.dart';
import '../services/restaurant_service.dart';
import '../theme/app_colors.dart';
import '../utils/order_recommendation_utils.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/home/home_constants.dart';
import '../widgets/home/home_cuisine_strip.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/home_section_header.dart';
import '../widgets/restaurant/restaurant_dish_card.dart';
import '../widgets/ui/app_ui_widgets.dart';
import '../data/cuisine_catalog.dart';
import '../services/dish_service.dart';
import '../models/dish.dart';
import 'cart_screen.dart';
import 'dish_detail_screen.dart';

/// AI-powered ordering hub — hybrid recommendation sections (not a static catalogue).
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, this.isTabActive = false});

  final bool isTabActive;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _restaurants = RestaurantService();
  final _dishes = DishService();
  final _searchController = TextEditingController();
  Timer? _dishSearchDebounce;

  bool _activated = false;
  String? _restaurantError;
  List<Restaurant> _catalogRestaurants = [];
  List<Dish> _searchDishes = [];
  String _searchQuery = '';
  String? _selectedCuisineKey;
  String? _selectedCuisineName;
  List<Dish> _cuisineDishes = [];
  bool _loadingCuisineDishes = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text;
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
        _scheduleDishSearch(q);
      }
    });
    _activateIfNeeded();
  }

  @override
  void dispose() {
    _dishSearchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartProvider>().load();
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _restaurantError = null);

    final recProvider = context.read<RecommendationProvider>();
    try {
      await Future.wait([
        recProvider.fetchPersonalized(force: true),
        recProvider.refreshTrending(),
        _fetchRestaurants(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() => _restaurantError = RecommendationCopy.friendlyError(e));
      }
    }

    if (!mounted) return;
    await _refreshDishMatches(_searchQuery);
  }

  Future<void> _retryRecommendations() async {
    final recProvider = context.read<RecommendationProvider>();
    await Future.wait([
      recProvider.fetchPersonalized(force: true),
      recProvider.refreshTrending(),
    ]);
  }

  Future<void> _fetchRestaurants() async {
    final raw = await _restaurants.list(limit: 60);
    final parsed = raw
        .whereType<Map<String, dynamic>>()
        .map(Restaurant.fromJson)
        .toList();
    if (!mounted) return;
    setState(() => _catalogRestaurants = parsed);
  }

  void _scheduleDishSearch(String query) {
    _dishSearchDebounce?.cancel();
    _dishSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      _refreshDishMatches(query);
    });
  }

  Future<void> _refreshDishMatches(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      if (mounted) setState(() => _searchDishes = []);
      return;
    }

    final visible = _visibleRestaurants;
    final dishMatches = <Dish>[];
    for (final r in visible.take(15)) {
      try {
        final menu = await _dishes.list(restaurantId: r.id, limit: 30);
        for (final raw in menu) {
          if (raw is! Map<String, dynamic>) continue;
          final d = Dish.fromJson(raw);
          final name = d.name.toLowerCase();
          if (name.contains(needle)) dishMatches.add(d);
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _searchDishes = dishMatches.take(12).toList());
  }

  List<Restaurant> get _visibleRestaurants {
    var list = OrderRecommendationUtils.filterByCuisine(
      _catalogRestaurants,
      _selectedCuisineKey,
    );
    list = OrderRecommendationUtils.filterBySearch(list, _searchQuery);
    return list;
  }

  void _onCuisineTap(CuisineDefinition? cuisine) {
    setState(() {
      _selectedCuisineKey = cuisine?.key;
      _selectedCuisineName = cuisine?.name;
      if (cuisine == null) {
        _cuisineDishes = [];
        _loadingCuisineDishes = false;
      }
    });
    _scheduleDishSearch(_searchQuery);
    if (cuisine != null) {
      _loadCuisineDishes(cuisine.key);
    }
  }

  Future<void> _loadCuisineDishes(String cuisineKey) async {
    setState(() => _loadingCuisineDishes = true);
    final restaurants = OrderRecommendationUtils.filterByCuisine(
      _catalogRestaurants,
      cuisineKey,
    );
    final dishes = <Dish>[];
    for (final r in restaurants.take(10)) {
      try {
        final menu = await _dishes.list(restaurantId: r.id, limit: 25);
        for (final raw in menu) {
          if (raw is! Map<String, dynamic>) continue;
          final d = Dish.fromJson(raw);
          if (OrderRecommendationUtils.dishMatchesCuisine(d, cuisineKey)) {
            dishes.add(d);
          }
        }
      } catch (_) {}
    }
    if (!mounted || _selectedCuisineKey != cuisineKey) return;
    setState(() {
      _cuisineDishes = dishes.take(12).toList();
      _loadingCuisineDishes = false;
    });
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  String _formatExplanation(Recommendation rec) {
    if (rec.explanationBullets.isNotEmpty) {
      return rec.explanationBullets.take(2).join(' · ');
    }
    return rec.explanation;
  }

  Widget _dishSection(String title, String subtitle, List<Recommendation> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(title: title, subtitle: subtitle, icon: Icons.auto_awesome),
        ...items.map((rec) {
          final dish = Dish(
            id: rec.dishId,
            name: rec.dishName,
            price: rec.price,
            restaurantId: 0,
            categoryId: 0,
            calories: rec.calories,
          );
          return RestaurantDishCard(
            dish: dish,
            isAiRecommended: true,
            aiExplanation: _formatExplanation(rec),
            restaurantName: rec.restaurantName,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DishDetailScreen(dishId: rec.dishId)),
            ),
          );
        }),
        const SizedBox(height: HomeConstants.sectionSpacing),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final recProvider = context.watch<RecommendationProvider>();
    final recs = OrderRecommendationUtils.filterRecommendations(
      recProvider.personalized,
      query: _searchQuery,
      cuisineKey: _selectedCuisineKey,
    );
    final trending = OrderRecommendationUtils.filterRecommendations(
      recProvider.trending,
      query: _searchQuery,
      cuisineKey: _selectedCuisineKey,
    );

    final hasActiveFilters =
        _searchQuery.trim().isNotEmpty || _selectedCuisineKey != null;
    final loadingRecs =
        recProvider.loadingPersonalized && recProvider.personalized.isEmpty;
    final recError = recProvider.personalizedError;
    final hasRecContent = recs.isNotEmpty || trending.isNotEmpty;

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
              onRefresh: _load,
              color: AppColors.accent,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  HomeSearchBar(
                    controller: _searchController,
                    editable: true,
                    onChanged: (_) {},
                  ),
                  HomeCuisineStrip(onCuisineTap: _onCuisineTap),
                  const SizedBox(height: 8),
                  if (loadingRecs && !hasActiveFilters)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                    )
                  else if (recError != null && !hasRecContent && !hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const EmptyState(
                            icon: Icons.cloud_off_outlined,
                            title: 'Unable to load AI recommendations',
                            subtitle: 'Check your connection and try again',
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              recError,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            onPressed: _retryRecommendations,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (hasActiveFilters &&
                      _searchDishes.isEmpty &&
                      _cuisineDishes.isEmpty &&
                      !_loadingCuisineDishes &&
                      recs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyState(
                        icon: Icons.search_off_outlined,
                        title: _selectedCuisineName != null
                            ? 'No ${_selectedCuisineName!} options yet'
                            : 'No matches',
                        subtitle: _selectedCuisineName != null
                            ? 'Try another cuisine or clear the filter'
                            : 'Try another search term or cuisine filter',
                      ),
                    )
                  else ...[
                    if (_loadingCuisineDishes)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                      ),
                    if (_cuisineDishes.isNotEmpty) ...[
                      HomeSectionHeader(
                        title: '${_selectedCuisineName ?? 'Cuisine'} dishes',
                        subtitle: 'From matching restaurants',
                        icon: Icons.ramen_dining_outlined,
                      ),
                      ..._cuisineDishes.map(
                        (d) => RestaurantDishCard(
                          dish: d,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DishDetailScreen(dishId: d.id),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_searchDishes.isNotEmpty) ...[
                      const HomeSectionHeader(
                        title: 'Dishes',
                        subtitle: 'Matching your search',
                        icon: Icons.ramen_dining_outlined,
                      ),
                      ..._searchDishes.map(
                        (d) => RestaurantDishCard(
                          dish: d,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DishDetailScreen(dishId: d.id),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (!hasActiveFilters) ...[
                      _dishSection(
                        'Recommended For You',
                        'Personalized by the hybrid AI engine',
                        OrderRecommendationUtils.recommendedForYou(recs),
                      ),
                      _dishSection(
                        'Healthy Picks',
                        'High protein and nutrition-aligned dishes',
                        OrderRecommendationUtils.healthyPicks(recs),
                      ),
                      _dishSection(
                        'Budget Friendly',
                        'Within your budget',
                        OrderRecommendationUtils.budgetFriendly(recs),
                      ),
                      _dishSection(
                        'Based On Previous Orders',
                        'Because you ordered similar dishes',
                        OrderRecommendationUtils.basedOnOrders(recs),
                      ),
                      _dishSection(
                        'Nearby',
                        'Popular dishes near you',
                        OrderRecommendationUtils.nearbyPicks(recs),
                      ),
                      _dishSection(
                        'Trending',
                        'Popular dishes right now',
                        trending,
                      ),
                    ] else if (recs.isNotEmpty) ...[
                      _dishSection(
                        'Recommended For You',
                        'Matching your filters',
                        OrderRecommendationUtils.recommendedForYou(recs),
                      ),
                    ],
                    if (_restaurantError != null && _catalogRestaurants.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Restaurant search unavailable: $_restaurantError',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
