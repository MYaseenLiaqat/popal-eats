import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reels_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/reels/reel_card.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Vertical reels viewer — architecture shell without video playback.
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelsProvider>().fetch(force: true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showPreviewNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video playback will be available in a future update'),
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

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: provider.reels.length,
      onPageChanged: provider.setCurrentIndex,
      itemBuilder: (context, index) {
        return ReelCard(
          reel: provider.reels[index],
          onPreviewTap: _showPreviewNotice,
        );
      },
    );
  }
}
