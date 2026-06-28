import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'restaurant_constants.dart';

class RestaurantMenuSearchBar extends StatefulWidget {
  const RestaurantMenuSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  State<RestaurantMenuSearchBar> createState() => _RestaurantMenuSearchBarState();
}

class _RestaurantMenuSearchBarState extends State<RestaurantMenuSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Search dishes in this menu',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accent),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged?.call('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RestaurantConstants.cardRadius),
            borderSide: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.55)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RestaurantConstants.cardRadius),
            borderSide: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.55)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RestaurantConstants.cardRadius),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class RestaurantCategoryTabs extends StatelessWidget {
  const RestaurantCategoryTabs({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: RestaurantConstants.animDuration,
              curve: RestaurantConstants.animCurve,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentSubtle : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.borderStrong.withValues(alpha: 0.55),
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: selected ? AppColors.accentGlow(alpha: 0.12) : null,
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: selected ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RestaurantStickyMenuHeader extends StatelessWidget {
  const RestaurantStickyMenuHeader({
    super.key,
    required this.searchController,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.onSearchChanged,
    required this.onCategorySelected,
  });

  final TextEditingController searchController;
  final List<String> categories;
  final int selectedCategoryIndex;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RestaurantMenuSearchBar(
          controller: searchController,
          onChanged: onSearchChanged,
        ),
        RestaurantCategoryTabs(
          categories: categories,
          selectedIndex: selectedCategoryIndex,
          onSelected: onCategorySelected,
        ),
      ],
    );
  }
}
