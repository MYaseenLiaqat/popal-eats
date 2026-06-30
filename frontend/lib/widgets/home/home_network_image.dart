import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../feed/feed_shimmer.dart';
import 'home_constants.dart';

/// Network image with shimmer, cover fit, and optional hero.
class HomeNetworkImage extends StatelessWidget {
  const HomeNetworkImage({
    super.key,
    this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.heroTag,
    this.fallbackIcon = Icons.restaurant_outlined,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Object? heroTag;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(HomeConstants.cardRadius);

    Widget child;
    if (url == null || url!.isEmpty) {
      child = _fallback(radius);
    } else {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final cacheW = width != null ? (width! * dpr).round() : null;
      final cacheH = height != null ? (height! * dpr).round() : null;
      child = ClipRRect(
        borderRadius: radius,
        child: Image.network(
          url!,
          fit: fit,
          width: width,
          height: height,
          cacheWidth: cacheW,
          cacheHeight: cacheH,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, image, progress) {
            if (progress == null) return image;
            return FeedShimmer(
              borderRadius: radius.topLeft.x,
              child: SizedBox(width: width, height: height),
            );
          },
          errorBuilder: (_, __, ___) => _fallback(radius),
        ),
      );
    }

    child = RepaintBoundary(child: child);

    if (heroTag != null) {
      child = Hero(
        tag: heroTag!,
        child: Material(type: MaterialType.transparency, child: child),
      );
    }

    return SizedBox(width: width, height: height, child: child);
  }

  Widget _fallback(BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentSubtle, AppColors.surfaceLight],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        size: (height ?? 120) * 0.28,
        color: AppColors.accent.withValues(alpha: 0.55),
      ),
    );
  }
}
