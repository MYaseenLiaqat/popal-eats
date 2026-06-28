import 'package:flutter/material.dart';

/// Layout and motion tokens for the cart experience.
abstract final class CartConstants {
  static const cardRadius = 20.0;
  static const animDuration = Duration(milliseconds: 260);
  static const animCurve = Curves.easeOutCubic;

  static String dishHeroTag(int dishId) => 'home_dish_$dishId';
}
