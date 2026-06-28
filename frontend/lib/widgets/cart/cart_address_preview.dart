import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'cart_constants.dart';

class CartAddressPreview extends StatelessWidget {
  const CartAddressPreview({
    super.key,
    this.address,
    this.onEdit,
  });

  final String? address;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(CartConstants.cardRadius),
          border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.55)),
          boxShadow: AppColors.cardShadow(),
        ),
        child: Row(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deliver to',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address ?? 'Add delivery address at checkout',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estimated delivery shown at checkout',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onEdit, child: const Text('Edit')),
          ],
        ),
      ),
    );
  }
}
