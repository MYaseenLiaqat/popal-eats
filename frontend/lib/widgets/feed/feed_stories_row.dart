import 'package:flutter/material.dart';

import '../../models/story.dart';
import '../../theme/app_colors.dart';
import '../../utils/media_url.dart';

/// Horizontal story rings backed by API story groups.
class FeedStoriesRow extends StatelessWidget {
  const FeedStoriesRow({
    super.key,
    required this.groups,
    this.currentUserId,
    this.showOwnStorySlot = false,
    this.onCreateTap,
    this.onGroupTap,
  });

  final List<StoryGroup> groups;
  final int? currentUserId;
  final bool showOwnStorySlot;
  final VoidCallback? onCreateTap;
  final void Function(StoryGroup group)? onGroupTap;

  @override
  Widget build(BuildContext context) {
    final ownGroup = currentUserId == null
        ? null
        : groups.where((g) => g.user.id == currentUserId).firstOrNull;

    final others = groups
        .where((g) => currentUserId == null || g.user.id != currentUserId)
        .toList();

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: (showOwnStorySlot ? 1 : 0) + others.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (showOwnStorySlot && index == 0) {
            return _StoryBubble(
              label: 'Your story',
              isOwn: true,
              hasUnviewed: ownGroup?.hasUnviewed ?? false,
              imageUrl: ownGroup?.stories.isNotEmpty == true
                  ? resolveMediaUrl(ownGroup!.stories.last.imageUrl)
                  : null,
              onTap: onCreateTap,
            );
          }
          final group = others[showOwnStorySlot ? index - 1 : index];
          final thumb = group.stories.isNotEmpty
              ? resolveMediaUrl(group.stories.last.imageUrl)
              : null;
          return _StoryBubble(
            label: group.user.fullName.split(' ').first,
            isOwn: false,
            hasUnviewed: group.hasUnviewed,
            imageUrl: thumb,
            onTap: () => onGroupTap?.call(group),
          );
        },
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.label,
    required this.isOwn,
    this.hasUnviewed = false,
    this.imageUrl,
    this.onTap,
  });

  final String label;
  final bool isOwn;
  final bool hasUnviewed;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showRing = !isOwn && hasUnviewed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: showRing
                    ? LinearGradient(
                        colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.85)],
                      )
                    : null,
                border: isOwn || !showRing
                    ? Border.all(
                        color: isOwn ? AppColors.surfaceLight : AppColors.textSecondary.withValues(alpha: 0.35),
                        width: 2,
                      )
                    : null,
              ),
              child: ClipOval(
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _iconFallback(),
                      )
                    : _iconFallback(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconFallback() {
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(
        isOwn ? Icons.add : Icons.person_outline,
        color: isOwn ? AppColors.accent : AppColors.textSecondary,
        size: isOwn ? 26 : 22,
      ),
    );
  }
}
