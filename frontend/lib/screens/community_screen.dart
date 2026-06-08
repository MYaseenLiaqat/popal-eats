import 'package:flutter/material.dart';

import '../data/community_mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/community_avatar.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'friend_requests_screen.dart';
import 'friends_list_screen.dart';

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

/// Community hub with mock social sections.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final previewRequests = mockFriendRequests.take(2).toList();
    final previewFriends = mockFriends.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: ListView(
        padding: const EdgeInsets.all(AppColors.screenPadding),
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
                        'Connect with friends and share your food journey',
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
            subtitle: '${mockFriendRequests.length} pending',
            trailing: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FriendRequestsScreen(),
                ),
              ),
              child: const Text('View all'),
            ),
          ),
          ...previewRequests.map(
            (req) => Padding(
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
                    CommunityAvatar(name: req.name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${req.mutualFriends} mutual friends',
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
            ),
          ),
          SectionHeader(
            title: 'Friends',
            subtitle: '${mockFriends.length} connected',
            trailing: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendsListScreen()),
              ),
              child: const Text('View all'),
            ),
          ),
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
                    CommunityAvatar(name: friend.name, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            friend.lastActive,
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
    );
  }
}
