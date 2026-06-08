import 'package:flutter/material.dart';

import 'dish_detail_screen.dart';
import '../models/dish.dart';
import '../models/restaurant.dart';
import '../services/category_service.dart';
import '../services/dish_service.dart';
import '../services/restaurant_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cart_icon_button.dart';
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

  Restaurant? restaurant;
  List<Dish> dishes = [];
  Map<int, String> categoryNames = {};
  bool loading = true;
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  List<({int categoryId, String label, List<Dish> items})> _groupedDishes() {
    if (dishes.isEmpty) return [];

    final sorted = List<Dish>.from(dishes)
      ..sort((a, b) => a.categoryId.compareTo(b.categoryId));

    final groups = <({int categoryId, String label, List<Dish> items})>[];
    for (final d in sorted) {
      final label = categoryNames[d.categoryId] ?? 'Menu';
      if (groups.isEmpty || groups.last.categoryId != d.categoryId) {
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
    final showGroupHeaders = groups.length > 1;
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lunch_dining,
                      color: AppColors.green,
                      size: 24,
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
                            '${d.calories} kcal',
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
                        '\$${d.price.toStringAsFixed(2)}',
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

  @override
  Widget build(BuildContext context) {
    final r = restaurant;

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
                          ModernCard(
                            gradient: AppColors.headerGradient,
                            borderColor: AppColors.gold.withValues(alpha: 0.35),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                              tag,
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
                          ..._menuSections(context),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }
}
