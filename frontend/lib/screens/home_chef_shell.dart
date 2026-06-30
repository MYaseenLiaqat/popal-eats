import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/restaurant.dart';
import '../providers/auth_provider.dart';
import '../services/home_chef_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import 'home_chef_content_screen.dart';
import 'home_chef_profile_screen.dart';
import 'owner_dishes_screen.dart';
import 'restaurant_analytics_screen.dart';
import 'restaurant_dashboard_home.dart';
import 'restaurant_orders_screen.dart';

/// Home chef shell — Dashboard · Orders · Recipes · Content · Analytics · Profile.
class HomeChefShell extends StatefulWidget {
  const HomeChefShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeChefShell> createState() => HomeChefShellState();
}

class HomeChefShellState extends State<HomeChefShell> {
  static const tabCount = 6;
  static const dashboardTab = 0;
  static const ordersTab = 1;
  static const recipesTab = 2;
  static const contentTab = 3;
  static const analyticsTab = 4;
  static const profileTab = 5;

  final _service = HomeChefOwnerService();
  late int _index;
  Restaurant? _kitchen;
  String _displayName = 'Home Chef';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, tabCount - 1);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await _service.getMe();
      final kitchen = await _service.kitchenAsRestaurant();
      if (!mounted) return;
      setState(() {
        _kitchen = kitchen;
        _displayName = me['display_name']?.toString() ?? kitchen.name;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_error != null || _kitchen == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home Chef')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppColors.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error ?? 'Could not load kitchen'),
                const SizedBox(height: 16),
                TextButton(onPressed: _load, child: const Text('Retry')),
                TextButton(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final kitchen = _kitchen!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_displayName),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          RestaurantDashboardHome(
            key: ValueKey('chef-dash-${kitchen.id}'),
            restaurant: kitchen,
            onNavigateOrders: () => navigateToTab(ordersTab),
            onNavigateMenu: () => navigateToTab(recipesTab),
            onNavigateContent: () => navigateToTab(contentTab),
          ),
          RestaurantOrdersScreen(
            key: ValueKey('chef-orders-${kitchen.id}'),
            restaurantId: kitchen.id,
          ),
          OwnerDishesScreen(
            key: ValueKey('chef-recipes-${kitchen.id}'),
            restaurantId: kitchen.id,
            restaurantName: 'Recipes',
            embedded: true,
          ),
          const HomeChefContentScreen(key: ValueKey('chef-content')),
          RestaurantAnalyticsScreen(
            key: ValueKey('chef-analytics-${kitchen.id}'),
            restaurantId: kitchen.id,
          ),
          HomeChefProfileScreen(
            key: const ValueKey('chef-profile'),
            onProfileUpdated: _load,
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
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Content',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
