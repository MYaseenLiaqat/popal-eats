import 'package:flutter/material.dart';

import '../../models/reel.dart';
import '../../theme/app_colors.dart';
import '../ui/app_ui_widgets.dart';

void showReelRecipeSheet(BuildContext context, Reel reel) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            reel.title,
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 4),
          Text(reel.creatorName, style: Theme.of(ctx).textTheme.bodyMedium),
          if (reel.recipeDescription != null && reel.recipeDescription!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(reel.recipeDescription!, style: Theme.of(ctx).textTheme.bodyLarge),
          ],
          if (reel.calories != null ||
              reel.protein != null ||
              reel.carbs != null ||
              reel.fats != null) ...[
            const SizedBox(height: 20),
            Text('Nutrition preview', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            NutritionGrid(
              calories: reel.calories,
              protein: reel.protein,
              carbs: reel.carbs,
              fats: reel.fats,
            ),
          ],
          if (reel.recipeIngredients.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Ingredients', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...reel.recipeIngredients.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.accent)),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
