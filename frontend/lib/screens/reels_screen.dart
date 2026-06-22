import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reels_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/reels/reel_card.dart';
import '../widgets/reels/reel_recipe_sheet.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Vertical reels viewer — full-screen swipe, placeholder content only.
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _hintController;
  late Animation<double> _hintOpacity;
  bool _showSwipeHint = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _hintOpacity = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelsProvider>().fetch(force: true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _dismissSwipeHint() {
    if (!_showSwipeHint) return;
    setState(() => _showSwipeHint = false);
    _hintController.stop();
  }

  void _showPreviewNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video playback will be available in a future update'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReelsProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reels'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (provider.reels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${provider.currentIndex + 1}/${provider.reels.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(ReelsProvider provider) {
    if (provider.loading && provider.reels.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (provider.error != null && provider.reels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppColors.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyState(
                icon: Icons.videocam_off_outlined,
                title: 'Could not load reels',
                subtitle: provider.error,
              ),
              TextButton(
                onPressed: () => provider.fetch(force: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.reels.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.videocam_outlined,
          title: 'No reels yet',
          subtitle: 'Recipe and chef reels will appear here soon.',
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          itemCount: provider.reels.length,
          onPageChanged: (index) {
            provider.setCurrentIndex(index);
            _dismissSwipeHint();
          },
          itemBuilder: (context, index) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: ReelCard(
                key: ValueKey(provider.reels[index].id),
                reel: provider.reels[index],
                onPreviewTap: _showPreviewNotice,
                onRecipeTap: () => showReelRecipeSheet(
                  context,
                  provider.reels[index],
                ),
              ),
            );
          },
        ),
        if (_showSwipeHint && provider.reels.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 120,
            child: FadeTransition(
              opacity: _hintOpacity,
              child: const Center(
                child: _SwipeHint(),
              ),
            ),
          ),
      ],
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white70, size: 20),
          SizedBox(width: 6),
          Text(
            'Swipe for more',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
