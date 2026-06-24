import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dish.dart';
import '../models/review.dart';
import '../providers/cart_provider.dart';
import '../services/api_client.dart';
import '../services/dish_service.dart';
import '../services/restaurant_service.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import '../utils/price_formatter.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/reviews/review_widgets.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Dish profile from `GET /dishes/{id}` with add-to-cart.
class DishDetailScreen extends StatefulWidget {
  const DishDetailScreen({super.key, required this.dishId});

  final int dishId;

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  final _dishes = DishService();
  final _restaurants = RestaurantService();
  final _reviews = ReviewService();

  Dish? dish;
  String? restaurantName;
  double restaurantRating = 0;
  int restaurantReviewCount = 0;
  List<Review> recentReviews = [];
  bool loading = true;
  bool reviewsLoading = false;
  bool adding = false;
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
      final d = await _dishes.getById(widget.dishId);
      if (!mounted) return;
      setState(() {
        dish = d;
        loading = false;
      });
      await _loadReviews(d.restaurantId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = RecommendationCopy.friendlyError(e);
        loading = false;
      });
    }
  }

  Future<void> _loadReviews(int restaurantId) async {
    setState(() => reviewsLoading = true);
    try {
      final r = await _restaurants.getById(restaurantId);
      final list = await _reviews.listForRestaurant(restaurantId, limit: 5);
      if (!mounted) return;
      setState(() {
        restaurantName = r.name;
        restaurantRating = r.averageRating;
        restaurantReviewCount = r.totalReviews;
        recentReviews = list;
        reviewsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => reviewsLoading = false);
    }
  }

  Future<void> _writeReview() async {
    final d = dish;
    if (d == null) return;

    if (!ApiClient.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to leave a review')),
      );
      return;
    }

    final name = restaurantName ?? 'this restaurant';
    final submitted = await showWriteReviewSheet(
      context: context,
      restaurantName: name,
      onSubmit: (rating, comment) async {
        await _reviews.create(
          restaurantId: d.restaurantId,
          rating: rating,
          comment: comment,
        );
      },
    );

    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your review!')),
      );
      await _loadReviews(d.restaurantId);
    }
  }

  Future<void> _addToCart() async {
    final d = dish;
    if (d == null || adding) return;

    setState(() => adding = true);
    final ok = await context.read<CartProvider>().addItem(dishId: d.id);
    if (!mounted) return;
    setState(() => adding = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${d.name} added to cart')),
      );
    } else {
      final msg = context.read<CartProvider>().error ?? 'Could not add to cart';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  bool _hasNutrition(Dish d) =>
      d.calories != null ||
      d.protein != null ||
      d.carbs != null ||
      d.fats != null;

  @override
  Widget build(BuildContext context) {
    final d = dish;
    final restaurantReviews = d?.restaurantId != null
        ? recentReviews
        : <Review>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(d?.name ?? 'Dish'),
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
              : d == null
                  ? const Center(child: Text('Dish not found'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(
                              AppColors.screenPadding,
                            ),
                            children: [
                              DishImageBanner(imageUrl: d.image),
                              const SizedBox(height: 20),
                              Text(
                                d.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(color: AppColors.gold),
                              ),
                              if (d.cuisine != null && d.cuisine!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  d.cuisine!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.green,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              ModernCard(
                                borderColor:
                                    AppColors.gold.withValues(alpha: 0.4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Price',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                    Text(
                                      PriceFormatter.format(d.price),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(color: AppColors.gold),
                                    ),
                                  ],
                                ),
                              ),
                              if (d.description != null &&
                                  d.description!.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Text(
                                  'Description',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  d.description!,
                                  style:
                                      Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                              if (_hasNutrition(d)) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Nutrition',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Per serving',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                NutritionGrid(
                                  calories: d.calories,
                                  protein: d.protein,
                                  carbs: d.carbs,
                                  fats: d.fats,
                                ),
                              ],
                              const SizedBox(height: 24),
                              RestaurantReviewsSection(
                                reviews: restaurantReviews,
                                averageRating: restaurantRating,
                                totalReviews: restaurantReviewCount,
                                loading: reviewsLoading,
                                onWriteReview: _writeReview,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        SafeArea(
                          minimum: const EdgeInsets.all(
                            AppColors.screenPadding,
                          ),
                          child: GoldActionButton(
                            label: d.isAvailable
                                ? 'Add To Cart'
                                : 'Unavailable',
                            icon: Icons.add_shopping_cart,
                            loading: adding,
                            onPressed: d.isAvailable && !adding
                                ? _addToCart
                                : null,
                          ),
                        ),
                      ],
                    ),
    );
  }
}
