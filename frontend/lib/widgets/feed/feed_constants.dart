import 'package:flutter/material.dart';

/// Shared layout tokens for the home/community feed.
abstract final class FeedConstants {
  /// Instagram-style portrait media frame (width : height).
  static const double mediaAspectRatio = 4 / 5;
  static const double cardRadius = 20;

  static const Duration animDuration = Duration(milliseconds: 260);
  static const Curve animCurve = Curves.easeOutCubic;

  static String heroTagForPost(int postId) => 'post_media_$postId';
}
