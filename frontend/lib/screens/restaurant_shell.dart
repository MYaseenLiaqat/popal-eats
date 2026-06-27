import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/restaurant.dart';
import '../providers/auth_provider.dart';
import '../services/restaurant_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'owner_dishes_screen.dart';
import 'restaurant_analytics_screen.dart';
import 'restaurant_content_screen.dart';
import 'restaurant_dashboard_home.dart';
import 'restaurant_orders_screen.dart';
import 'restaurant_profile_screen.dart';
import 'restaurant_register_screen.dart';

/// Restaurant owner shell — Dashboard · Orders · Menu · Content · Analytics · Profile.
class RestaurantShell extends StatefulWidget {
  const RestaurantShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<RestaurantShell> createState() => RestaurantShellState();
}

class RestaurantShellState extends State<RestaurantShell> {
  static const tabCount = 6;
  static const dashboardTab = 0;
  static const ordersTab = 1;
  static const menuTab = 2;
  static const contentTab = 3;
  static const analyticsTab = 4;
  static const profileTab = 5;

  final _service = RestaurantOwnerService();
  late int _index;
  List<Restaurant> _restaurants = [];
  Restaurant? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, tabCount - 1);
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.listMine();
      if (!mounted) return;
      setState(() {
        _restaurants = list;
        _selected = list.isNotEmpty ? list.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = RecommendationCopy.friendlyError(e);
        _loading = false;
      });
    }
  }

  void navigateToTab(int index) {
    if (index < 0 || index >= tabCount) return;
    setState(() => _index = index);
  }

  void _selectRestaurant(Restaurant restaurant) {
    setState(() => _selected = restaurant);
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_error != null && _restaurants.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurant')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppColors.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!),
                const SizedBox(height: 16),
                TextButton(onPressed: _loadRestaurants, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    if (_restaurants.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurant')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppColors.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No restaurant registered',
                  subtitle: 'Register your restaurant to access the business dashboard.',
                ),
                const SizedBox(height: 20),
                GoldActionButton(
                  label: 'Register restaurant',
                  icon: Icons.add_business_outlined,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RestaurantRegisterScreen()),
                    );
                    _loadRestaurants();
                  },
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: _logout, child: const Text('Sign out')),
              ],
            ),
          ),
        ),
      );
    }

    final restaurant = _selected!;
    return Scaffold(
      appBar: AppBar(
        title: _restaurants.length > 1
            ? DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: restaurant.id,
                  dropdownColor: AppColors.surface,
                  items: _restaurants
                      .map(
                        (r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    final match = _restaurants.where((r) => r.id == id).firstOrNull;
                    if (match != null) _selectRestaurant(match);
                  },
                ),
              )
            : Text(restaurant.name),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRestaurants),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          RestaurantDashboardHome(
            key: ValueKey('dash-${restaurant.id}'),
            restaurant: restaurant,
            onNavigateOrders: () => navigateToTab(ordersTab),
            onNavigateMenu: () => navigateToTab(menuTab),
            onNavigateContent: () => navigateToTab(contentTab),
          ),
          RestaurantOrdersScreen(
            key: ValueKey('orders-${restaurant.id}'),
            restaurantId: restaurant.id,
          ),
          OwnerDishesScreen(
            key: ValueKey('menu-${restaurant.id}'),
            restaurantId: restaurant.id,
            restaurantName: restaurant.name,
            embedded: true,
          ),
          RestaurantContentScreen(
            key: ValueKey('content-${restaurant.id}'),
            restaurantId: restaurant.id,
          ),
          RestaurantAnalyticsScreen(
            key: ValueKey('analytics-${restaurant.id}'),
            restaurantId: restaurant.id,
          ),
          RestaurantProfileScreen(
            key: ValueKey('profile-${restaurant.id}'),
            restaurantId: restaurant.id,
            onRestaurantUpdated: _loadRestaurants,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.navBg,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        selectedIndex: _index,
        onDestinationSelected: navigateToTab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Content',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
