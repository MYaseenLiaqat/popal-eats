import 'package:flutter/material.dart';

import '../../models/group_session.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_display.dart';
import '../community_avatar.dart';
import '../ui/app_ui_widgets.dart';

class GroupSessionCard extends StatelessWidget {
  const GroupSessionCard({
    super.key,
    required this.session,
    this.onTap,
  });

  final GroupSession session;
  final VoidCallback? onTap;

  Color _statusColor() {
    return switch (session.status.toLowerCase()) {
      'active' => AppColors.accent,
      'closed' => AppColors.textSecondary,
      _ => AppColors.accent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final hostName = session.host?.fullName ?? 'Host #${session.hostUserId}';

    return ModernCard(
      onTap: onTap,
      borderColor: session.isActive
          ? AppColors.accent.withValues(alpha: 0.25)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.groups, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Host · $hostName',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${session.memberCount} members',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        session.status.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _statusColor(),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Created ${DateDisplay.formatShort(session.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
        ],
      ),
    );
  }
}

class GroupMemberTile extends StatelessWidget {
  const GroupMemberTile({
    super.key,
    required this.name,
    this.imageUrl,
    this.subtitle,
    this.isHost = false,
  });

  final String name;
  final String? imageUrl;
  final String? subtitle;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ModernCard(
        borderColor: isHost ? AppColors.accent.withValues(alpha: 0.35) : null,
        child: Row(
          children: [
            CommunityAvatar(name: name, imageUrl: imageUrl, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null)
                    Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (isHost)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'HOST',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
