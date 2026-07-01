import 'package:flutter/material.dart';

import '../../data/cuisine_catalog.dart';
import '../../theme/app_colors.dart';
import 'home_constants.dart';
import 'home_section_header.dart';

class HomeCuisineStrip extends StatefulWidget {
  const HomeCuisineStrip({
    super.key,
    this.onCuisineTap,
  });

  final ValueChanged<CuisineDefinition?>? onCuisineTap;

  @override
  State<HomeCuisineStrip> createState() => _HomeCuisineStripState();
}

class _HomeCuisineStripState extends State<HomeCuisineStrip> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: 'Cuisines',
          subtitle: 'Explore flavors near you',
          icon: Icons.restaurant_menu_outlined,
        ),
        SizedBox(
          height: 122,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: CuisineCatalog.cuisines.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cuisine = CuisineCatalog.cuisines[index];
              final selected = _selectedIndex == index;
              return _CuisineChip(
                cuisine: cuisine,
                selected: selected,
                onTap: () {
                  final clearing = selected;
                  setState(() => _selectedIndex = clearing ? null : index);
                  widget.onCuisineTap?.call(clearing ? null : cuisine);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CuisineChip extends StatefulWidget {
  const _CuisineChip({
    required this.cuisine,
    required this.selected,
    required this.onTap,
  });

  final CuisineDefinition cuisine;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CuisineChip> createState() => _CuisineChipState();
}

class _CuisineChipState extends State<_CuisineChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lift = widget.selected || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Transform.scale(
          scale: lift ? 1.04 : 1.0,
          child: AnimatedContainer(
            duration: HomeConstants.animDuration,
            curve: HomeConstants.animCurve,
            width: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
              border: Border.all(
                color: widget.selected
                    ? AppColors.accent
                    : AppColors.cardBorder,
                width: widget.selected ? 2 : 1,
              ),
              boxShadow: lift ? AppColors.accentGlow(alpha: 0.22) : AppColors.cardShadow(),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(
                    widget.cuisine.imageAsset,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  color: widget.selected ? AppColors.accentSubtle : AppColors.surface,
                  child: Text(
                    widget.cuisine.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.selected ? AppColors.accent : AppColors.textPrimary,
                    ),
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
