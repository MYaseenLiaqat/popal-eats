import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/friends_provider.dart';
import '../../providers/group_provider.dart';
import '../../screens/notification_center_screen.dart';
import '../../theme/app_colors.dart';

/// Global activity hub entry — Instagram-style heart with pending badge.
class NotificationHubButton extends StatelessWidget {
  const NotificationHubButton({super.key, this.initialTab = 0});

  final int initialTab;

  static int pendingCount(BuildContext context) {
    final friends = context.watch<FriendsProvider>();
    final groups = context.watch<GroupProvider>();
    return friends.incomingCount + groups.incomingInvitationCount;
  }

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationCenterScreen(initialTab: initialTab),
      ),
    ).then((_) {
      if (!context.mounted) return;
      context.read<FriendsProvider>().fetchAll(force: true);
      context.read<GroupProvider>().fetchAll(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = pendingCount(context);

    return IconButton(
      tooltip: count > 0 ? '$count pending' : 'Activity',
      onPressed: () => _open(context),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 9 ? '9+' : '$count'),
        backgroundColor: AppColors.accent,
        textColor: AppColors.onAccent,
        child: const Icon(Icons.favorite_outline),
      ),
    );
  }
}
