import 'package:flutter/material.dart';

import '../../models/recommendation.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import '../ui/app_ui_widgets.dart';
import 'home_constants.dart';
import 'home_network_image.dart';

class HomeDishHorizontalCard extends StatefulWidget {
  const HomeDishHorizontalCard({
    super.key,
    required this.recommendation,
    required this.width,
    this.imageUrl,
    this.showTrending = false,
    this.matchPercent,
    this.onTap,
  });

  final Recommendation recommendation;
  final double width;
  final String? imageUrl;
  final bool showTrending;
  final int? matchPercent;
  final VoidCallback? onTap;

  @override
  State<HomeDishHorizontalCard> createState() => _HomeDishHorizontalCardState();
}

class _HomeDishHorizontalCardState extends State<HomeDishHorizontalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lift = _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Transform.translate(
          offset: Offset(0, lift ? -3 : 0),
          child: Transform.scale(
            scale: lift ? 1.02 : 1.0,
            child: AnimatedContainer(
              duration: HomeConstants.animDuration,
              curve: HomeConstants.animCurve,
              width: widget.width,
              decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
            border: Border.all(
              color: lift
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.borderStrong.withValues(alpha: 0.5),
            ),
            boxShadow: lift ? AppColors.cardShadow(elevated: true) : AppColors.cardShadow(),
          ),
          clipBehavior: Clip.antiAlias,
          child: RepaintBoundary(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    HomeNetworkImage(
                      url: widget.imageUrl,
                      height: 130,
                      width: widget.width,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(HomeConstants.cardRadius),
                      ),
                      heroTag: HomeConstants.dishHeroTag(widget.recommendation.dishId),
                    ),
                    if (widget.showTrending)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department, size: 14, color: AppColors.accent),
                              SizedBox(width: 4),
                              Text(
                                'Trending',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.recommendation.calories != null)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            '${widget.recommendation.calories} kcal',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recommendation.dishName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.recommendation.restaurantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            PriceFormatter.format(widget.recommendation.price),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const Spacer(),
                          if (widget.matchPercent != null && widget.matchPercent! >= 70)
                            const AiMatchBadge(compact: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }
}
