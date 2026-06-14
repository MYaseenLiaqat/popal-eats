import 'package:flutter/material.dart';

import '../../models/group_member_location.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_display.dart';
import '../community_avatar.dart';
import '../ui/app_ui_widgets.dart';

class GroupLocationTile extends StatelessWidget {
  const GroupLocationTile({super.key, required this.location});

  final GroupMemberLocation location;

  @override
  Widget build(BuildContext context) {
    final name = location.user?.fullName ?? 'User #${location.userId}';
    final handle = location.user?.displayHandle;

    return ModernCard(
      borderColor: AppColors.green.withValues(alpha: 0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommunityAvatar(
            name: name,
            imageUrl: location.user?.profileImage,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                if (handle != null)
                  Text(handle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location.coordinatesLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Updated ${DateDisplay.formatRelativeUpdated(location.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GroupLocationsSection extends StatelessWidget {
  const GroupLocationsSection({
    super.key,
    required this.sessionId,
    required this.loading,
    required this.sharing,
    required this.error,
    required this.locations,
    required this.onShare,
    required this.onRefresh,
    required this.onRetry,
  });

  final int sessionId;
  final bool loading;
  final bool sharing;
  final String? error;
  final List<GroupMemberLocation> locations;
  final VoidCallback onShare;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Group Locations',
          subtitle: 'Shared member positions for nearby picks',
        ),
        Row(
          children: [
            Expanded(
              child: GoldActionButton(
                label: sharing ? 'Sharing…' : 'Share My Location',
                icon: Icons.my_location,
                loading: sharing,
                onPressed: sharing ? null : onShare,
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Refresh locations',
              onPressed: loading ? null : onRefresh,
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (error != null && locations.isEmpty)
          Column(
            children: [
              EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load locations',
                subtitle: error,
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          )
        else if (loading && locations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
          )
        else if (locations.isEmpty)
          const EmptyState(
            icon: Icons.location_off_outlined,
            title: 'No members have shared location yet',
            subtitle: 'Tap Share My Location so the group can find nearby restaurants',
          )
        else
          ...locations.map(
            (location) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GroupLocationTile(location: location),
            ),
          ),
      ],
    );
  }
}
