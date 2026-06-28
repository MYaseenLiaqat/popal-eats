import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/friends_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/social/social_user_card.dart';
import '../widgets/ui/app_ui_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().fetchFriends(force: true);
      context.read<GroupProvider>().fetchInvitations(force: true);
      context.read<GroupProvider>().fetchGroupDetail(widget.sessionId, force: true);
    });
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

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsProvider>();
    final groups = context.watch<GroupProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Invite Friends')),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          await friends.fetchFriends(force: true);
          await groups.fetchInvitations(force: true);
        },
        child: _buildBody(friends, groups),
      ),
    );
  }

  Widget _buildBody(FriendsProvider friends, GroupProvider groups) {
    if (friends.loadingFriends && friends.friends.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (friends.friendsError != null && friends.friends.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load friends',
                  subtitle: friends.friendsError,
                ),
                TextButton(
                  onPressed: () => friends.fetchFriends(force: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (friends.friends.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.people_outline,
            title: 'No friends to invite',
            subtitle: 'Add friends first, then invite them to your group',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppColors.screenPadding),
      itemCount: friends.friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final friend = friends.friends[index];
        final isMember = _isMember(friend.id, groups);
        final pending = _alreadyInvited(friend.id, groups) || _invited.contains(friend.id);

        Widget trailing;
        if (isMember) {
          trailing = Text(
            'Member',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.accent),
          );
        } else if (pending) {
          trailing = const PendingBadge();
        } else {
          trailing = FilledButton(
            onPressed: groups.actionLoading ? null : () => _invite(friend.id, friend.fullName),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
            ),
            child: const Text('Invite'),
          );
        }

        return SocialUserCard(user: friend, trailing: trailing);
      },
    );
  }
}
