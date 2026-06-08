import 'package:flutter/material.dart';

import '../data/community_mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/community_avatar.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Mock friend requests with local accept/decline actions.
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  late List<MockFriendRequest> _requests;

  @override
  void initState() {
    super.initState();
    _requests = List<MockFriendRequest>.from(mockFriendRequests);
  }

  void _accept(MockFriendRequest req) {
    setState(() => _requests.removeWhere((r) => r.id == req.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You are now friends with ${req.name}')),
    );
  }

  void _decline(MockFriendRequest req) {
    setState(() => _requests.removeWhere((r) => r.id == req.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Declined request from ${req.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friend Requests')),
      body: _requests.isEmpty
          ? const EmptyState(
              icon: Icons.person_add_outlined,
              title: 'No pending requests',
              subtitle: 'New friend requests will appear here',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppColors.screenPadding),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final req = _requests[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ModernCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CommunityAvatar(name: req.name, size: 52),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    req.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${req.mutualFriends} mutual friends',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _decline(req),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: BorderSide(
                                    color: AppColors.surfaceLight
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _accept(req),
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
                    ),
                  ),
                );
              },
            ),
    );
  }
}
