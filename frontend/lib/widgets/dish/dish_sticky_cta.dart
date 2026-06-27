import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import 'dish_constants.dart';

class DishQuantitySelector extends StatelessWidget {
  const DishQuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.enabled = true,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove,
            onTap: enabled && quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          AnimatedSwitcher(
            duration: DishConstants.animDuration,
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: SizedBox(
              key: ValueKey(quantity),
              width: 36,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add,
            onTap: enabled ? () => onChanged(quantity + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: onTap != null ? AppColors.accent : AppColors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class DishStickyCta extends StatelessWidget {
  const DishStickyCta({
    super.key,
    required this.quantity,
    required this.unitPrice,
    required this.loading,
    required this.enabled,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  final int quantity;
  final double unitPrice;
  final bool loading;
  final bool enabled;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    final subtotal = unitPrice * quantity;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(DishConstants.cardRadius),
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              DishQuantitySelector(
                quantity: quantity,
                enabled: enabled && !loading,
                onChanged: onQuantityChanged,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Subtotal', style: Theme.of(context).textTheme.bodySmall),
                    AnimatedSwitcher(
                      duration: DishConstants.animDuration,
                      child: Text(
                        PriceFormatter.format(subtotal),
                        key: ValueKey(subtotal),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: enabled && !loading ? AppColors.accentGradient : null,
                      color: enabled ? null : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: enabled ? AppColors.accentGlow(alpha: 0.25) : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: enabled && !loading ? onAddToCart : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onAccent,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_shopping_cart_outlined,
                                      color: enabled ? AppColors.onAccent : AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      enabled ? 'Add to Cart' : 'Unavailable',
                                      style: TextStyle(
                                        color: enabled ? AppColors.onAccent : AppColors.textSecondary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
