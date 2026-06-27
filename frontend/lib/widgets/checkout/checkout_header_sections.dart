import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'checkout_constants.dart';

class CheckoutHeader extends StatelessWidget {
  const CheckoutHeader({
    super.key,
    this.restaurantName,
    this.orderPreview,
  });

  final String? restaurantName;
  final String? orderPreview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          boxShadow: AppColors.cardShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checkout',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
            ),
            if (restaurantName != null) ...[
              const SizedBox(height: 6),
              Text(
                restaurantName!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            if (orderPreview != null) ...[
              const SizedBox(height: 4),
              Text(
                orderPreview!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CheckoutAddressCard extends StatelessWidget {
  const CheckoutAddressCard({
    super.key,
    required this.controller,
    this.focusNode,
    this.recipientName,
    this.phone,
    this.enabled = true,
    this.error,
    this.onEditFocus,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? recipientName;
  final String? phone;
  final bool enabled;
  final String? error;
  final VoidCallback? onEditFocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
          border: Border.all(
            color: error != null
                ? AppColors.error.withValues(alpha: 0.5)
                : AppColors.borderStrong.withValues(alpha: 0.55),
          ),
          boxShadow: AppColors.cardShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentSubtle,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.location_on_outlined, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delivery address',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                TextButton(onPressed: onEditFocus, child: const Text('Edit')),
              ],
            ),
            if (recipientName != null) ...[
              const SizedBox(height: 10),
              Text(
                recipientName!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            if (phone != null && phone!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(phone!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter your full delivery address',
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
    );
  }
}

class CheckoutDeliveryEta extends StatefulWidget {
  const CheckoutDeliveryEta({super.key, this.etaLabel});

  final String? etaLabel;

  @override
  State<CheckoutDeliveryEta> createState() => _CheckoutDeliveryEtaState();
}

class _CheckoutDeliveryEtaState extends State<CheckoutDeliveryEta>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.etaLabel ?? '30–40 minutes (estimate)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentSubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delivery_dining_outlined, color: AppColors.accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated arrival',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    'Final ETA confirmed after order placement',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
