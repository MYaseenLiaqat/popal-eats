import 'package:flutter/material.dart';

import '../../models/social_user.dart';
import '../../theme/app_colors.dart';
import '../community_avatar.dart';
import '../ui/app_ui_widgets.dart';

class SocialUserCard extends StatelessWidget {
  const SocialUserCard({
    super.key,
    required this.user,
    this.trailing,
    this.onTap,
    this.compact = false,
    this.useCard = true,
  });

  final UserPublicProfile user;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool compact;
  final bool useCard;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunityAvatar(
          name: user.fullName,
          imageUrl: user.profileImage,
          size: compact ? 44 : 52,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                user.displayHandle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent.withValues(alpha: 0.85),
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!compact && user.role != null && user.role!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  user.roleLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              if (!compact && user.bio != null && user.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  user.bio!.trim(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 116),
              child: trailing!,
            ),
          ),
        ],
      ],
    );

    if (!useCard) return content;
    return ModernCard(onTap: onTap, child: content);
  }
}

class PendingBadge extends StatelessWidget {
  const PendingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        'Pending',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
