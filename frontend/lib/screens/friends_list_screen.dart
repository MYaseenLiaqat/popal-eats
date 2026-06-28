import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/friends_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/social/social_user_card.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Friends list backed by GET /friends.
class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().fetchFriends(force: true);
    });
  }

  Future<void> _confirmRemove(String name, int friendId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove friend?'),
        content: Text('Remove $name from your friends list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<FriendsProvider>();
    final ok = await provider.removeFriend(friendId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed $name')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.actionError ?? 'Could not remove friend')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => provider.fetchFriends(force: true),
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(FriendsProvider provider) {
    if (provider.loadingFriends && provider.friends.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (provider.friendsError != null && provider.friends.isEmpty) {
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
                  subtitle: provider.friendsError,
                ),
                TextButton(
                  onPressed: () => provider.fetchFriends(force: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (provider.friends.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.people_outline,
            title: 'No friends yet',
            subtitle: 'Search users and send friend requests to connect',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppColors.screenPadding),
      itemCount: provider.friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final friend = provider.friends[index];
        return SocialUserCard(
          user: friend,
          trailing: IconButton(
            tooltip: 'Remove friend',
            onPressed: provider.actionLoading
                ? null
                : () => _confirmRemove(friend.fullName, friend.id),
            icon: Icon(
              Icons.person_remove_outlined,
              color: AppColors.error.withValues(alpha: 0.85),
            ),
          ),
        );
      },
    );
  }
}
