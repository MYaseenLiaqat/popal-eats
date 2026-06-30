import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/friends_provider.dart';
import '../providers/home_feed_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/social/social_user_card.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Friend requests with incoming and outgoing tabs.
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().fetchRequests(force: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _accept(int requestId, String name) async {
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

  Future<void> _reject(int requestId, String name) async {
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

  Widget _buildIncoming(FriendsProvider provider) {
    if (provider.loadingRequests && provider.incomingRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (provider.requestsError != null && provider.incomingRequests.isEmpty) {
      return _errorState(provider.requestsError!, () => provider.fetchRequests(force: true));
    }

    if (provider.incomingRequests.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No incoming requests',
        subtitle: 'When someone adds you, requests appear here',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppColors.screenPadding),
      itemCount: provider.incomingRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final request = provider.incomingRequests[index];
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
                          : () => _reject(request.id, user.fullName),
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
                          : () => _accept(request.id, user.fullName),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelOutgoing(int requestId, String name) async {
    final provider = context.read<FriendsProvider>();
    final ok = await provider.cancelRequest(requestId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancelled request to $name')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.actionError ?? 'Could not cancel request')),
      );
    }
  }

  Widget _buildOutgoing(FriendsProvider provider) {
    if (provider.loadingRequests && provider.outgoingRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (provider.requestsError != null && provider.outgoingRequests.isEmpty) {
      return _errorState(provider.requestsError!, () => provider.fetchRequests(force: true));
    }

    if (provider.outgoingRequests.isEmpty) {
      return const EmptyState(
        icon: Icons.outbound_outlined,
        title: 'No outgoing requests',
        subtitle: 'Search users to send friend requests',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppColors.screenPadding),
      itemCount: provider.outgoingRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final request = provider.outgoingRequests[index];
        final user = request.receiver;
        if (user == null) return const SizedBox.shrink();

        return SocialUserCard(
          user: user,
          trailing: OutlinedButton(
            onPressed: provider.actionLoading
                ? null
                : () => _cancelOutgoing(request.id, user.fullName),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Widget _errorState(String message, VoidCallback onRetry) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load requests',
          subtitle: message,
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(
              text: provider.incomingCount > 0
                  ? 'Incoming (${provider.incomingCount})'
                  : 'Incoming',
            ),
            Tab(
              text: provider.outgoingCount > 0
                  ? 'Sent (${provider.outgoingCount})'
                  : 'Sent',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => provider.fetchRequests(force: true),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildIncoming(provider),
            _buildOutgoing(provider),
          ],
        ),
      ),
    );
  }
}
