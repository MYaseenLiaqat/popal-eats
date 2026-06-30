import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Brand logo asset used across auth, headers, and marketing surfaces.
abstract final class AppAssets {
  static const logo = 'assets/images/app_logo.png';
}

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 80,
    this.showShadow = true,
    this.showRing = true,
  });

  final double size;
  final bool showShadow;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: showRing
            ? Border.all(
                color: AppColors.brandGold.withValues(alpha: 0.55),
                width: 2,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.brandChocolate.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColors.brandGold.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.all(size * 0.06),
      child: ClipOval(
        child: Image.asset(
          AppAssets.logo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.restaurant,
            size: size * 0.45,
            color: AppColors.brandGoldDark,
          ),
        ),
      ),
    );
  }
}
