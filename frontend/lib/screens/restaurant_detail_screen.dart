import 'package:flutter/material.dart';

import 'dish_detail_screen.dart';
import '../models/dish.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../services/api_client.dart';
import '../services/category_service.dart';
import '../services/dish_service.dart';
import '../services/restaurant_service.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import '../utils/menu_category_filter.dart';
import '../utils/preference_display.dart';
import '../utils/price_formatter.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/cart_icon_button.dart';
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

  Restaurant? restaurant;
  List<Dish> dishes = [];
  List<Review> recentReviews = [];
  Map<int, String> categoryNames = {};
  bool loading = true;
  bool reviewsLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
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

  Widget? _nutritionHighlights() {
    final withCal = dishes.where((d) => d.calories != null).toList();
    if (withCal.isEmpty) return null;

    withCal.sort((a, b) => (a.calories ?? 0).compareTo(b.calories ?? 0));
    final light = withCal.first;
    final hearty = withCal.last;
    final highProtein = dishes
        .where((d) => (d.protein ?? 0) >= 20)
        .map((d) => d.name)
        .take(2)
        .toList();

    return ModernCard(
      borderColor: AppColors.green.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nutrition highlights', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text('Lighter pick: ${light.name} (${light.calories} kcal)'),
          if (hearty.id != light.id)
            Text('Hearty option: ${hearty.name} (${hearty.calories} kcal)'),
          if (highProtein.isNotEmpty)
            Text('High protein: ${highProtein.join(', ')}'),
        ],
      ),
    );
  }

  List<Widget> _menuSections(BuildContext context) {
    if (dishes.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: ModernCard(
            child: Text(
              'No dishes listed for this restaurant',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ];
    }

    final groups = _groupedDishes();
    final distinctLabels = groups.map((g) => g.label).toSet();
    final showGroupHeaders = distinctLabels.length > 1;
    final widgets = <Widget>[];

    for (final group in groups) {
      widgets.add(
        SectionHeader(
          title: showGroupHeaders ? group.label : 'Menu',
          subtitle: '${group.items.length} dishes',
        ),
      );
      for (final d in group.items) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ModernCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DishDetailScreen(dishId: d.id),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: d.image != null && d.image!.isNotEmpty
                          ? Image.network(
                              d.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _dishThumbFallback(),
                            )
                          : _dishThumbFallback(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (d.description != null &&
                            d.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            d.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (d.calories != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${d.calories} kcal'
                                '${d.protein != null ? ' · ${d.protein!.toStringAsFixed(0)}g protein' : ''}',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        PriceFormatter.format(d.price),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.gold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _dishThumbFallback() {
    return Container(
      color: AppColors.green.withValues(alpha: 0.12),
      child: const Icon(Icons.lunch_dining, color: AppColors.green, size: 24),
    );
  }

  String? _primaryCuisine(Restaurant r) {
    if (r.tags.isEmpty) return null;
    return PreferenceDisplay.cuisineLabel(r.tags.first);
  }

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final highlights = r != null ? _nutritionHighlights() : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(r?.name ?? 'Restaurant'),
        actions: const [CartIconButton()],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppColors.screenPadding),
                    child: Text(error!, textAlign: TextAlign.center),
                  ),
                )
              : r == null
                  ? const Center(child: Text('Restaurant not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.gold,
                      child: ListView(
                        padding: const EdgeInsets.all(AppColors.screenPadding),
                        children: [
                          if (r.image != null && r.image!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: DishImageBanner(imageUrl: r.image, height: 180),
                            ),
                          ModernCard(
                            gradient: AppColors.headerGradient,
                            borderColor: AppColors.gold.withValues(alpha: 0.35),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (r.image == null || r.image!.isEmpty)
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          gradient: AppColors.goldGradient,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.storefront,
                                          color: Color(0xFF1A1400),
                                          size: 36,
                                        ),
                                      )
                                    else
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          r.image!,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.storefront,
                                            color: AppColors.gold,
                                            size: 36,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  color: AppColors.gold,
                                                ),
                                          ),
                                          if (_primaryCuisine(r) != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _primaryCuisine(r)!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(color: AppColors.green),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          RatingBadge(
                                            rating: r.averageRating,
                                            reviews: r.totalReviews,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (r.description != null &&
                                    r.description!.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    r.description!,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                                if ((r.address != null &&
                                        r.address!.isNotEmpty) ||
                                    (r.city != null &&
                                        r.city!.isNotEmpty)) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                        color: AppColors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          [
                                            if (r.address != null &&
                                                r.address!.isNotEmpty)
                                              r.address!,
                                            if (r.city != null &&
                                                r.city!.isNotEmpty)
                                              r.city!,
                                          ].join(', '),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (r.tags.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: r.tags
                                        .map(
                                          (tag) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceLight,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppColors.green
                                                    .withValues(alpha: 0.35),
                                              ),
                                            ),
                                            child: Text(
                                              PreferenceDisplay.cuisineLabel(tag),
                                              style: const TextStyle(
                                                color: AppColors.green,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (highlights != null) ...[
                            const SizedBox(height: 16),
                            highlights,
                          ],
                          const SizedBox(height: 8),
                          RestaurantReviewsSection(
                            reviews: recentReviews,
                            averageRating: r.averageRating,
                            totalReviews: r.totalReviews,
                            loading: reviewsLoading,
                            onWriteReview: _writeReview,
                          ),
                          const SizedBox(height: 8),
                          ..._menuSections(context),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }
}
