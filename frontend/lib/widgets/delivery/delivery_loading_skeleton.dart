import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Shimmer loading placeholder for the delivery tab.
class DeliveryLoadingSkeleton extends StatefulWidget {
  const DeliveryLoadingSkeleton({super.key});

  @override
  State<DeliveryLoadingSkeleton> createState() => _DeliveryLoadingSkeletonState();
}

class _DeliveryLoadingSkeletonState extends State<DeliveryLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return RepaintBoundary(
      child: ListView(
        padding: const EdgeInsets.all(AppColors.screenPadding),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _ShimmerBox(controller: _controller, height: 140, radius: 20),
          const SizedBox(height: 16),
          _ShimmerBox(controller: _controller, height: height * 0.38, radius: 24),
          const SizedBox(height: 16),
          _ShimmerBox(controller: _controller, height: 96, radius: 20),
          const SizedBox(height: 16),
          _ShimmerBox(controller: _controller, height: 120, radius: 20),
          const SizedBox(height: 24),
          _ShimmerBox(controller: _controller, height: 18, width: 140, radius: 8),
          const SizedBox(height: 12),
          for (var i = 0; i < 3; i++) ...[
            _ShimmerBox(controller: _controller, height: 72, radius: 16),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.controller,
    required this.height,
    this.width,
    this.radius = 16,
  });

  final AnimationController controller;
  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          height: height,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + controller.value * 2, 0),
              end: Alignment(1 + controller.value * 2, 0),
              colors: const [
                AppColors.surfaceLight,
                Color(0xFF2A3139),
                AppColors.surfaceLight,
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}
