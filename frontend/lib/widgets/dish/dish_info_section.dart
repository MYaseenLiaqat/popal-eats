import 'package:flutter/material.dart';

import '../../models/dish.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import '../ui/app_ui_widgets.dart';
import 'dish_constants.dart';

class DishInfoHeader extends StatelessWidget {
  const DishInfoHeader({
    super.key,
    required this.dish,
    this.restaurantName,
    this.restaurantRating = 0,
    this.restaurantReviewCount = 0,
    this.onRestaurantTap,
  });

  final Dish dish;
  final String? restaurantName;
  final double restaurantRating;
  final int restaurantReviewCount;
  final VoidCallback? onRestaurantTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dish.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
          ),
          if (restaurantName != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onRestaurantTap,
              child: Text(
                restaurantName!,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                PriceFormatter.format(dish.price),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              if (restaurantRating > 0)
                RatingBadge(rating: restaurantRating, reviews: restaurantReviewCount),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: dish.isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
                label: dish.isAvailable ? 'Available' : 'Unavailable',
                color: dish.isAvailable ? AppColors.accent : AppColors.error,
              ),
              if (dish.cuisine != null && dish.cuisine!.trim().isNotEmpty)
                _InfoChip(icon: Icons.restaurant_menu_outlined, label: dish.cuisine!.trim()),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class DishExpandableDescription extends StatefulWidget {
  const DishExpandableDescription({super.key, required this.text});

  final String text;

  @override
  State<DishExpandableDescription> createState() => _DishExpandableDescriptionState();
}

class _DishExpandableDescriptionState extends State<DishExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            duration: DishConstants.animDuration,
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Text(
              widget.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            secondChild: Text(
              widget.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
          if (widget.text.length > 120)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Show less' : 'Read more'),
            ),
        ],
      ),
    );
  }
}
