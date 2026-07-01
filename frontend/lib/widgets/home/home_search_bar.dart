import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'home_constants.dart';

class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({
    super.key,
    this.onTap,
    this.onFilterTap,
    this.controller,
    this.onChanged,
    this.editable = false,
  });

  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool editable;

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  static const _hints = ['Pizza', 'Biryani', 'Burgers', 'Sushi', 'Desserts'];

  int _hintIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.editable && widget.controller != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search restaurants, dishes, cuisines…',
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.accent.withValues(alpha: 0.9)),
            suffixIcon: widget.onFilterTap != null
                ? IconButton(
                    tooltip: 'Filters',
                    onPressed: widget.onFilterTap,
                    icon: Icon(Icons.tune_rounded, color: AppColors.accent.withValues(alpha: 0.95)),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
              borderSide: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
              borderSide: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.6)),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
              border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                ...AppColors.accentGlow(alpha: 0.08),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.accent.withValues(alpha: 0.9)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search people & restaurants',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: HomeConstants.animDuration,
                          switchInCurve: HomeConstants.animCurve,
                          switchOutCurve: HomeConstants.animCurve,
                          transitionBuilder: (child, animation) => SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.4),
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(opacity: animation, child: child),
                          ),
                          child: Text(
                            _hints[_hintIndex],
                            key: ValueKey(_hints[_hintIndex]),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Filters',
                    onPressed: widget.onFilterTap,
                    icon: Icon(
                      Icons.tune_rounded,
                      color: AppColors.accent.withValues(alpha: 0.95),
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
