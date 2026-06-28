import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../cart_icon_button.dart';
import '../community_avatar.dart';
import '../social/notification_hub_button.dart';

class HomeHeroHeader extends StatelessWidget {
  const HomeHeroHeader({
    super.key,
    required this.greeting,
    required this.userName,
    this.location,
    this.avatarUrl,
    this.onProfileTap,
  });

  final String greeting;
  final String userName;
  final String? location;
  final String? avatarUrl;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A2418),
                  Color(0xFF0D1117),
                  Color(0xFF161B22),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -30,
                  child: _blurOrb(120, AppColors.accent.withValues(alpha: 0.18)),
                ),
                Positioned(
                  bottom: -20,
                  left: -40,
                  child: _blurOrb(100, AppColors.accent.withValues(alpha: 0.1)),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.paddingOf(context).top + 12,
                    16,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  greeting,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userName,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const NotificationHubButton(),
                          const SizedBox(width: 4),
                          const CartIconButton(),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onProfileTap,
                            child: CommunityAvatar(
                              name: userName,
                              imageUrl: avatarUrl,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppColors.accent.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location ?? 'Set your delivery location',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: location != null
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.6,
            spreadRadius: size * 0.15,
          ),
        ],
      ),
    );
  }
}
