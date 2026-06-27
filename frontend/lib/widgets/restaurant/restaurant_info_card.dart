import 'package:flutter/material.dart';

import '../../models/restaurant.dart';
import '../../theme/app_colors.dart';
import '../../utils/preference_display.dart';
import 'restaurant_constants.dart';

class RestaurantInfoCard extends StatelessWidget {
  const RestaurantInfoCard({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    if (restaurant.description != null && restaurant.description!.trim().isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.info_outline,
        title: 'About',
        value: restaurant.description!.trim(),
      ));
    }

    final addressParts = <String>[
      if (restaurant.address != null && restaurant.address!.trim().isNotEmpty)
        restaurant.address!.trim(),
      if (restaurant.city != null && restaurant.city!.trim().isNotEmpty) restaurant.city!.trim(),
    ];
    if (addressParts.isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.location_on_outlined,
        title: 'Address',
        value: addressParts.join(', '),
      ));
    }

    if (restaurant.phoneNumber != null && restaurant.phoneNumber!.trim().isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.phone_outlined,
        title: 'Phone',
        value: restaurant.phoneNumber!.trim(),
      ));
    }

    if (restaurant.tags.isNotEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: restaurant.tags
                .map(
                  (tag) => Chip(
                    label: Text(PreferenceDisplay.cuisineLabel(tag)),
                    backgroundColor: AppColors.accentSubtle,
                    side: BorderSide(color: AppColors.accent.withValues(alpha: 0.35)),
                    labelStyle: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(RestaurantConstants.cardRadius),
          border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.55)),
          boxShadow: AppColors.cardShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant info',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Promotional chips derived from restaurant tags and status.
class RestaurantPromoBadges extends StatelessWidget {
  const RestaurantPromoBadges({super.key, required this.restaurant});

  final Restaurant restaurant;

  List<({String label, IconData icon, Color color})> _badges() {
    final badges = <({String label, IconData icon, Color color})>[];
    final seen = <String>{};

    void add(String label, IconData icon) {
      if (seen.add(label)) {
        badges.add((label: label, icon: icon, color: AppColors.accent));
      }
    }

    if (restaurant.isOpen) add('Open Now', Icons.check_circle_outline);
    if (restaurant.averageRating >= 4.5 && restaurant.totalReviews > 0) {
      add('Top Rated', Icons.star_outline);
    }

    for (final tag in restaurant.tags) {
      final lower = tag.toLowerCase();
      final label = PreferenceDisplay.cuisineLabel(tag);
      if (lower.contains('free') && lower.contains('deliver')) {
        add('Free Delivery', Icons.delivery_dining_outlined);
      } else if (lower.contains('off') || lower.contains('%')) {
        add(label, Icons.local_offer_outlined);
      } else if (lower.contains('best') || lower.contains('seller') || lower.contains('popular')) {
        add(label, Icons.local_fire_department_outlined);
      } else if (lower.contains('fast')) {
        add(label, Icons.bolt_outlined);
      }
    }

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final badges = _badges();
    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: badges.map((b) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: b.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: b.color.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(b.icon, size: 14, color: b.color),
                const SizedBox(width: 6),
                Text(
                  b.label,
                  style: TextStyle(
                    color: b.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
