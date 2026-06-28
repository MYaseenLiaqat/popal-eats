import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import '../../utils/profile_image_url.dart';
import '../feed/feed_shimmer.dart';
import 'checkout_constants.dart';

class CheckoutPaymentSection extends StatelessWidget {
  const CheckoutPaymentSection({
    super.key,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final CheckoutPaymentMethod selected;
  final ValueChanged<CheckoutPaymentMethod> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment method',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Checkout uses your existing payment flow (UI preview for card & wallet)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          ...CheckoutPaymentMethod.values.map((method) {
            final isSelected = selected == method;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: enabled ? () => onSelected(method) : null,
                  borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
                  child: AnimatedContainer(
                    duration: CheckoutConstants.animDuration,
                    curve: CheckoutConstants.animCurve,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentSubtle : AppColors.surface,
                      borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.borderStrong.withValues(alpha: 0.55),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected ? AppColors.accentGlow(alpha: 0.1) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(method.icon, color: AppColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            method.label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: CheckoutConstants.animDuration,
                          child: Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            key: ValueKey(isSelected),
                            color: isSelected ? AppColors.accent : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class CheckoutPromoSection extends StatefulWidget {
  const CheckoutPromoSection({super.key});

  @override
  State<CheckoutPromoSection> createState() => _CheckoutPromoSectionState();
}

class _CheckoutPromoSectionState extends State<CheckoutPromoSection> {
  bool _expanded = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AnimatedContainer(
        duration: CheckoutConstants.animDuration,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
          border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.55)),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_outlined, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Promo code',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: CheckoutConstants.animDuration,
                      child: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: CheckoutConstants.animDuration,
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Enter promo code',
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Promo preview only — no backend change')),
                        );
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutInstructionsField extends StatelessWidget {
  const CheckoutInstructionsField({super.key, required this.controller, this.enabled = true});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Special instructions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            enabled: enabled,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any delivery instructions?',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
                borderSide: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.55)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
                borderSide: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.55)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutOrderReview extends StatelessWidget {
  const CheckoutOrderReview({
    super.key,
    this.restaurantName,
    required this.items,
  });

  final String? restaurantName;
  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
          border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.55)),
          boxShadow: AppColors.cardShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order review',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (restaurantName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      restaurantName!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            ...items.map((item) {
              final dish = item.dish;
              final name = dish?.name ?? 'Dish #${item.dishId}';
              final imageUrl = resolveProfileImageUrl(dish?.image);
              final lineTotal = (dish?.price ?? 0) * item.quantity;
              return RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _thumbFallback(),
                                )
                              : _thumbFallback(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('Qty ${item.quantity}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text(
                        PriceFormatter.format(lineTotal),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() {
    return ColoredBox(
      color: AppColors.accentSubtle,
      child: Icon(Icons.restaurant, color: AppColors.accent.withValues(alpha: 0.55), size: 22),
    );
  }
}

class CheckoutOrderSummary extends StatelessWidget {
  const CheckoutOrderSummary({
    super.key,
    required this.subtotal,
    required this.itemCount,
  });

  final double subtotal;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
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
            _line(context, 'Delivery fee', 'Calculated at placement', muted: true),
            _line(context, 'Service fee', 'Calculated at placement', muted: true),
            _line(context, 'Tax', 'Calculated at placement', muted: true),
            _line(context, 'Discount', '—', muted: true),
            const Divider(height: 24),
            _line(context, 'Total', PriceFormatter.format(subtotal), emphasize: true),
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

class CheckoutPlaceOrderCta extends StatelessWidget {
  const CheckoutPlaceOrderCta({
    super.key,
    required this.totalLabel,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String totalLabel;
  final bool loading;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled && !loading ? onPressed : null,
          child: Ink(
            decoration: BoxDecoration(
              gradient: enabled && !loading ? AppColors.accentGradient : null,
              color: enabled && !loading ? null : AppColors.surfaceLight,
            ),
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
                  if (loading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onAccent,
                      ),
                    )
                  else ...[
                    const Text(
                      'Place Order',
                      style: TextStyle(
                        color: AppColors.onAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle_outline, color: AppColors.onAccent),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CheckoutLoadingSkeleton extends StatelessWidget {
  const CheckoutLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        FeedShimmer(borderRadius: CheckoutConstants.cardRadius, child: SizedBox(height: 100)),
        SizedBox(height: 14),
        FeedShimmer(borderRadius: CheckoutConstants.cardRadius, child: SizedBox(height: 140)),
        SizedBox(height: 14),
        FeedShimmer(borderRadius: CheckoutConstants.cardRadius, child: SizedBox(height: 88)),
        SizedBox(height: 14),
        FeedShimmer(borderRadius: CheckoutConstants.cardRadius, child: SizedBox(height: 180)),
      ],
    );
  }
}

class CheckoutEmptyState extends StatelessWidget {
  const CheckoutEmptyState({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.accent.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Add dishes before checking out',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onBack, child: const Text('Back to Cart')),
          ],
        ),
      ),
    );
  }
}

class CheckoutNetworkError extends StatelessWidget {
  const CheckoutNetworkError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.accent.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
