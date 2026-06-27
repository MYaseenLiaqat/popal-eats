import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'feed_constants.dart';
import 'feed_shimmer.dart';

/// Fixed-size feed media frame — every post uses identical dimensions.
class FeedMediaFrame extends StatelessWidget {
  const FeedMediaFrame({
    super.key,
    this.imageUrl,
    this.isVideo = false,
    this.onTap,
    this.onDoubleTap,
    this.heroTag,
  });

  final String? imageUrl;
  final bool isVideo;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: FeedConstants.mediaAspectRatio,
        child: GestureDetector(
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMedia(),
              if (isVideo) _playBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedia() {
    if (imageUrl == null) {
      return _wrapHero(_placeholder());
    }

    Widget image = Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return FeedShimmer(child: const SizedBox.expand());
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );

    image = _wrapHero(image);
    return image;
  }

  Widget _wrapHero(Widget child) {
    if (heroTag == null) return child;
    return Hero(
      tag: heroTag!,
      child: Material(type: MaterialType.transparency, child: child),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.surfaceLight,
      child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        size: 48,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _playBadge() {
    return Center(
      child: IgnorePointer(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
        ),
      ),
    );
  }
}
