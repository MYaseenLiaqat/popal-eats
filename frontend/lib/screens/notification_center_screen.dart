import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group_session.dart';
import '../models/social_user.dart';
import '../providers/friends_provider.dart';
import '../providers/group_provider.dart';
import '../providers/home_feed_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_display.dart';
import '../widgets/community_avatar.dart';
import '../widgets/social/social_user_card.dart';
import '../widgets/social/user_search_panel.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'friend_requests_screen.dart';
import 'group_detail_screen.dart';
import 'group_invitations_screen.dart';

/// Global social hub: pending requests, group invites, and user search.
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().fetchAll(force: true);
      context.read<GroupProvider>().fetchAll(force: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<FriendsProvider>().fetchAll(force: true),
      context.read<GroupProvider>().fetchAll(force: true),
    ]);
  }

  Future<void> _acceptFriend(int requestId, String name) async {
    final provider = context.read<FriendsProvider>();
    final ok = await provider.acceptRequest(requestId);
    if (!mounted) return;
    if (ok) {
      await context.read<HomeFeedProvider>().fetch(force: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are now friends with $name')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.actionError ?? 'Could not accept request')),
      );
    }
  }

  Future<void> _rejectFriend(int requestId, String name) async {
    final provider = context.read<FriendsProvider>();
    final ok = await provider.rejectRequest(requestId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Declined request from $name')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.actionError ?? 'Could not decline request')),
      );
    }
  }

  Future<void> _acceptGroup(GroupInvitation invitation) async {
    final provider = context.read<GroupProvider>();
    final ok = await provider.acceptInvitation(invitation.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined ${invitation.sessionName ?? 'group'}')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GroupDetailScreen(sessionId: invitation.sessionId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.actionError ?? 'Could not accept invitation')),
      );
    }
  }

  Future<void> _rejectGroup(GroupInvitation invitation) async {
    final provider = context.read<GroupProvider>();
    final ok = await provider.rejectInvitation(invitation.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation declined')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.actionError ?? 'Could not decline invitation')),
      );
    }
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    VoidCallback? onSeeAll,
  }) {
    return SectionHeader(
      title: title,
      subtitle: subtitle,
      trailing: onSeeAll != null
          ? TextButton(onPressed: onSeeAll, child: const Text('See all'))
          : null,
    );
  }

  Widget _friendRequestTile(FriendRequest request, FriendsProvider provider) {
    final user = request.sender;
    if (user == null) return const SizedBox.shrink();

    return ModernCard(
      child: Column(
        children: [
          SocialUserCard(user: user, compact: true, useCard: false),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: provider.actionLoading
                      ? null
                      : () => _rejectFriend(request.id, user.fullName),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(
                      color: AppColors.surfaceLight.withValues(alpha: 0.8),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: provider.actionLoading
                      ? null
                      : () => _acceptFriend(request.id, user.fullName),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupInvitationTile(GroupInvitation invitation, GroupProvider provider) {
    final inviter = invitation.sender;
    final groupName = invitation.sessionName ?? 'Group #${invitation.sessionId}';

    return ModernCard(
      borderColor: AppColors.accent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(groupName, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      DateDisplay.formatShort(invitation.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (inviter != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                CommunityAvatar(
                  name: inviter.fullName,
                  imageUrl: inviter.profileImage,
                  size: 40,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${inviter.fullName} invited you to eat together',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: provider.actionLoading
                      ? null
                      : () => _rejectGroup(invitation),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: provider.actionLoading
                      ? null
                      : () => _acceptGroup(invitation),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                  ),
                  child: const Text('Join group'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final friends = context.watch<FriendsProvider>();
    final groups = context.watch<GroupProvider>();
    final loading = (friends.loadingRequests || groups.loadingInvitations) &&
        friends.incomingRequests.isEmpty &&
        groups.incomingInvitations.isEmpty;

    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final hasFriendRequests = friends.incomingRequests.isNotEmpty;
    final hasGroupInvites = groups.incomingInvitations.isNotEmpty;

    if (!hasFriendRequests && !hasGroupInvites) {
      return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppColors.screenPadding),
          children: [
            ModernCard(
              gradient: AppColors.headerGradient,
              borderColor: AppColors.accent.withValues(alpha: 0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re all caught up',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.accent,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'New friend requests and group invites will show up here.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GoldActionButton(
              label: 'Find people to follow',
              icon: Icons.person_search_outlined,
              onPressed: () => _tabController.animateTo(1),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          if (hasFriendRequests) ...[
            _sectionHeader(
              title: 'Friend requests',
              subtitle: '${friends.incomingCount} waiting for you',
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
              ).then((_) => friends.fetchAll(force: true)),
            ),
            ...friends.incomingRequests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _friendRequestTile(request, friends),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (hasGroupInvites) ...[
            _sectionHeader(
              title: 'Group invitations',
              subtitle: '${groups.incomingInvitationCount} pending',
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GroupInvitationsScreen()),
              ).then((_) => groups.fetchAll(force: true)),
            ),
            ...groups.incomingInvitations.map(
              (invitation) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _groupInvitationTile(invitation, groups),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsProvider>();
    final groups = context.watch<GroupProvider>();
    final pending = friends.incomingCount + groups.incomingInvitationCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            tooltip: 'Search people',
            icon: const Icon(Icons.search),
            onPressed: () => _tabController.animateTo(1),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(
              text: pending > 0 ? 'Requests ($pending)' : 'Requests',
            ),
            const Tab(text: 'Search'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityTab(),
          SizedBox.expand(
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: UserSearchPanel(
                autofocus: false,
                padding: const EdgeInsets.fromLTRB(
                  AppColors.screenPadding,
                  12,
                  AppColors.screenPadding,
                  8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
