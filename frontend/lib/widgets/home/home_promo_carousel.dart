import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'home_constants.dart';

class _PromoSlide {
  const _PromoSlide({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.colors,
    this.icon = Icons.local_offer_outlined,
  });

  final String title;
  final String subtitle;
  final String badge;
  final List<Color> colors;
  final IconData icon;
}

class HomePromoCarousel extends StatefulWidget {
  const HomePromoCarousel({super.key});

  @override
  State<HomePromoCarousel> createState() => _HomePromoCarouselState();
}

class _HomePromoCarouselState extends State<HomePromoCarousel> {
  static const _slides = [
    _PromoSlide(
      title: '30% OFF',
      subtitle: 'Your first order this week',
      badge: 'Limited time',
      colors: [Color(0xFF0D2B1A), Color(0xFF1A3D2E)],
      icon: Icons.percent_rounded,
    ),
    _PromoSlide(
      title: 'Free Delivery',
      subtitle: 'On orders above minimum',
      badge: 'Weekend deal',
      colors: [Color(0xFF142A4A), Color(0xFF161B22)],
      icon: Icons.delivery_dining_outlined,
    ),
    _PromoSlide(
      title: 'Weekend Deals',
      subtitle: 'Save on family bundles',
      badge: 'Popular',
      colors: [Color(0xFF2A1A3D), Color(0xFF161B22)],
      icon: Icons.weekend_outlined,
    ),
    _PromoSlide(
      title: 'Recommended Meals',
      subtitle: 'Curated picks just for you',
      badge: 'For you',
      colors: [Color(0xFF0D2B1A), Color(0xFF21262D)],
      icon: Icons.auto_awesome_outlined,
    ),
  ];

  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % _slides.length;
      _controller.animateToPage(
        next,
        duration: HomeConstants.animDuration,
        curve: HomeConstants.animCurve,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 156,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _PromoCard(slide: slide),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: HomeConstants.animDuration,
              curve: HomeConstants.animCurve,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppColors.accent : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.slide});

  final _PromoSlide slide;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: slide.colors,
          ),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
          boxShadow: AppColors.cardShadow(elevated: true),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                slide.icon,
                size: 120,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      slide.badge,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    slide.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slide.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
