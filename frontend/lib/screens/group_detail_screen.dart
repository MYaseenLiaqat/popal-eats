import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group_session.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_display.dart';
import '../widgets/groups/group_session_card.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'invite_friends_to_group_screen.dart';

/// Group session detail with members and actions.
class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchGroupDetail(widget.sessionId, force: true);
    });
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming in the next update')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupProvider>();
    final session = provider.selectedGroup;

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.name ?? 'Group'),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => provider.fetchGroupDetail(widget.sessionId, force: true),
        child: _buildBody(provider, session),
      ),
    );
  }

  Widget _buildBody(GroupProvider provider, GroupSession? session) {
    if (provider.loadingDetail && session == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (provider.detailError != null && session == null) {
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
                  title: 'Could not load group',
                  subtitle: provider.detailError,
                ),
                TextButton(
                  onPressed: () =>
                      provider.fetchGroupDetail(widget.sessionId, force: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (session == null) return const SizedBox.shrink();

    final hostName = session.host?.fullName ?? 'User #${session.hostUserId}';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppColors.screenPadding),
      children: [
        GroupSessionCard(session: session),
        const SizedBox(height: 16),
        ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Session info', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _infoRow('Status', session.status.toUpperCase()),
              _infoRow('Host', hostName),
              _infoRow('Members', '${session.memberCount}'),
              _infoRow('Created', DateDisplay.formatDateTime(session.createdAt)),
              _infoRow('Expires', DateDisplay.formatDateTime(session.expiresAt)),
              const SizedBox(height: 6),
              Text(
                DateDisplay.formatRelativeExpiry(session.expiresAt),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.green,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SectionHeader(
          title: 'Members',
          subtitle: 'People in this session',
        ),
        ...session.members.map((member) {
          final user = member.user;
          final name = user?.fullName ?? 'User #${member.userId}';
          return GroupMemberTile(
            name: name,
            imageUrl: user?.profileImage,
            subtitle: user?.displayHandle,
            isHost: member.userId == session.hostUserId,
          );
        }),
        const SizedBox(height: 8),
        Text('Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ProfileActionCard(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Invite Friends',
          subtitle: 'Send invitations to your friends list',
          iconColor: AppColors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InviteFriendsToGroupScreen(sessionId: session.id),
            ),
          ),
        ),
        ProfileActionCard(
          icon: Icons.location_on_outlined,
          title: 'Share Location',
          subtitle: 'Help the group find nearby picks',
          onTap: () => _showComingSoon('Location sharing'),
        ),
        ProfileActionCard(
          icon: Icons.restaurant_menu,
          title: 'View Recommendations',
          subtitle: 'See dishes ranked for your group',
          iconColor: AppColors.gold,
          onTap: () => _showComingSoon('Group recommendations'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
