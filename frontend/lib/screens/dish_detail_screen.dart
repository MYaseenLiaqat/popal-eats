import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dish.dart';
import '../models/recommendation.dart';
import '../models/review.dart';
import '../providers/cart_provider.dart';
import '../services/api_client.dart';
import '../services/dish_service.dart';
import '../services/feed_image_loader.dart';
import '../services/recommendation_service.dart';
import '../services/restaurant_service.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/dish/dish_hero_header.dart';
import '../widgets/dish/dish_info_section.dart';
import '../widgets/dish/dish_loading_skeleton.dart';
import '../widgets/dish/dish_nutrition_section.dart';
import '../widgets/dish/dish_reviews_recommended.dart';
import '../widgets/dish/dish_sticky_cta.dart';
import '../widgets/reviews/review_widgets.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'main_shell.dart';
import 'restaurant_detail_screen.dart';

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
  final _recommendations = RecommendationService();
  final _imageLoader = FeedImageLoader();

  Dish? dish;
  String? restaurantName;
  int? restaurantId;
  double restaurantRating = 0;
  int restaurantReviewCount = 0;
  List<Review> recentReviews = [];
  List<Recommendation> relatedRecommendations = [];
  Map<int, String?> recommendationImages = {};
  bool loading = true;
  bool reviewsLoading = false;
  bool adding = false;
  bool _favorite = false;
  int _quantity = 1;
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
      await _loadRecommendations();
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
        restaurantId = r.id;
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

  Future<void> _loadRecommendations() async {
    try {
      final list = await _recommendations.list();
      if (!mounted) return;
      final related = list.where((r) => r.dishId != widget.dishId).take(8).toList();
      final images = await _imageLoader.loadImages(related.map((r) => r.dishId));
      if (!mounted) return;
      setState(() {
        relatedRecommendations = related;
        recommendationImages = images;
      });
    } catch (_) {}
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
    final ok = await context.read<CartProvider>().addItem(
          dishId: d.id,
          quantity: _quantity,
        );
    if (!mounted) return;
    setState(() => adding = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${d.name} added to cart'),
          action: SnackBarAction(
            label: 'Go to Order',
            onPressed: () {
              context.findAncestorStateOfType<MainShellState>()?.navigateToTab(MainShellState.orderTab);
            },
          ),
        ),
      );
    } else {
      final msg = context.read<CartProvider>().error ?? 'Could not add to cart';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  void _openRestaurant() {
    final id = restaurantId ?? dish?.restaurantId;
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurantId: id)),
    );
  }

  void _openRelatedDish(int dishId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DishDetailScreen(dishId: dishId)),
    );
  }

  void _shareDish() {
    shareDishLink(widget.dishId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dish link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = dish;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: loading
          ? const DishLoadingSkeleton()
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Could not load dish',
                          subtitle: RecommendationCopy.friendlyError(error),
                        ),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : d == null
                  ? const Center(child: Text('Dish not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accent,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            child: DishHeroHeader(
                              imageUrl: d.image,
                              dishId: d.id,
                              restaurantName: restaurantName,
                              isFavorite: _favorite,
                              onFavoriteToggle: () => setState(() => _favorite = !_favorite),
                              onRestaurantTap: _openRestaurant,
                              onShare: _shareDish,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: DishInfoHeader(
                              dish: d,
                              restaurantName: restaurantName,
                              restaurantRating: restaurantRating,
                              restaurantReviewCount: restaurantReviewCount,
                              onRestaurantTap: _openRestaurant,
                            ),
                          ),
                          if (d.description != null && d.description!.trim().isNotEmpty)
                            SliverToBoxAdapter(
                              child: DishExpandableDescription(text: d.description!.trim()),
                            ),
                          SliverToBoxAdapter(child: DishNutritionSection(dish: d)),
                          SliverToBoxAdapter(child: DishIngredientsSection(ingredients: d.ingredients)),
                          SliverToBoxAdapter(child: DishAllergensSection(allergens: d.allergens)),
                          SliverToBoxAdapter(
                            child: DishReviewsSection(
                              reviews: recentReviews,
                              averageRating: restaurantRating,
                              totalReviews: restaurantReviewCount,
                              loading: reviewsLoading,
                              onWriteReview: _writeReview,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: DishRecommendedSection(
                              items: relatedRecommendations,
                              dishImages: recommendationImages,
                              onDishTap: _openRelatedDish,
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 120 + bottomPad)),
                        ],
                      ),
                    ),
      bottomNavigationBar: d == null || loading || error != null
          ? null
          : DishStickyCta(
              quantity: _quantity,
              unitPrice: d.price,
              loading: adding,
              enabled: d.isAvailable,
              onQuantityChanged: (q) => setState(() => _quantity = q),
              onAddToCart: _addToCart,
            ),
    );
  }
}
