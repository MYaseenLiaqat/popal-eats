import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../screens/cart_screen.dart';

/// App bar cart icon with item-count badge.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().itemCount;

    return IconButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      ),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
