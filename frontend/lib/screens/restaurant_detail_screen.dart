import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dish_detail_screen.dart';
import '../models/dish.dart';
import '../models/recommendation.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../providers/cart_provider.dart';
import '../providers/restaurant_follow_provider.dart';
import '../services/api_client.dart';
import '../services/category_service.dart';
import '../services/dish_service.dart';
import '../services/recommendation_service.dart';
import '../services/restaurant_service.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import '../utils/menu_category_filter.dart';
import '../utils/profile_image_url.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/restaurant/restaurant_constants.dart';
import '../widgets/restaurant/restaurant_dish_card.dart';
import '../widgets/restaurant/restaurant_floating_cart_bar.dart';
import '../widgets/restaurant/restaurant_hero_header.dart';
import '../widgets/restaurant/restaurant_info_card.dart';
import '../widgets/restaurant/restaurant_loading_skeleton.dart';
import '../widgets/restaurant/restaurant_menu_header.dart';
import '../widgets/restaurant/restaurant_sections.dart';
import '../widgets/reviews/review_widgets.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Restaurant profile and menu (`GET /restaurants/{id}` + dishes).
class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  final int restaurantId;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final _restaurants = RestaurantService();
  final _dishes = DishService();
  final _categories = CategoryService();
  final _reviews = ReviewService();
  final _recommendations = RecommendationService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  Restaurant? restaurant;
  List<Dish> dishes = [];
  List<Review> recentReviews = [];
  List<Recommendation> restaurantRecommendations = [];
  Map<int, String> categoryNames = {};
  final Map<String, GlobalKey> _sectionKeys = {};
  final Set<int> _favoriteDishes = {};
  bool _favoriteRestaurant = false;
  bool loading = true;
  bool reviewsLoading = false;
  String? error;
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  Set<int> get _recommendedDishIds =>
      restaurantRecommendations.map((r) => r.dishId).toSet();

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartProvider>().load();
        context.read<RestaurantFollowProvider>().load();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow() async {
    final provider = context.read<RestaurantFollowProvider>();
    final nowFollowing = await provider.toggle(widget.restaurantId);
    if (!mounted) return;
    final name = restaurant?.name ?? 'restaurant';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowFollowing ? 'Following $name' : 'Unfollowed $name'),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final r = await _restaurants.getById(widget.restaurantId);
      final rawDishes = await _dishes.list(
        restaurantId: widget.restaurantId,
        limit: 100,
      );
      final rawCategories = await _categories.list(limit: 100);
      final parsedDishes = rawDishes
          .whereType<Map<String, dynamic>>()
          .map(Dish.fromJson)
          .toList();
      final names = <int, String>{};
      for (final c in rawCategories) {
        if (c is Map<String, dynamic>) {
          final id = c['id'];
          final name = c['name']?.toString();
          if (id is int && name != null && name.isNotEmpty) {
            names[id] = name;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        restaurant = r;
        dishes = parsedDishes;
        categoryNames = names;
        loading = false;
      });
      _loadReviews();
      _loadRecommendations(r.name, parsedDishes.map((d) => d.id).toSet());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = RecommendationCopy.friendlyError(e);
        loading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() => reviewsLoading = true);
    try {
      final list = await _reviews.listForRestaurant(widget.restaurantId, limit: 5);
      if (!mounted) return;
      setState(() {
        recentReviews = list;
        reviewsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => reviewsLoading = false);
    }
  }

  Future<void> _loadRecommendations(String restaurantName, Set<int> dishIds) async {
    try {
      final list = await _recommendations.list();
      if (!mounted) return;
      setState(() {
        restaurantRecommendations = list
            .where(
              (rec) =>
                  dishIds.contains(rec.dishId) ||
                  rec.restaurantName.trim().toLowerCase() ==
                      restaurantName.trim().toLowerCase(),
            )
            .take(8)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _writeReview() async {
    final r = restaurant;
    if (r == null) return;

    if (!ApiClient.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to leave a review')),
      );
      return;
    }

    final submitted = await showWriteReviewSheet(
      context: context,
      restaurantName: r.name,
      onSubmit: (rating, comment) async {
        await _reviews.create(
          restaurantId: r.id,
          rating: rating,
          comment: comment,
        );
      },
    );

    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your review!')),
      );
      await _load();
    }
  }

  List<({int categoryId, String label, List<Dish> items})> _groupedDishes() {
    if (dishes.isEmpty) return [];

    final sorted = List<Dish>.from(dishes)
      ..sort((a, b) => a.categoryId.compareTo(b.categoryId));

    final groups = <({int categoryId, String label, List<Dish> items})>[];
    for (final d in sorted) {
      final rawLabel = categoryNames[d.categoryId] ?? 'Menu';
      final label = MenuCategoryFilter.displayLabel(rawLabel);
      if (groups.isEmpty || groups.last.label != label) {
        groups.add((categoryId: d.categoryId, label: label, items: [d]));
      } else {
        final last = groups.removeLast();
        groups.add((
          categoryId: last.categoryId,
          label: last.label,
          items: [...last.items, d],
        ));
      }
    }
    return groups;
  }

  List<String> _categoryTabs() {
    final groups = _groupedDishes();
    if (groups.isEmpty) return const ['Popular'];
    final labels = groups.map((g) => g.label).toSet().toList();
    return ['Popular', ...labels];
  }

  List<Dish> _filterDishes(List<Dish> source) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((d) {
      final inName = d.name.toLowerCase().contains(q);
      final inDesc = d.description?.toLowerCase().contains(q) ?? false;
      return inName || inDesc;
    }).toList();
  }

  void _onCategorySelected(int index) {
    setState(() => _selectedCategoryIndex = index);
    final tabs = _categoryTabs();
    if (index >= tabs.length) return;
    final key = _sectionKeys[tabs[index]];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: RestaurantConstants.animDuration,
        curve: RestaurantConstants.animCurve,
        alignment: 0.12,
      );
    }
  }

  void _openDish(int dishId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DishDetailScreen(dishId: dishId)),
    );
  }

  GlobalKey _keyForSection(String label) {
    return _sectionKeys.putIfAbsent(label, GlobalKey.new);
  }

  List<Widget> _buildMenuSlivers() {
    final groups = _groupedDishes();
    if (groups.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: RestaurantMenuEmpty(query: _searchQuery),
        ),
      ];
    }

    final slivers = <Widget>[];
    final tabs = _categoryTabs();

    final popularDishes = _filterDishes(dishes).take(8).toList();
    if (tabs.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          key: _keyForSection('Popular'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Popular',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
      if (popularDishes.isEmpty) {
        slivers.add(SliverToBoxAdapter(child: RestaurantMenuEmpty(query: _searchQuery)));
      } else {
        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dish = popularDishes[index];
                return RestaurantDishCard(
                  dish: dish,
                  isFavorite: _favoriteDishes.contains(dish.id),
                  isAiRecommended: _recommendedDishIds.contains(dish.id),
                  onTap: () => _openDish(dish.id),
                  onFavoriteToggle: () {
                    setState(() {
                      if (_favoriteDishes.contains(dish.id)) {
                        _favoriteDishes.remove(dish.id);
                      } else {
                        _favoriteDishes.add(dish.id);
                      }
                    });
                  },
                );
              },
              childCount: popularDishes.length,
            ),
          ),
        );
      }
    }

    for (final group in groups) {
      final filtered = _filterDishes(group.items);
      if (filtered.isEmpty && _searchQuery.isNotEmpty) continue;

      slivers.add(
        SliverToBoxAdapter(
          key: _keyForSection(group.label),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              group.label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );

      if (filtered.isEmpty) {
        slivers.add(const SliverToBoxAdapter(child: RestaurantMenuEmpty()));
      } else {
        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dish = filtered[index];
                return RestaurantDishCard(
                  dish: dish,
                  isFavorite: _favoriteDishes.contains(dish.id),
                  isAiRecommended: _recommendedDishIds.contains(dish.id),
                  onTap: () => _openDish(dish.id),
                  onFavoriteToggle: () {
                    setState(() {
                      if (_favoriteDishes.contains(dish.id)) {
                        _favoriteDishes.remove(dish.id);
                      } else {
                        _favoriteDishes.add(dish.id);
                      }
                    });
                  },
                );
              },
              childCount: filtered.length,
            ),
          ),
        );
      }
    }

    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: loading
          ? const RestaurantLoadingSkeleton()
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Could not load restaurant',
                          subtitle: RecommendationCopy.friendlyError(error),
                        ),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : r == null
                  ? const Center(child: Text('Restaurant not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accent,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverAppBar(
                            pinned: true,
                            stretch: true,
                            expandedHeight: RestaurantConstants.heroHeight,
                            backgroundColor: AppColors.background,
                            leading: Padding(
                              padding: const EdgeInsets.all(8),
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withValues(alpha: 0.45),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                            actions: [
                              Consumer<RestaurantFollowProvider>(
                                builder: (context, follows, _) {
                                  final isFollowing = follows.isFollowing(widget.restaurantId);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: TextButton(
                                      onPressed: _toggleFollow,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: isFollowing
                                            ? Colors.white.withValues(alpha: 0.2)
                                            : AppColors.accent,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      child: Text(
                                        isFollowing ? 'Following' : 'Follow',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: CartIconButton(),
                              ),
                            ],
                            flexibleSpace: FlexibleSpaceBar(
                              background: RestaurantHeroHeader(
                                restaurant: r,
                                isFavorite: _favoriteRestaurant,
                                onFavoriteToggle: () {
                                  setState(() => _favoriteRestaurant = !_favoriteRestaurant);
                                },
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(child: RestaurantInfoCard(restaurant: r)),
                          SliverToBoxAdapter(child: RestaurantPromoBadges(restaurant: r)),
                          SliverToBoxAdapter(
                            child: RestaurantReviewsPreview(
                              reviews: recentReviews,
                              averageRating: r.averageRating,
                              totalReviews: r.totalReviews,
                              loading: reviewsLoading,
                              onWriteReview: _writeReview,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: RestaurantRecommendedSection(
                              items: restaurantRecommendations,
                              dishImages: {
                                for (final d in dishes)
                                  d.id: resolveProfileImageUrl(d.image),
                              },
                              onDishTap: _openDish,
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: RestaurantStickyHeaderDelegate(
                              child: RestaurantStickyMenuHeader(
                                searchController: _searchController,
                                categories: _categoryTabs(),
                                selectedCategoryIndex: _selectedCategoryIndex,
                                onSearchChanged: (value) {
                                  setState(() => _searchQuery = value);
                                },
                                onCategorySelected: _onCategorySelected,
                              ),
                            ),
                          ),
                          ..._buildMenuSlivers(),
                          SliverToBoxAdapter(
                            child: SizedBox(height: 96 + topPadding),
                          ),
                        ],
                      ),
                    ),
      bottomNavigationBar: const RestaurantFloatingCartBar(),
    );
  }
}
