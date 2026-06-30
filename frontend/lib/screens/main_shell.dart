import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import 'community_screen.dart';
import 'delivery_screen.dart';
import 'home_screen.dart';
import 'order_screen.dart';
import 'profile_screen.dart';

/// Primary app shell: Home · Order · Delivery · Community · Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  static const tabCount = 5;
  static const homeTab = 0;
  static const orderTab = 1;
  static const deliveryTab = 2;
  static const communityTab = 3;
  static const profileTab = 4;

  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, tabCount - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FriendsProvider>().fetchAll(force: true);
      context.read<GroupProvider>().fetchAll(force: true);
      context.read<CartProvider>().load();
    });
  }

  void navigateToTab(int index) {
    if (index < 0 || index >= tabCount) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(isTabActive: _index == homeTab),
          OrderScreen(isTabActive: _index == orderTab),
          DeliveryScreen(isTabActive: _index == deliveryTab),
          const CommunityScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.navBg,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        selectedIndex: _index,
        onDestinationSelected: navigateToTab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Order',
          ),
          NavigationDestination(
            icon: Icon(Icons.delivery_dining_outlined),
            selectedIcon: Icon(Icons.delivery_dining),
            label: 'Delivery',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
