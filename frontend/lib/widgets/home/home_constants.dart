import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Layout and motion tokens for the premium home experience.
abstract final class HomeConstants {
  static const cardRadius = 20.0;
  static const sectionSpacing = 28.0;
  static const horizontalPadding = AppColors.screenPadding;

  static const animDuration = Duration(milliseconds: 260);
  static const animCurve = Curves.easeOutCubic;

  static String restaurantHeroTag(int id) => 'home_restaurant_$id';
  static String dishHeroTag(int id) => 'home_dish_$id';

  static double carouselItemWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 380;
    if (width >= 900) return 340;
    if (width >= 600) return 300;
    return width * 0.82;
  }

  static double dishCardWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 260;
    if (width >= 900) return 240;
    return 210;
  }

  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 3;
    if (width >= 900) return 2;
    return 1;
  }
}
