import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/friends_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/social/social_user_card.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'search_users_screen.dart';

enum _InviteLoadState { loading, ready, timeout, error }

/// Pick friends to invite into a group session.
class InviteFriendsToGroupScreen extends StatefulWidget {
  const InviteFriendsToGroupScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<InviteFriendsToGroupScreen> createState() =>
      _InviteFriendsToGroupScreenState();
}

class _InviteFriendsToGroupScreenState extends State<InviteFriendsToGroupScreen> {
  final Set<int> _invited = {};
  _InviteLoadState _loadState = _InviteLoadState.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loadState = _InviteLoadState.loading);

    final friends = context.read<FriendsProvider>();
    final groups = context.read<GroupProvider>();

    try {
      await Future.wait([
        friends.fetchFriends(force: true),
      ]).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      setState(() => _loadState = _InviteLoadState.ready);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _loadState = _InviteLoadState.timeout);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadState = _InviteLoadState.error);
    }

    unawaited(groups.fetchInvitations(force: true));
    unawaited(groups.fetchGroupDetail(widget.sessionId, force: true));
  }

  bool _alreadyInvited(int userId, GroupProvider groups) {
    return groups.outgoingInvitations.any(
      (inv) => inv.sessionId == widget.sessionId && inv.receiverId == userId,
    );
  }

  bool _isMember(int userId, GroupProvider groups) {
    final session = groups.selectedGroup;
    if (session == null || session.id != widget.sessionId) return false;
    return session.members.any((m) => m.userId == userId);
  }

  Future<void> _invite(int receiverId, String name) async {
    final provider = context.read<GroupProvider>();
    final ok = await provider.inviteFriend(
      sessionId: widget.sessionId,
      receiverId: receiverId,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _invited.add(receiverId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation sent to $name')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.actionError ?? 'Could not send invitation')),
      );
    }
  }

  Widget _inviteButton({
    required int userId,
    required String name,
    required GroupProvider groups,
  }) {
    final isMember = _isMember(userId, groups);
    final pending = _alreadyInvited(userId, groups) || _invited.contains(userId);

    if (isMember) {
      return Text(
        'Member',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.accent),
      );
    }
    if (pending) return const PendingBadge();

    return FilledButton(
      onPressed: groups.actionLoading ? null : () => _invite(userId, name),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: const Text('Invite'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsProvider>();
    final groups = context.watch<GroupProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Invite Friends')),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: _buildBody(friends, groups),
      ),
    );
  }

  Widget _buildBody(FriendsProvider friends, GroupProvider groups) {
    if (_loadState == _InviteLoadState.loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
        ],
      );
    }

    if (_loadState == _InviteLoadState.timeout) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyState(
                  icon: Icons.timer_outlined,
                  title: 'Request timed out',
                  subtitle: 'Check your connection and try again.',
                ),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ],
      );
    }

    final hasFriends = friends.friends.isNotEmpty;
    final loadFailed = _loadState == _InviteLoadState.error ||
        (friends.friendsError != null && !hasFriends);

    if (loadFailed) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load users',
                  subtitle: friends.friendsError,
                ),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ],
      );
    }

    if (!hasFriends) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          const EmptyState(
            icon: Icons.people_outline,
            title: 'No friends found',
            subtitle: 'Add friends first, then invite them to your group',
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
              ),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Find Friends'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppColors.screenPadding),
      children: [
        Text('Your friends', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...friends.friends.map(
          (friend) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SocialUserCard(
              user: friend,
              trailing: _inviteButton(
                userId: friend.id,
                name: friend.fullName,
                groups: groups,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
