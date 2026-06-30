import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Saved posts from the feed — empty until the user saves content.
class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Posts')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppColors.screenPadding),
          child: EmptyState(
            icon: Icons.bookmark_border,
            title: 'No saved posts yet',
            subtitle: 'Tap save on any post in your feed to collect it here.',
          ),
        ),
      ),
    );
  }
}
