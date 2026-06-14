import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/friends_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/community_avatar.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'friend_requests_screen.dart';
import 'friends_list_screen.dart';
import 'search_users_screen.dart';

class MockCommunityActivity {
  const MockCommunityActivity({
    required this.message,
    required this.icon,
    this.accent = 0,
  });

  final String message;
  final String icon;
  final int accent;
}

const mockCommunityActivity = [
  MockCommunityActivity(
    message: 'Ahmed liked Healthy Chicken Bowl',
    icon: 'favorite',
  ),
  MockCommunityActivity(
    message: 'Sara completed nutrition goal',
    icon: 'flag',
    accent: 1,
  ),
  MockCommunityActivity(
    message: 'Ali tried Chef Special Pizza',
    icon: 'restaurant',
  ),
  MockCommunityActivity(
    message: 'Fatima shared a new recipe',
    icon: 'share',
    accent: 1,
  ),
];

IconData _activityIcon(String key) {
  switch (key) {
    case 'favorite':
      return Icons.favorite_outline;
    case 'flag':
      return Icons.flag_outlined;
    case 'share':
      return Icons.ios_share_outlined;
    default:
      return Icons.restaurant_outlined;
  }
}

/// Community hub with live friends and requests.
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsProvider>();
    final previewRequests = friends.incomingRequests.take(2).toList();
    final previewFriends = friends.friends.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            tooltip: 'Search users',
            icon: const Icon(Icons.person_search_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
            ).then((_) => friends.fetchAll(force: true)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => friends.fetchAll(force: true),
        child: ListView(
          padding: const EdgeInsets.all(AppColors.screenPadding),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ModernCard(
              gradient: AppColors.headerGradient,
              borderColor: AppColors.green.withValues(alpha: 0.35),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.groups, color: AppColors.green, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your community',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.gold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${friends.friendsCount} friends · ${friends.incomingCount} incoming requests',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SectionHeader(
              title: 'Friend Requests',
              subtitle: friends.incomingCount > 0
                  ? '${friends.incomingCount} pending'
                  : 'No pending incoming',
              trailing: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FriendRequestsScreen(),
                  ),
                ).then((_) => friends.fetchAll(force: true)),
                child: const Text('View all'),
              ),
            ),
            if (friends.loadingRequests && previewRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )
            else if (previewRequests.isEmpty)
              ModernCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add_alt_1_outlined, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Find people to connect with',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                  ],
                ),
              )
            else
              ...previewRequests.map((request) {
                final user = request.sender;
                if (user == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ModernCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FriendRequestsScreen(),
                      ),
                    ),
                    child: Row(
                      children: [
                        CommunityAvatar(
                          name: user.fullName,
                          imageUrl: user.profileImage,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                user.displayHandle,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              }),
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
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )
            else if (previewFriends.isEmpty)
              ModernCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search users to grow your network',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
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
              subtitle: 'Recent updates',
            ),
            ...mockCommunityActivity.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ModernCard(
                  borderColor: activity.accent == 1
                      ? AppColors.green.withValues(alpha: 0.35)
                      : null,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (activity.accent == 1
                                  ? AppColors.green
                                  : AppColors.gold)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _activityIcon(activity.icon),
                          color: activity.accent == 1
                              ? AppColors.green
                              : AppColors.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          activity.message,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
