import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/category_service.dart';
import '../services/dish_service.dart';
import '../services/restaurant_service.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'menu_upload_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'recommendations_screen.dart';
import 'restaurant_detail_screen.dart';
import 'review_status_screen.dart';
import '../widgets/cart_icon_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _restaurants = RestaurantService();
  final _categories = CategoryService();
  final _dishes = DishService();
  final _reviews = ReviewService();

  List<dynamic> restaurants = [];
  List<dynamic> categories = [];
  List<dynamic> dishes = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<CartProvider>().load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await _restaurants.list();
      final c = await _categories.list();
      final d = await _dishes.list();
      if (!mounted) return;
      setState(() {
        restaurants = r;
        categories = c;
        dishes = d;
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

  Future<void> _addReview(int restaurantId) async {
    try {
      final created = await _reviews.create(
        restaurantId: restaurantId,
        rating: 5,
        comment: 'Great experience from app!',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted — processing AI...')),
        );
        final reviewId = created['id'] as int?;
        if (reviewId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReviewStatusScreen(reviewId: reviewId),
            ),
          );
        }
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _openRecommendations() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?['full_name']?.toString() ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Popal Eats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.recommend_outlined),
            tooltip: 'Recommendations',
            onPressed: _openRecommendations,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'My orders',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
          const CartIconButton(),
          if (auth.user?['role'] == 'admin')
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MenuUploadScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              context.read<CartProvider>().reset();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(error!, textAlign: TextAlign.center),
                  ),
                )
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
                            Text(
                              'Hello, $name',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: AppColors.gold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Discover meals tailored to your taste',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      SectionHeader(
                        title: 'For You',
                        subtitle: 'AI-powered recommendations',
                        trailing: TextButton(
                          onPressed: _openRecommendations,
                          child: const Text('See all'),
                        ),
                      ),
                      ModernCard(
                        onTap: _openRecommendations,
                        borderColor: AppColors.green.withValues(alpha: 0.4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: AppColors.green,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personalized picks',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Trending, popular & hybrid recommendations',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      SectionHeader(
                        title: 'Restaurants',
                        subtitle: '${restaurants.length} nearby',
                      ),
                      ...restaurants.map((r) {
                        final id = r['id'] as int;
                        final rating =
                            r['average_rating'] ?? r['rating'] ?? 0;
                        final reviews = r['total_reviews'] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ModernCard(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RestaurantDetailScreen(
                                  restaurantId: id,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.goldGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: Color(0xFF1A1400),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['name']?.toString() ?? '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        r['city']?.toString() ?? '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.gold
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  size: 14,
                                                  color: AppColors.gold,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$rating',
                                                  style: const TextStyle(
                                                    color: AppColors.gold,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$reviews reviews',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.rate_review_outlined,
                                    color: AppColors.green,
                                  ),
                                  onPressed: () => _addReview(id),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      SectionHeader(
                        title: 'Categories',
                        subtitle: '${categories.length} cuisines',
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((c) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.green.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              c['name']?.toString() ?? '',
                              style: const TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SectionHeader(
                        title: 'Popular dishes',
                        subtitle: 'Top picks from the menu',
                      ),
                      ...dishes.take(10).map((d) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ModernCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lunch_dining,
                                  color: AppColors.gold,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    d['name']?.toString() ?? '',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                Text(
                                  '\$${d['price']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: AppColors.gold),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
