import 'package:flutter/material.dart';

import '../../models/reel.dart';
import '../../theme/app_colors.dart';
import '../../utils/profile_image_url.dart';

/// Full-bleed reel card — static preview only (no video player in Phase 5).
class ReelCard extends StatelessWidget {
  const ReelCard({
    super.key,
    required this.reel,
    this.onPreviewTap,
    this.onRecipeTap,
  });

  final Reel reel;
  final VoidCallback? onPreviewTap;
  final VoidCallback? onRecipeTap;

  @override
  Widget build(BuildContext context) {
    final thumbnail = resolveProfileImageUrl(reel.thumbnailUrl);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnail != null)
          Image.network(
            thumbnail,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _PreviewBackdrop(kind: reel.kind),
          )
        else
          _PreviewBackdrop(kind: reel.kind),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.75),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      reel.kindLabel,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: _PreviewPlayButton(
                    durationLabel: reel.durationLabel,
                    onTap: onPreviewTap,
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 24 + bottomInset),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                reel.creatorName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                reel.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                reel.caption,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _SideActions(reel: reel, onRecipeTap: onRecipeTap),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewBackdrop extends StatelessWidget {
  const _PreviewBackdrop({required this.kind});

  final ReelKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = switch (kind) {
      ReelKind.chef => [const Color(0xFF2A2418), const Color(0xFF1A2830)],
      ReelKind.restaurant => [const Color(0xFF1A2028), const Color(0xFF283018)],
      ReelKind.recipe => [const Color(0xFF1A2830), const Color(0xFF2A2418)],
    };

    final icon = switch (kind) {
      ReelKind.chef => Icons.emoji_events_outlined,
      ReelKind.restaurant => Icons.storefront_outlined,
      ReelKind.recipe => Icons.menu_book_outlined,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 88,
          color: AppColors.gold.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _PreviewPlayButton extends StatelessWidget {
  const _PreviewPlayButton({
    this.durationLabel,
    this.onTap,
  });

  final String? durationLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.45),
                border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            durationLabel != null ? 'Preview · $durationLabel' : 'Preview coming soon',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _SideActions extends StatelessWidget {
  const _SideActions({required this.reel, this.onRecipeTap});

  final Reel reel;
  final VoidCallback? onRecipeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: Icons.favorite_border,
          label: 'Save',
          onTap: () => _showPlaceholderSnack(context, 'Save reel — coming soon'),
        ),
        const SizedBox(height: 16),
        _ActionIcon(
          icon: Icons.bookmark_border,
          label: 'Recipe',
          onTap: reel.hasRecipeDetails
              ? onRecipeTap
              : () => _showPlaceholderSnack(context, 'Recipe details not available yet'),
        ),
        const SizedBox(height: 16),
        _ActionIcon(
          icon: Icons.ios_share_outlined,
          label: 'Share',
          onTap: () => _showPlaceholderSnack(context, 'Share reel — coming soon'),
        ),
      ],
    );
  }

  void _showPlaceholderSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
