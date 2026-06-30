import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'delivery_constants.dart';

/// Live rider card with call, chat, and share location actions.
class DeliveryRiderCard extends StatelessWidget {
  const DeliveryRiderCard({
    super.key,
    required this.profile,
    this.riderFeaturesEnabled = false,
    this.onCall,
    this.onChat,
    this.onShareLocation,
  });

  final DeliveryRiderProfile profile;
  final bool riderFeaturesEnabled;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback? onShareLocation;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.55)),
          boxShadow: AppColors.cardShadow(),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.accentSubtle,
                  child: Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'R',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        riderFeaturesEnabled
                            ? '${profile.vehicle} · ${profile.plateNumber}'
                            : 'Restaurant-managed delivery',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.rating} · ${profile.completedDeliveries} deliveries',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!riderFeaturesEnabled)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Your order is delivered by the restaurant team. Contact them via Need Help for updates.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.phone_outlined,
                    label: 'Call',
                    onTap: riderFeaturesEnabled ? onCall : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    onTap: riderFeaturesEnabled ? onChat : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_location_outlined,
                    label: 'Share',
                    onTap: riderFeaturesEnabled ? onShareLocation : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.45)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
