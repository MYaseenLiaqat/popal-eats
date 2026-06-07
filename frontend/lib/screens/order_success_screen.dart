import 'package:flutter/material.dart';

import '../models/order.dart';
import 'home_screen.dart';

/// Shown after a successful checkout.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order placed')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Order placed successfully!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text('Order #${order.id}'),
            Text('Total: \$${order.totalPrice.toStringAsFixed(2)}'),
            Text('Status: ${order.status}'),
            const Spacer(),
            FilledButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                );
              },
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}
