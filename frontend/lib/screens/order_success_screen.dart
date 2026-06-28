import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_colors.dart';
import '../utils/price_formatter.dart';
import '../widgets/checkout/checkout_constants.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'main_shell.dart';

/// Shown after a successful checkout.
class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final Order order;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  static const _estimatedDelivery = '30–40 minutes (estimate)';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.65, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Navigate to Delivery tab for live tracking.
  void _trackOrder() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.findAncestorStateOfType<MainShellState>()?.navigateToTab(MainShellState.deliveryTab);
  }

  void _backToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.findAncestorStateOfType<MainShellState>()?.navigateToTab(MainShellState.homeTab);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppColors.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.28),
                            AppColors.accent.withValues(alpha: 0.12),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.55)),
                        boxShadow: AppColors.accentGlow(alpha: 0.22),
                      ),
                      child: const Icon(Icons.check_rounded, size: 72, color: AppColors.accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _fade,
                child: Text(
                  'Order Placed Successfully',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _fade,
                child: Text(
                  'We\'re preparing your food',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _fade,
                child: ModernCard(
                  borderColor: AppColors.accent.withValues(alpha: 0.35),
                  child: Column(
                    children: [
                      _infoRow(
                        context,
                        icon: Icons.receipt_long_outlined,
                        label: 'Order number',
                        value: '#${order.id}',
                        trailing: StatusBadge(status: order.status),
                      ),
                      const Divider(height: 24),
                      _infoRow(
                        context,
                        icon: Icons.delivery_dining_outlined,
                        label: 'Estimated delivery',
                        value: _estimatedDelivery,
                      ),
                      const Divider(height: 24),
                      _infoRow(
                        context,
                        icon: Icons.payments_outlined,
                        label: 'Total',
                        value: PriceFormatter.format(order.totalPrice),
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _fade,
                child: GoldActionButton(
                  label: 'Track Order',
                  icon: Icons.route_outlined,
                  onPressed: _trackOrder,
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _fade,
                child: OutlinedButton.icon(
                  onPressed: _backToHome,
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Back to Home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CheckoutConstants.cardRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
    bool emphasize = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentSubtle,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
                      color: emphasize ? AppColors.accent : null,
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
