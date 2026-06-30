import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Saved recipes — empty until the user saves recipe posts.
class SavedRecipesScreen extends StatelessWidget {
  const SavedRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Recipes')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppColors.screenPadding),
          child: EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No saved recipes yet',
            subtitle: 'Save recipe posts from home chefs to find them here.',
          ),
        ),
      ),
    );
  }
}
