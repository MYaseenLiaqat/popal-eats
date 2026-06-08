import 'package:flutter/material.dart';

import '../data/community_mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/community_avatar.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Mock friends list.
class FriendsListScreen extends StatelessWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppColors.screenPadding),
        itemCount: mockFriends.length,
        itemBuilder: (context, index) {
          final friend = mockFriends[index];
          final isActive = friend.lastActive == 'Active now';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ModernCard(
              child: Row(
                children: [
                  CommunityAvatar(name: friend.name, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isActive) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              friend.lastActive,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isActive
                                        ? AppColors.green
                                        : null,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
