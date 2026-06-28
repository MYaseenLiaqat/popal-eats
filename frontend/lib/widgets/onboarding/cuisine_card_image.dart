import 'package:flutter/material.dart';

/// Rounded food photo for cuisine onboarding cards.
class CuisineCardImage extends StatelessWidget {
  const CuisineCardImage({
    super.key,
    required this.assetPath,
    this.borderRadius = 14,
  });

  final String assetPath;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth * 0.52;
        final size = side.clamp(72.0, constraints.maxHeight);

        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                width: size,
                height: size,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: Colors.black26,
                    child: Icon(
                      Icons.restaurant_menu_outlined,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: size * 0.35,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
