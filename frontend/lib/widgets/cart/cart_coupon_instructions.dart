import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'cart_constants.dart';

class CartCouponSection extends StatefulWidget {
  const CartCouponSection({super.key});

  @override
  State<CartCouponSection> createState() => _CartCouponSectionState();
}

class _CartCouponSectionState extends State<CartCouponSection> {
  bool _expanded = false;
  bool _applied = false;
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
        duration: CartConstants.animDuration,
        curve: CartConstants.animCurve,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(CartConstants.cardRadius),
          border: Border.all(
            color: _applied
                ? AppColors.accent.withValues(alpha: 0.45)
                : AppColors.borderStrong.withValues(alpha: 0.55),
          ),
          boxShadow: AppColors.cardShadow(),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(CartConstants.cardRadius),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentSubtle,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_offer_outlined, color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _applied ? 'Coupon applied (preview)' : 'Apply coupon',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            _applied
                                ? 'Discount preview only — checkout unchanged'
                                : 'Save on your order',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: CartConstants.animDuration,
                      child: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: CartConstants.animDuration,
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
                          hintText: 'Enter coupon code',
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (_controller.text.trim().isEmpty) return;
                        setState(() => _applied = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coupon preview applied (UI only)'),
                          ),
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

class CartInstructionsField extends StatelessWidget {
  const CartInstructionsField({super.key, required this.controller});

  final TextEditingController controller;

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
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add cooking instructions...',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CartConstants.cardRadius),
                borderSide: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.55)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CartConstants.cardRadius),
                borderSide: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.55)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CartConstants.cardRadius),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
