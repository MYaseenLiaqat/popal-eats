import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';

/// Celebration overlay when an order is delivered.
class DeliverySuccessOverlay extends StatefulWidget {
  const DeliverySuccessOverlay({
    super.key,
    required this.order,
    required this.restaurantName,
    this.onRateDelivery,
    this.onRateFood,
    this.onOrderAgain,
    this.onGoHome,
  });

  final Order order;
  final String restaurantName;
  final VoidCallback? onRateDelivery;
  final VoidCallback? onRateFood;
  final VoidCallback? onOrderAgain;
  final VoidCallback? onGoHome;

  static Future<void> show(
    BuildContext context, {
    required Order order,
    required String restaurantName,
    VoidCallback? onRateDelivery,
    VoidCallback? onRateFood,
    VoidCallback? onOrderAgain,
    VoidCallback? onGoHome,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) {
        return DeliverySuccessOverlay(
          order: order,
          restaurantName: restaurantName,
          onRateDelivery: onRateDelivery,
          onRateFood: onRateFood,
          onOrderAgain: onOrderAgain,
          onGoHome: onGoHome,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<DeliverySuccessOverlay> createState() => _DeliverySuccessOverlayState();
}

class _DeliverySuccessOverlayState extends State<DeliverySuccessOverlay>
    with TickerProviderStateMixin {
  late AnimationController _check;
  late AnimationController _confetti;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _check = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _confetti = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _checkScale = CurvedAnimation(parent: _check, curve: Curves.elasticOut);
    _check.forward();
  }

  @override
  void dispose() {
    _check.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _confetti,
            builder: (context, _) => CustomPaint(
              painter: _ConfettiPainter(_confetti.value),
              size: MediaQuery.sizeOf(context),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _checkScale,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.accentGradient,
                        boxShadow: AppColors.accentGlow(alpha: 0.45),
                      ),
                      child: const Icon(Icons.check_rounded, color: AppColors.onAccent, size: 52),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentSubtle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
                    ),
                    child: const Text(
                      'DELIVERED',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enjoy your meal!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.restaurantName} · Order #${widget.order.id}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    PriceFormatter.format(widget.order.totalPrice),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 28),
                  if (widget.onRateDelivery != null) ...[
                    _ActionRow(
                      icon: Icons.delivery_dining_outlined,
                      label: 'Rate Delivery',
                      onTap: widget.onRateDelivery!,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (widget.onRateFood != null) ...[
                    _ActionRow(
                      icon: Icons.restaurant_outlined,
                      label: 'Rate Food',
                      onTap: widget.onRateFood!,
                    ),
                    const SizedBox(height: 10),
                  ],
                  FilledButton(
                    onPressed: widget.onOrderAgain,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Order Again'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: widget.onGoHome,
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.45)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress);

  final double progress;
  final _random = Random(42);
  final _colors = [
    AppColors.accent,
    Colors.amber,
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.orangeAccent,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 48; i++) {
      final x = _random.nextDouble() * size.width;
      final baseY = _random.nextDouble() * size.height;
      final y = (baseY + progress * size.height * 0.35) % size.height;
      final color = _colors[i % _colors.length];
      final paint = Paint()..color = color.withValues(alpha: 0.75);
      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: 6 + _random.nextDouble() * 4,
        height: 10 + _random.nextDouble() * 6,
      );
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(progress * pi * 2 + i);
      canvas.drawRect(rect.shift(-rect.center), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
