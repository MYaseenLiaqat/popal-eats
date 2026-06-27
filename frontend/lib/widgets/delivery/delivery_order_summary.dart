import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import 'delivery_constants.dart';

/// Expandable order details — items, fees, address, payment.
class DeliveryOrderSummary extends StatefulWidget {
  const DeliveryOrderSummary({
    super.key,
    required this.order,
    required this.restaurantName,
    required this.itemLabels,
    required this.breakdown,
  });

  final Order order;
  final String restaurantName;
  final Map<int, String> itemLabels;
  final DeliveryOrderBreakdown breakdown;

  @override
  State<DeliveryOrderSummary> createState() => _DeliveryOrderSummaryState();
}

class _DeliveryOrderSummaryState extends State<DeliveryOrderSummary> {
  bool _expanded = false;

  String _itemLabel(int dishId) =>
      widget.itemLabels[dishId]?.isNotEmpty == true ? widget.itemLabels[dishId]! : 'Menu item';

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: AppColors.animDuration,
        curve: AppColors.animCurve,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.55)),
          boxShadow: _expanded ? AppColors.cardShadow(elevated: true) : null,
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order details',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            widget.restaurantName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      PriceFormatter.format(widget.breakdown.total),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppColors.animDuration,
                      child: const Icon(Icons.expand_more, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: AppColors.borderStrong),
                    const SizedBox(height: 8),
                    ...widget.order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}×',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_itemLabel(item.dishId))),
                            Text(PriceFormatter.format(item.price * item.quantity)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    _Line(label: 'Subtotal', value: widget.breakdown.subtotal),
                    _Line(label: 'Delivery fee', value: widget.breakdown.deliveryFee),
                    _Line(label: 'Tax', value: widget.breakdown.tax),
                    const Divider(color: AppColors.borderStrong),
                    _Line(
                      label: 'Total',
                      value: widget.breakdown.total,
                      bold: true,
                      accent: true,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.payment_outlined,
                      label: 'Payment',
                      value: widget.breakdown.paymentMethod,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: widget.order.deliveryAddress,
                    ),
                  ],
                ),
              ),
              crossFadeState:
                  _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: AppColors.animDuration,
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.bold = false,
    this.accent = false,
  });

  final String label;
  final double value;
  final bool bold;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: accent ? AppColors.accent : null,
            ),
          ),
          Text(
            PriceFormatter.format(value),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: accent ? AppColors.accent : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
