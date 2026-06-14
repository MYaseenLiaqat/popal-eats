import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/groups/group_session_card.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'group_invitations_screen.dart';

/// List of active group recommendation sessions.
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchAll(force: true);
    });
  }

  void _openSession(int sessionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDetailScreen(sessionId: sessionId),
      ),
    ).then((_) {
      if (!mounted) return;
      context.read<GroupProvider>().fetchAll(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Sessions'),
        actions: [
          IconButton(
            tooltip: 'Invitations',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupInvitationsScreen()),
            ).then((_) => groups.fetchAll(force: true)),
            icon: Badge(
              isLabelVisible: groups.incomingInvitationCount > 0,
              label: Text('${groups.incomingInvitationCount}'),
              child: const Icon(Icons.mail_outline),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
        ).then((created) {
          if (created == true) groups.fetchGroups(force: true);
        }),
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF1A1400),
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => groups.fetchAll(force: true),
        child: _buildBody(groups),
      ),
    );
  }

  Widget _buildBody(GroupProvider provider) {
    if (provider.loadingGroups && provider.groups.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (provider.groupsError != null && provider.groups.isEmpty) {
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
                  title: 'Could not load groups',
                  subtitle: provider.groupsError,
                ),
                TextButton(
                  onPressed: () => provider.fetchAll(force: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (provider.groups.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          const SizedBox(height: 40),
          const EmptyState(
            icon: Icons.groups_outlined,
            title: 'No group sessions yet',
            subtitle: 'Create a group and invite friends to decide what to eat together',
          ),
          const SizedBox(height: 20),
          GoldActionButton(
            label: 'Create your first group',
            icon: Icons.add,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            ).then((created) {
              if (created == true) provider.fetchGroups(force: true);
            }),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppColors.screenPadding),
      itemCount: provider.groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final session = provider.groups[index];
        return GroupSessionCard(
          session: session,
          onTap: () => _openSession(session.id),
        );
      },
    );
  }
}
