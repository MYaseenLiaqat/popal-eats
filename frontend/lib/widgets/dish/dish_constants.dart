import 'package:flutter/material.dart';

/// Layout and motion tokens for dish detail screens.
abstract final class DishConstants {
  static const cardRadius = 20.0;
  static const heroHeight = 320.0;

  static const animDuration = Duration(milliseconds: 260);
  static const animCurve = Curves.easeOutCubic;

  static String dishHeroTag(int dishId) => 'home_dish_$dishId';
}
