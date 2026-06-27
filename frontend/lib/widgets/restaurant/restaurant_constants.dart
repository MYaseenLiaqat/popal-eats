import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Layout and motion tokens for restaurant detail screens.
abstract final class RestaurantConstants {
  static const cardRadius = 20.0;
  static const heroHeight = 280.0;
  static const stickyHeaderHeight = 112.0;

  static const animDuration = Duration(milliseconds: 260);
  static const animCurve = Curves.easeOutCubic;

  static String coverHeroTag(int restaurantId) => 'home_restaurant_$restaurantId';
  static String dishHeroTag(int dishId) => 'home_dish_$dishId';
}

class RestaurantStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  RestaurantStickyHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => RestaurantConstants.stickyHeaderHeight;

  @override
  double get maxExtent => RestaurantConstants.stickyHeaderHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: AppColors.background,
      elevation: overlapsContent ? 4 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant RestaurantStickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
