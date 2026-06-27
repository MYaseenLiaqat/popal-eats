import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/profile_image_url.dart';

class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveProfileImageUrl(imageUrl);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (resolved != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          resolved,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialAvatar(initial),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _initialAvatar(initial);
          },
        ),
      );
    }

    return _initialAvatar(initial);
  }

  Widget _initialAvatar(String initial) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.accentGradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.onAccent,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
