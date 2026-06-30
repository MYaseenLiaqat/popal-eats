import 'package:flutter/material.dart';

import '../screens/cart_screen.dart';

/// Short-lived snackbar shown only immediately after a successful add-to-cart.
class CartPrompt {
  CartPrompt._();

  static const _duration = Duration(seconds: 4);

  static void showAddedToCart(
    BuildContext context, {
    required String itemName,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$itemName added to cart'),
          duration: _duration,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () => _openCart(context),
          ),
        ),
      );
  }

  static void _openCart(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CartScreen()),
    );
  }
}
