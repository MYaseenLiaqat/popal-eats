import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/category_service.dart';
import '../services/dish_service.dart';
import '../services/restaurant_service.dart';
import '../services/review_service.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'menu_upload_screen.dart';
import 'orders_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Popal Eats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.recommend_outlined),
            tooltip: 'Recommendations',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RecommendationsScreen(),
              ),
            ),
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
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Hello, ${auth.user?['full_name'] ?? 'Guest'}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text('Restaurants (${restaurants.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                      ...restaurants.map((r) {
                        final id = r['id'] as int;
                        final rating = r['average_rating'] ?? r['rating'] ?? 0;
                        return Card(
                          child: ListTile(
                            title: Text(r['name']?.toString() ?? ''),
                            subtitle: Text(
                              '${r['city'] ?? ''} · ★ $rating (${r['total_reviews'] ?? 0} reviews)',
                            ),
                            isThreeLine: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RestaurantDetailScreen(
                                  restaurantId: id,
                                ),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.rate_review),
                              onPressed: () => _addReview(id),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Text('Categories (${categories.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                      ...categories.map(
                        (c) => ListTile(
                          dense: true,
                          title: Text(c['name']?.toString() ?? ''),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Dishes (${dishes.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                      ...dishes.take(10).map(
                            (d) => ListTile(
                              dense: true,
                              title: Text(d['name']?.toString() ?? ''),
                              trailing: Text('\$${d['price']}'),
                            ),
                          ),
                    ],
                  ),
                ),
    );
  }
}
