import 'package:flutter/material.dart';

import '../../models/story.dart';
import '../../theme/app_colors.dart';
import '../feed/feed_stories_row.dart';
import '../ui/app_ui_widgets.dart';

/// Stories row with empty state — always occupies a slot on Home.
class HomeStoriesSection extends StatelessWidget {
  const HomeStoriesSection({
    super.key,
    required this.groups,
    required this.loading,
    this.currentUserId,
    this.showOwnStorySlot = false,
    this.onCreateTap,
    this.onGroupTap,
  });

  final List<StoryGroup> groups;
  final bool loading;
  final int? currentUserId;
  final bool showOwnStorySlot;
  final VoidCallback? onCreateTap;
  final void Function(StoryGroup group)? onGroupTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stories', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (loading && groups.isEmpty)
            const SizedBox(
              height: 96,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            )
          else if (groups.isEmpty)
            const ModernCard(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Icon(Icons.auto_stories_outlined, color: AppColors.textSecondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No stories yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            FeedStoriesRow(
              groups: groups,
              currentUserId: currentUserId,
              showOwnStorySlot: showOwnStorySlot,
              onCreateTap: onCreateTap,
              onGroupTap: onGroupTap,
            ),
        ],
      ),
    );
  }
}
