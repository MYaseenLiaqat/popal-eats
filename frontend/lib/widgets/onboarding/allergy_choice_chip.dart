import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Compact selectable allergy chip.
class AllergyChoiceChip extends StatelessWidget {
  const AllergyChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
      selectedColor: AppColors.accent.withValues(alpha: 0.22),
      checkmarkColor: AppColors.accent,
      side: BorderSide(
        color: selected ? AppColors.accent : AppColors.border,
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
