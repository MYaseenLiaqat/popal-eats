import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import '../../utils/profile_image_url.dart';
import '../feed/feed_shimmer.dart';
import 'cart_constants.dart';

class CartItemCard extends StatefulWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.enabled,
    required this.isFavorite,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
    required this.onFavoriteToggle,
  });

  final CartItem item;
  final bool enabled;
  final bool isFavorite;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;
  final VoidCallback onFavoriteToggle;

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dish = widget.item.dish;
    final name = dish?.name ?? 'Dish #${widget.item.dishId}';
    final unitPrice = dish?.price ?? 0;
    final lineTotal = unitPrice * widget.item.quantity;
    final imageUrl = resolveProfileImageUrl(dish?.image);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Transform.scale(
        scale: _hovered ? 1.005 : 1.0,
        child: AnimatedContainer(
          duration: CartConstants.animDuration,
          curve: CartConstants.animCurve,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(CartConstants.cardRadius),
            border: Border.all(
              color: _hovered
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.borderStrong.withValues(alpha: 0.5),
            ),
            boxShadow: _hovered ? AppColors.cardShadow(elevated: true) : AppColors.cardShadow(),
          ),
          clipBehavior: Clip.antiAlias,
          child: RepaintBoundary(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 108,
                    child: Hero(
                      tag: CartConstants.dishHeroTag(widget.item.dishId),
                      child: Material(
                        type: MaterialType.transparency,
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const FeedShimmer(child: SizedBox.expand());
                                },
                                errorBuilder: (_, __, ___) => _imageFallback(),
                              )
                            : _imageFallback(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: widget.onFavoriteToggle,
                                icon: Icon(
                                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: widget.isFavorite ? Colors.redAccent : AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: widget.enabled ? widget.onRemove : null,
                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${PriceFormatter.format(unitPrice)} each',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              _QuantityControl(
                                quantity: widget.item.quantity,
                                enabled: widget.enabled,
                                onDecrease: widget.onDecrease,
                                onIncrease: widget.onIncrease,
                              ),
                              const Spacer(),
                              AnimatedSwitcher(
                                duration: CartConstants.animDuration,
                                child: Text(
                                  PriceFormatter.format(lineTotal),
                                  key: ValueKey(lineTotal),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _imageFallback() {
    return ColoredBox(
      color: AppColors.accentSubtle,
      child: Icon(Icons.restaurant_menu, color: AppColors.accent.withValues(alpha: 0.55), size: 36),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove, onTap: enabled ? onDecrease : null),
          AnimatedSwitcher(
            duration: CartConstants.animDuration,
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: SizedBox(
              key: ValueKey(quantity),
              width: 32,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          _QtyBtn(icon: Icons.add, onTap: enabled ? onIncrease : null),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: onTap != null ? AppColors.accent : AppColors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
