import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Small circular cuisine thumbnail for dense onboarding grids.
class CuisineThumbnailTile extends StatelessWidget {
  const CuisineThumbnailTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.accent = AppColors.gold,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: selected
                      ? [accent.withValues(alpha: 0.55), accent.withValues(alpha: 0.2)]
                      : [AppColors.surfaceLight, AppColors.surface],
                ),
                border: Border.all(
                  color: selected ? accent : AppColors.surfaceLight.withValues(alpha: 0.7),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    height: 1.1,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
