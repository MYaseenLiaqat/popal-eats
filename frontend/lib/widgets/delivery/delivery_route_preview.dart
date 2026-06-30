import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'delivery_constants.dart';

/// Stylized delivery route preview (no external map SDK).
class DeliveryRoutePreview extends StatelessWidget {
  const DeliveryRoutePreview({
    super.key,
    required this.coordinates,
    required this.routeProgress,
    this.heightFactor = 0.45,
  });

  final DeliveryCoordinates coordinates;
  final double routeProgress;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * heightFactor;
    final mapHeight = height.clamp(220.0, 520.0);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: mapHeight,
          width: double.infinity,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2B1A), AppColors.surfaceLight],
              ),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: _RoutePainter(progress: routeProgress),
                ),
                const Positioned(
                  top: 16,
                  left: 16,
                  child: _MapLegendDot(color: AppColors.accent, label: 'Restaurant'),
                ),
                const Positioned(
                  top: 16,
                  right: 16,
                  child: _MapLegendDot(color: Colors.blueAccent, label: 'You'),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Icon(Icons.delivery_dining, color: Colors.orangeAccent.withValues(alpha: 0.9), size: 32),
                      const SizedBox(height: 4),
                      Text('Live delivery preview', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapLegendDot extends StatelessWidget {
  const _MapLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.2, size.height * 0.72);
    final end = Offset(size.width * 0.78, size.height * 0.28);
    final rider = Offset.lerp(start, end, progress)!;

    final routePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.15, end.dx, end.dy);
    canvas.drawPath(path, routePaint);

    _drawPin(canvas, start, AppColors.accent);
    _drawPin(canvas, end, Colors.blueAccent);
    _drawPin(canvas, rider, Colors.orangeAccent, radius: 10);
  }

  void _drawPin(Canvas canvas, Offset center, Color color, {double radius = 8}) {
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius + 4,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.progress != progress;
}
