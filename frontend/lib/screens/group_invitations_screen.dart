import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group_session.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_display.dart';
import '../widgets/community_avatar.dart';
import '../widgets/social/social_user_card.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'group_detail_screen.dart';

/// Incoming and outgoing group session invitations.
class GroupInvitationsScreen extends StatefulWidget {
  const GroupInvitationsScreen({super.key});

  @override
  State<GroupInvitationsScreen> createState() => _GroupInvitationsScreenState();
}

class _GroupInvitationsScreenState extends State<GroupInvitationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchInvitations(force: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _accept(GroupInvitation invitation) async {
    final provider = context.read<GroupProvider>();
    final ok = await provider.acceptInvitation(invitation.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${invitation.sessionName ?? 'group'}'),
        ),
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

  Future<void> _reject(GroupInvitation invitation) async {
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

  Widget _invitationCard(GroupInvitation invitation, {required bool incoming}) {
    final inviter = invitation.sender;
    final groupName = invitation.sessionName ?? 'Group #${invitation.sessionId}';
    final hostName = invitation.sessionHost?.fullName;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups, color: AppColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(groupName, style: Theme.of(context).textTheme.titleMedium),
                    if (hostName != null)
                      Text('Host · $hostName', style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      DateDisplay.formatShort(invitation.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!incoming) const PendingBadge(),
            ],
          ),
          if (incoming && inviter != null) ...[
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
                    '${inviter.fullName} invited you',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reject(invitation),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _accept(invitation),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: const Color(0xFF0A1F12),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTab(List<GroupInvitation> items, {required bool incoming}) {
    final provider = context.watch<GroupProvider>();

    if (provider.loadingInvitations && items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (provider.invitationsError != null && items.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load invitations',
            subtitle: provider.invitationsError,
          ),
          TextButton(
            onPressed: () => provider.fetchInvitations(force: true),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return EmptyState(
        icon: incoming ? Icons.inbox_outlined : Icons.outbound_outlined,
        title: incoming ? 'No incoming invitations' : 'No sent invitations',
        subtitle: incoming
            ? 'Group invites from friends appear here'
            : 'Invite friends from a group session',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppColors.screenPadding),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _invitationCard(items[index], incoming: incoming),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Invitations'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(
              text: provider.incomingInvitationCount > 0
                  ? 'Incoming (${provider.incomingInvitationCount})'
                  : 'Incoming',
            ),
            Tab(
              text: provider.outgoingInvitationCount > 0
                  ? 'Sent (${provider.outgoingInvitationCount})'
                  : 'Sent',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => provider.fetchInvitations(force: true),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTab(provider.incomingInvitations, incoming: true),
            _buildTab(provider.outgoingInvitations, incoming: false),
          ],
        ),
      ),
    );
  }
}
