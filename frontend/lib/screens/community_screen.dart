import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/friends_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/community_avatar.dart';
import '../widgets/social/notification_hub_button.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'friends_list_screen.dart';
import 'group_detail_screen.dart';
import 'groups_screen.dart';
import 'notification_center_screen.dart';

/// Community hub — friends, groups, and activity feed.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().fetchAll(force: true);
      context.read<GroupProvider>().fetchAll(force: true);
    });
  }

  void _openActivityHub() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
    ).then((_) {
      if (!mounted) return;
      context.read<FriendsProvider>().fetchAll(force: true);
      context.read<GroupProvider>().fetchAll(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsProvider>();
    final groups = context.watch<GroupProvider>();
    final previewFriends = friends.friends.take(3).toList();
    final pending = friends.incomingCount + groups.incomingInvitationCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: const [NotificationHubButton()],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          await friends.fetchAll(force: true);
          await groups.fetchAll(force: true);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppColors.screenPadding),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ModernCard(
              gradient: AppColors.headerGradient,
              borderColor: AppColors.accent.withValues(alpha: 0.35),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.groups, color: AppColors.accent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your community',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.accent,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${friends.friendsCount} friends · ${groups.groupCount} groups',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (pending > 0) ...[
              const SizedBox(height: 12),
              ModernCard(
                onTap: _openActivityHub,
                borderColor: AppColors.accent.withValues(alpha: 0.35),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$pending new request${pending == 1 ? '' : 's'} — tap to review',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ),
            ],
            SectionHeader(
              title: 'Group Sessions',
              subtitle: groups.incomingInvitationCount > 0
                  ? '${groups.groupCount} groups · ${groups.incomingInvitationCount} invites in Activity'
                  : '${groups.groupCount} active groups',
              trailing: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroupsScreen()),
                ).then((_) => groups.fetchAll(force: true)),
                child: const Text('View all'),
              ),
            ),
            if (groups.groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ModernCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GroupsScreen()),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.group_add_outlined, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create a group to decide what to eat together',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...groups.groups.take(3).map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ModernCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(sessionId: session.id),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.groups, color: AppColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(session.name, style: Theme.of(context).textTheme.titleMedium),
                              Text(
                                '${session.memberCount} members',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SectionHeader(
              title: 'Friends',
              subtitle: '${friends.friendsCount} connected',
              trailing: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FriendsListScreen()),
                ).then((_) => friends.fetchFriends(force: true)),
                child: const Text('View all'),
              ),
            ),
            if (friends.loadingFriends && previewFriends.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (previewFriends.isEmpty)
              ModernCard(
                onTap: _openActivityHub,
                child: Row(
                  children: [
                    const Icon(Icons.person_add_alt_1_outlined, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Find people in Activity → Search',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                  ],
                ),
              )
            else
              ...previewFriends.map(
                (friend) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ModernCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FriendsListScreen()),
                    ),
                    child: Row(
                      children: [
                        CommunityAvatar(
                          name: friend.fullName,
                          imageUrl: friend.profileImage,
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.fullName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                friend.displayHandle,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SectionHeader(
              title: 'Community Activity',
              subtitle: 'From your network',
            ),
            const ModernCard(
              child: EmptyState(
                icon: Icons.dynamic_feed_outlined,
                title: 'Friend activity lives on Home',
                subtitle: 'Posts, stories, and restaurant updates appear in the Home feed.',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
