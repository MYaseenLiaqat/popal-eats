import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../screens/cart_screen.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import 'restaurant_constants.dart';

class RestaurantFloatingCartBar extends StatelessWidget {
  const RestaurantFloatingCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return AnimatedSwitcher(
      duration: RestaurantConstants.animDuration,
      switchInCurve: RestaurantConstants.animCurve,
      switchOutCurve: RestaurantConstants.animCurve,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: cart.isEmpty
          ? const SizedBox.shrink(key: ValueKey('empty'))
          : SafeArea(
              key: const ValueKey('cart'),
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Material(
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(RestaurantConstants.cardRadius),
                color: AppColors.accent,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: AppColors.onAccent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          PriceFormatter.format(cart.subtotal),
                          style: const TextStyle(
                            color: AppColors.onAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'View Cart →',
                          style: TextStyle(
                            color: AppColors.onAccent,
                            fontWeight: FontWeight.w700,
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
}
