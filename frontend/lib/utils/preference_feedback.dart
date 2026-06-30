import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

void showPreferencesSavedFeedback(BuildContext context, {String? message}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.onAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message ?? 'Preferences saved successfully'),
            ),
          ],
        ),
        backgroundColor: AppColors.accent.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
}
