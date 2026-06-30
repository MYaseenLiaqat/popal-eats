import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dish.dart';
import '../../providers/cart_provider.dart';
import '../../utils/cart_prompt.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import '../../utils/profile_image_url.dart';
import '../feed/feed_shimmer.dart';
import 'restaurant_constants.dart';

class RestaurantDishCard extends StatefulWidget {
  const RestaurantDishCard({
    super.key,
    required this.dish,
    this.isFavorite = false,
    this.isAiRecommended = false,
    this.aiExplanation,
    this.restaurantName,
    this.onTap,
    this.onFavoriteToggle,
  });

  final Dish dish;
  final bool isFavorite;
  final bool isAiRecommended;
  final String? aiExplanation;
  final String? restaurantName;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  @override
  State<RestaurantDishCard> createState() => _RestaurantDishCardState();
}

class _RestaurantDishCardState extends State<RestaurantDishCard> {
  bool _hovered = false;
  bool _adding = false;

  String? get _imageUrl => resolveProfileImageUrl(widget.dish.image);

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    final ok = await context.read<CartProvider>().addItem(dishId: widget.dish.id);
    if (!mounted) return;
    setState(() => _adding = false);
    if (ok) {
      CartPrompt.showAddedToCart(context, itemName: widget.dish.name);
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
            duration: RestaurantConstants.animDuration,
            curve: RestaurantConstants.animCurve,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(RestaurantConstants.cardRadius),
              border: Border.all(
                color: lift
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.borderStrong.withValues(alpha: 0.5),
              ),
              boxShadow: lift ? AppColors.cardShadow(elevated: true) : AppColors.cardShadow(),
            ),
            clipBehavior: Clip.antiAlias,
            child: RepaintBoundary(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 118,
                      child: Hero(
                        tag: RestaurantConstants.dishHeroTag(widget.dish.id),
                        child: Material(
                          type: MaterialType.transparency,
                          child: _imageUrl != null
                              ? Image.network(
                                  _imageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const FeedShimmer(child: SizedBox.expand());
                                  },
                                  errorBuilder: (_, __, ___) => _imageFallback(),
                                )
                              : _imageFallback(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.dish.name,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                if (widget.isAiRecommended)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.accentGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_awesome, size: 12, color: AppColors.onAccent),
                                        SizedBox(width: 4),
                                        Text(
                                          'AI Pick',
                                          style: TextStyle(
                                            color: AppColors.onAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: widget.onFavoriteToggle,
                                  icon: Icon(
                                    widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: widget.isFavorite
                                        ? Colors.redAccent
                                        : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.restaurantName != null &&
                                widget.restaurantName!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.restaurantName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                            if (widget.aiExplanation != null &&
                                widget.aiExplanation!.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.auto_awesome, size: 14, color: AppColors.accent),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.aiExplanation!,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: AppColors.accent,
                                              height: 1.3,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (widget.dish.description != null &&
                                widget.dish.description!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.dish.description!.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (widget.dish.calories != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSubtle,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  '${widget.dish.calories} kcal'
                                  '${widget.dish.protein != null ? ' · ${widget.dish.protein!.toStringAsFixed(0)}g protein' : ''}',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            if (widget.dish.allergens.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: widget.dish.allergens.take(3).map((a) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.error.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, size: 11, color: AppColors.error),
                                        const SizedBox(width: 3),
                                        Text(
                                          a,
                                          style: const TextStyle(
                                            color: AppColors.error,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            const Spacer(),
                            Row(
                              children: [
                                Text(
                                  PriceFormatter.format(widget.dish.price),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const Spacer(),
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
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.accentSubtle,
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_menu,
        color: AppColors.accent.withValues(alpha: 0.55),
        size: 36,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: AppColors.onAccent, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: AppColors.onAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class RestaurantMenuEmpty extends StatelessWidget {
  const RestaurantMenuEmpty({super.key, this.query});

  final String? query;

  @override
  Widget build(BuildContext context) {
    final isSearch = query != null && query!.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            isSearch ? Icons.search_off_outlined : Icons.restaurant_outlined,
            size: 56,
            color: AppColors.accent.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 12),
          Text(
            isSearch ? 'No dishes match your search' : 'No menu items yet',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isSearch ? 'Try a different keyword' : 'This restaurant has not listed dishes yet',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
