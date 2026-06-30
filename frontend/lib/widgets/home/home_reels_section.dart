import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/reels_provider.dart';
import '../../theme/app_colors.dart';
import '../feed/home_reels_entry.dart';
import '../ui/app_ui_widgets.dart';

/// Reels strip on Home — shows entry when available, otherwise empty state.
class HomeReelsSection extends StatelessWidget {
  const HomeReelsSection({super.key, required this.onOpenReels});

  final VoidCallback onOpenReels;

  @override
  Widget build(BuildContext context) {
    final reels = context.watch<ReelsProvider>();
    final hasVideo = reels.reels.any((r) => r.hasVideo);

    if (reels.loading && reels.reels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 48,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
            ),
          ),
        ),
      );
    }

    if (hasVideo) {
      return HomeReelsEntry(onTap: onOpenReels);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ModernCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Icon(Icons.slow_motion_video_outlined, color: AppColors.textSecondary.withValues(alpha: 0.9)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No reels available yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
