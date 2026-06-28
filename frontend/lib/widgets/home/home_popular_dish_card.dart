import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recommendation.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import 'home_constants.dart';
import 'home_network_image.dart';

class HomePopularDishCard extends StatefulWidget {
  const HomePopularDishCard({
    super.key,
    required this.recommendation,
    this.imageUrl,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
  });

  final Recommendation recommendation;
  final String? imageUrl;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  @override
  State<HomePopularDishCard> createState() => _HomePopularDishCardState();
}

class _HomePopularDishCardState extends State<HomePopularDishCard> {
  bool _hovered = false;
  bool _adding = false;

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    final ok = await context.read<CartProvider>().addItem(
          dishId: widget.recommendation.dishId,
        );
    if (!mounted) return;
    setState(() => _adding = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.recommendation.dishName} added to cart')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lift = _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Transform.scale(
          scale: lift ? 1.01 : 1.0,
          child: AnimatedContainer(
            duration: HomeConstants.animDuration,
            curve: HomeConstants.animCurve,
            decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
            border: Border.all(
              color: lift
                  ? AppColors.accent.withValues(alpha: 0.35)
                  : AppColors.borderStrong.withValues(alpha: 0.5),
            ),
            boxShadow: lift ? AppColors.cardShadow(elevated: true) : AppColors.cardShadow(),
          ),
          clipBehavior: Clip.antiAlias,
          child: RepaintBoundary(
            child: Row(
              children: [
                HomeNetworkImage(
                  url: widget.imageUrl,
                  width: 108,
                  height: 108,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(HomeConstants.cardRadius),
                  ),
                  heroTag: HomeConstants.dishHeroTag(widget.recommendation.dishId),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
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
                        const Spacer(),
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
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: widget.onFavoriteToggle,
                              icon: Icon(
                                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: widget.isFavorite ? Colors.redAccent : AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                            _AddButton(loading: _adding, onTap: _addToCart),
                          ],
                        ),
                      ],
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
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent),
                )
              : const Icon(Icons.add, color: AppColors.onAccent, size: 18),
        ),
      ),
    );
  }
}
