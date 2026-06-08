import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ModernCard extends StatelessWidget {
  const ModernCard({
    super.key,
    required this.child,
    this.gradient,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  final Widget child;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.surfaceGradient,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(
          color: borderColor ?? AppColors.surfaceLight.withValues(alpha: 0.6),
        ),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        child: content,
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.accent = AppColors.gold,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ModernCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiMatchBadge extends StatelessWidget {
  const AiMatchBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.green.withValues(alpha: 0.25),
            AppColors.gold.withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: compact ? 12 : 14,
            color: AppColors.green,
          ),
          const SizedBox(width: 4),
          Text(
            'AI Match',
            style: TextStyle(
              color: AppColors.green,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.rating,
    this.reviews,
  });

  final double rating;
  final int? reviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (reviews != null) ...[
            const SizedBox(width: 6),
            Text(
              '($reviews)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class DishImageBanner extends StatelessWidget {
  const DishImageBanner({
    super.key,
    this.imageUrl,
    this.height = 200,
  });

  final String? imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.cardRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2418), Color(0xFF1A1A22)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_menu,
        size: 64,
        color: AppColors.gold.withValues(alpha: 0.6),
      ),
    );
  }
}

class NutritionGrid extends StatelessWidget {
  const NutritionGrid({
    super.key,
    this.calories,
    this.protein,
    this.carbs,
    this.fats,
  });

  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fats;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value, Color accent})>[
      if (calories != null)
        (label: 'Calories', value: '$calories kcal', accent: AppColors.gold),
      if (protein != null)
        (
          label: 'Protein',
          value: '${protein!.toStringAsFixed(1)} g',
          accent: AppColors.green,
        ),
      if (carbs != null)
        (
          label: 'Carbs',
          value: '${carbs!.toStringAsFixed(1)} g',
          accent: AppColors.gold,
        ),
      if (fats != null)
        (
          label: 'Fats',
          value: '${fats!.toStringAsFixed(1)} g',
          accent: AppColors.green,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => SizedBox(
              width: (MediaQuery.sizeOf(context).width -
                      AppColors.screenPadding * 2 -
                      8) /
                  2,
              child: ModernCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: item.accent,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class GoldActionButton extends StatelessWidget {
  const GoldActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null ? AppColors.goldGradient : null,
          color: onPressed == null ? AppColors.surfaceLight : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1A1400),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: const Color(0xFF1A1400)),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF1A1400),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.dishName,
    required this.restaurantName,
    required this.price,
    required this.score,
    required this.explanation,
    this.calories,
    this.onTap,
    this.showAiBadge = true,
  });

  final String dishName;
  final String restaurantName;
  final double price;
  final double score;
  final String explanation;
  final int? calories;
  final VoidCallback? onTap;
  final bool showAiBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        onTap: onTap,
        borderColor: AppColors.green.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.green.withValues(alpha: 0.2),
                        AppColors.gold.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    color: AppColors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dishName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (showAiBadge) const AiMatchBadge(compact: true),
                        ],
                      ),
                      if (restaurantName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          restaurantName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (score > 0)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Score ${score.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (calories != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$calories kcal',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            if (explanation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                explanation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.gold,
                      ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileActionCard extends StatelessWidget {
  const ProfileActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor = AppColors.gold,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color iconColor;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        destructive ? AppColors.error : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ModernCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (destructive ? AppColors.error : iconColor)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: destructive ? AppColors.error : iconColor,
              size: 22,
            ),
          ),
          title: Text(title, style: TextStyle(color: titleColor)),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
