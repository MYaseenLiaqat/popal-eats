import 'package:flutter/material.dart';

import '../../models/recommendation.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import '../feed/feed_shimmer.dart';
import '../home/home_section_header.dart';
import 'cart_constants.dart';

class CartAddonsSection extends StatelessWidget {
  const CartAddonsSection({
    super.key,
    required this.items,
    required this.dishImages,
    required this.loading,
    required this.onAdd,
  });

  final List<Recommendation> items;
  final Map<int, String?> dishImages;
  final bool loading;
  final ValueChanged<int> onAdd;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => FeedShimmer(
              borderRadius: CartConstants.cardRadius,
              child: const SizedBox(width: 170, height: 190),
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const HomeSectionHeader(
          title: 'Recommended add-ons',
          subtitle: 'Complete your meal',
          icon: Icons.add_circle_outline,
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final rec = items[index];
              return _AddonCard(
                recommendation: rec,
                imageUrl: dishImages[rec.dishId],
                onAdd: () => onAdd(rec.dishId),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddonCard extends StatefulWidget {
  const _AddonCard({
    required this.recommendation,
    this.imageUrl,
    required this.onAdd,
  });

  final Recommendation recommendation;
  final String? imageUrl;
  final VoidCallback onAdd;

  @override
  State<_AddonCard> createState() => _AddonCardState();
}

class _AddonCardState extends State<_AddonCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Transform.scale(
        scale: _hovered ? 1.03 : 1.0,
        child: Container(
          width: 170,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 90,
                  child: widget.imageUrl != null
                      ? Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const FeedShimmer(child: SizedBox.expand());
                          },
                          errorBuilder: (_, __, ___) => _fallback(),
                        )
                      : _fallback(),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recommendation.dishName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        PriceFormatter.format(widget.recommendation.price),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: widget.onAdd,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                          ),
                          child: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return ColoredBox(
      color: AppColors.accentSubtle,
      child: Icon(Icons.restaurant, color: AppColors.accent.withValues(alpha: 0.5)),
    );
  }
}

class CartOrderSummary extends StatelessWidget {
  const CartOrderSummary({
    super.key,
    required this.subtotal,
    required this.itemCount,
  });

  final double subtotal;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(CartConstants.cardRadius),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          boxShadow: AppColors.cardShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text('$itemCount item${itemCount == 1 ? '' : 's'}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            _line(context, 'Subtotal', PriceFormatter.format(subtotal)),
            _line(context, 'Delivery fee', 'At checkout', muted: true),
            _line(context, 'Service fee', 'At checkout', muted: true),
            _line(context, 'Discount', '—', muted: true),
            _line(context, 'Tax', 'At checkout', muted: true),
            const Divider(height: 24),
            _line(
              context,
              'Total',
              PriceFormatter.format(subtotal),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
    bool muted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: muted ? AppColors.textSecondary : null,
                  fontWeight: emphasize ? FontWeight.w700 : null,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: emphasize ? AppColors.accent : (muted ? AppColors.textSecondary : null),
                  fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class CartCheckoutCta extends StatelessWidget {
  const CartCheckoutCta({
    super.key,
    required this.totalLabel,
    required this.enabled,
    required this.onCheckout,
  });

  final String totalLabel;
  final bool enabled;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(CartConstants.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: enabled ? AppColors.accentGradient : null,
            color: enabled ? null : AppColors.surfaceLight,
          ),
          child: InkWell(
            onTap: enabled ? onCheckout : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Text(
                    totalLabel,
                    style: TextStyle(
                      color: enabled ? AppColors.onAccent : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      color: enabled ? AppColors.onAccent : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: enabled ? AppColors.onAccent : AppColors.textSecondary,
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

class CartEmptyState extends StatelessWidget {
  const CartEmptyState({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentSubtle,
                shape: BoxShape.circle,
                boxShadow: AppColors.accentGlow(alpha: 0.12),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 72,
                color: AppColors.accent.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover restaurants and add your favorite dishes',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.restaurant_outlined),
              label: const Text('Browse Restaurants'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartLoadingSkeleton extends StatelessWidget {
  const CartLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        FeedShimmer(borderRadius: CartConstants.cardRadius, child: const SizedBox(height: 88)),
        const SizedBox(height: 14),
        FeedShimmer(borderRadius: CartConstants.cardRadius, child: const SizedBox(height: 88)),
        const SizedBox(height: 14),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FeedShimmer(borderRadius: CartConstants.cardRadius, child: const SizedBox(height: 118)),
          ),
      ],
    );
  }
}
