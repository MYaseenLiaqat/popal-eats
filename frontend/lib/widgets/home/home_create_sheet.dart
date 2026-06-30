import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../screens/create_post_screen.dart';
import '../../screens/create_recipe_screen.dart';
import '../../screens/story_viewer_screen.dart';
import '../../screens/upload_reel_screen.dart';

/// Customer content creation options from the Home FAB.
/// Returns true when any content was successfully created.
Future<bool> showHomeCreateSheet(BuildContext context) async {
  final action = await showModalBottomSheet<_HomeCreateAction>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Create', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _CreateOption(
              icon: Icons.auto_stories_outlined,
              title: 'Create Story',
              subtitle: 'Visible for 24 hours',
              onTap: () => Navigator.pop(context, _HomeCreateAction.story),
            ),
            _CreateOption(
              icon: Icons.slow_motion_video_outlined,
              title: 'Upload Reel',
              subtitle: 'Share a food video experience',
              onTap: () => Navigator.pop(context, _HomeCreateAction.reel),
            ),
            _CreateOption(
              icon: Icons.restaurant_outlined,
              title: 'Create Food Post',
              subtitle: 'Photo and caption for your feed',
              onTap: () => Navigator.pop(context, _HomeCreateAction.foodPost),
            ),
            _CreateOption(
              icon: Icons.menu_book_outlined,
              title: 'Share Recipe',
              subtitle: 'Ingredients, steps, and photos',
              onTap: () => Navigator.pop(context, _HomeCreateAction.recipe),
            ),
          ],
        ),
      ),
    ),
  );

  if (!context.mounted || action == null) return false;

  switch (action) {
    case _HomeCreateAction.story:
      return (await showCreateStorySheet(context)) == true;
    case _HomeCreateAction.reel:
      return await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const UploadReelScreen()),
          ) ==
          true;
    case _HomeCreateAction.foodPost:
      return await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          ) !=
          null;
    case _HomeCreateAction.recipe:
      return await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
          ) !=
          null;
  }
}

enum _HomeCreateAction { story, reel, foodPost, recipe }

class _CreateOption extends StatelessWidget {
  const _CreateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.accent),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}