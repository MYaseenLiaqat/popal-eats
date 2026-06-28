import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group_member_location.dart';
import '../models/group_session.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_display.dart';
import '../widgets/groups/group_locations_section.dart';
import '../widgets/groups/group_session_card.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'group_decision_screen.dart';
import 'group_recommendations_screen.dart';
import 'invite_friends_to_group_screen.dart';

/// Group session detail with members, locations, and actions.
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll({bool force = true}) async {
    final provider = context.read<GroupProvider>();
    await provider.fetchGroupDetail(widget.sessionId, force: force);
    if (!mounted) return;
    await provider.loadLocations(widget.sessionId, force: force);
  }

  Future<void> _shareMyLocation() async {
    final provider = context.read<GroupProvider>();
    final ok = await provider.shareMyLocation(widget.sessionId);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location shared with the group')),
      );
      return;
    }

    final message = provider.locationActionError ?? 'Could not share location';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    if (provider.locationActionError != null &&
        provider.locationActionError!.contains('permanently denied')) {
      _showPermissionDialog(openSettings: true);
    } else if (provider.locationActionError != null &&
        provider.locationActionError!.contains('turned off')) {
      _showPermissionDialog(openSettings: false, locationServices: true);
    }
  }

  Future<void> _showPermissionDialog({
    required bool openSettings,
    bool locationServices = false,
  }) async {
    final provider = context.read<GroupProvider>();
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locationServices ? 'Enable location services' : 'Location permission needed'),
        content: Text(
          locationServices
              ? 'Turn on location services to share your position with the group.'
              : 'Allow location access so your group can find nearby restaurant picks.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(openSettings ? 'Open settings' : 'Open location settings'),
          ),
        ],
      ),
    );
    if (open != true || !mounted) return;
    if (openSettings) {
      await provider.locationService.openAppSettings();
    } else {
      await provider.locationService.openLocationSettings();
    }
  }

  void _openRecommendations(GroupSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupRecommendationsScreen(
          sessionId: session.id,
          groupName: session.name,
        ),
      ),
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
        color: AppColors.accent,
        onRefresh: () => _loadAll(force: true),
        child: _buildBody(provider, session),
      ),
    );
  }

  Widget _buildBody(GroupProvider provider, GroupSession? session) {
    if (provider.loadingDetail && session == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
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
                  onPressed: () => _loadAll(force: true),
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
    final locations = provider.locationsSessionId == session.id
        ? provider.memberLocations
        : <GroupMemberLocation>[];

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
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        GroupLocationsSection(
          sessionId: session.id,
          loading: provider.loadingLocations,
          sharing: provider.sharingLocation,
          error: provider.locationsError,
          locations: locations,
          onShare: _shareMyLocation,
          onRefresh: () => provider.loadLocations(session.id, force: true),
          onRetry: () => provider.loadLocations(session.id, force: true),
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
          iconColor: AppColors.accent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InviteFriendsToGroupScreen(sessionId: session.id),
            ),
          ),
        ),
        ProfileActionCard(
          icon: Icons.restaurant_menu,
          title: 'View Recommendations',
          subtitle: 'See dishes ranked for your group',
          iconColor: AppColors.accent,
          onTap: () => _openRecommendations(session),
        ),
        ProfileActionCard(
          icon: Icons.how_to_vote_outlined,
          title: 'Group Decision',
          subtitle: 'Consensus status and agreed pick',
          iconColor: AppColors.accent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupDecisionScreen(
                sessionId: session.id,
                groupName: session.name,
              ),
            ),
          ),
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
