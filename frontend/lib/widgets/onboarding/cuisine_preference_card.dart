import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Full-bleed hero cuisine card with gradient text overlay.
class CuisinePreferenceCard extends StatefulWidget {
  const CuisinePreferenceCard({
    super.key,
    required this.label,
    required this.imageAsset,
    required this.selected,
    required this.onTap,
    this.description,
    this.imageAlignment = Alignment.center,
  });

  final String label;
  final String imageAsset;
  final String? description;
  final bool selected;
  final VoidCallback onTap;
  final Alignment imageAlignment;

  static const _radius = 18.0;
  static const _animDuration = Duration(milliseconds: 260);

  @override
  State<CuisinePreferenceCard> createState() => _CuisinePreferenceCardState();
}

class _CuisinePreferenceCardState extends State<CuisinePreferenceCard> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _active => _hovered || widget.selected;

  @override
  Widget build(BuildContext context) {
    final cardScale = _pressed ? 0.98 : 1.0;
    final lift = _hovered && !_pressed ? -7.0 : 0.0;
    final parallax = _hovered && !_pressed ? const Offset(-5, -8) : Offset.zero;
    final overlayAlpha = _hovered ? 0.12 : 0.18;
    final gradientAlpha = _hovered ? 0.72 : 0.80;
    final borderColor = widget.selected
        ? AppColors.accent
        : (_hovered ? AppColors.accent.withValues(alpha: 0.85) : Colors.transparent);
    final borderWidth = widget.selected ? 2.0 : (_hovered ? 1.5 : 0.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: cardScale,
          duration: CuisinePreferenceCard._animDuration,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: CuisinePreferenceCard._animDuration,
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, lift, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CuisinePreferenceCard._radius),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: widget.selected
                      ? AppColors.accent.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: _active ? 0.45 : 0.28),
                  blurRadius: _active ? 22 : 12,
                  offset: Offset(0, _active ? 10 : 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CuisinePreferenceCard._radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRect(
                    child: AnimatedScale(
                      scale: _hovered && !_pressed ? 1.08 : 1.0,
                      duration: CuisinePreferenceCard._animDuration,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: parallax,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.matrix(
                            _brightnessMatrix(_hovered ? 1.08 : 1.0),
                          ),
                          child: Image.asset(
                            widget.imageAsset,
                            fit: BoxFit.cover,
                            alignment: widget.imageAlignment,
                            width: double.infinity,
                            height: double.infinity,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (context, error, stackTrace) {
                              return ColoredBox(
                                color: AppColors.surfaceLight,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: CuisinePreferenceCard._animDuration,
                      color: Colors.black.withValues(alpha: overlayAlpha),
                    ),
                  ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: CuisinePreferenceCard._animDuration,
                        height: 110,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: gradientAlpha),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 21,
                              height: 1.15,
                            ),
                          ),
                          if (widget.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 14,
                                height: 1.25,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.selected)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: AnimatedScale(
                          scale: widget.selected ? 1.0 : 0.0,
                          duration: CuisinePreferenceCard._animDuration,
                          curve: Curves.easeOutCubic,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: AppColors.onAccent,
                              size: 18,
                            ),
                          ),
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

  List<double> _brightnessMatrix(double brightness) {
    return [
      brightness, 0, 0, 0, 0,
      0, brightness, 0, 0, 0,
      0, 0, brightness, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}
