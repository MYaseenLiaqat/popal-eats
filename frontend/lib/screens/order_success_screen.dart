import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'main_shell.dart';

/// Shown after a successful checkout.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order placed')),
      body: Padding(
        padding: const EdgeInsets.all(AppColors.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.green.withValues(alpha: 0.25),
                      AppColors.gold.withValues(alpha: 0.25),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 72,
                  color: AppColors.green,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Order placed successfully!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.gold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for your order',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ModernCard(
              borderColor: AppColors.gold.withValues(alpha: 0.35),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order number',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '#${order.id}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: order.status),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TotalAmountCard(
              label: 'Total paid',
              amount: '\$${order.totalPrice.toStringAsFixed(2)}',
            ),
            const Spacer(),
            GoldActionButton(
              label: 'Continue Shopping',
              icon: Icons.home_outlined,
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (_) => false,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
