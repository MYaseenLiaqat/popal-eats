import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Shimmer placeholder for feed media and cards.
class FeedShimmer extends StatefulWidget {
  const FeedShimmer({
    super.key,
    this.borderRadius = 0,
    this.child,
  });

  final double borderRadius;
  final Widget? child;

  @override
  State<FeedShimmer> createState() => _FeedShimmerState();
}

class _FeedShimmerState extends State<FeedShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(-0.5 + _controller.value * 2, 0),
              colors: [
                AppColors.surfaceLight,
                AppColors.surfaceLight.withValues(alpha: 0.55),
                AppColors.surfaceLight,
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Skeleton block with optional aspect ratio.
class FeedSkeletonBlock extends StatelessWidget {
  const FeedSkeletonBlock({
    super.key,
    this.aspectRatio,
    this.height,
    this.width,
    this.borderRadius = 0,
  });

  final double? aspectRatio;
  final double? height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final block = FeedShimmer(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
      ),
    );
    if (aspectRatio != null) {
      return AspectRatio(aspectRatio: aspectRatio!, child: block);
    }
    return block;
  }
}
