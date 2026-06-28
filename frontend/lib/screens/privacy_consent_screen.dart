import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// First-launch privacy and data-use consent.
class PrivacyConsentScreen extends StatelessWidget {
  const PrivacyConsentScreen({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppColors.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Your privacy matters',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Popal Eats uses your data to personalize food picks and power social features.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: const [
                    _ConsentPoint(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'Taste preferences',
                      body: 'Cuisines and allergies help us recommend dishes you will enjoy.',
                    ),
                    _ConsentPoint(
                      icon: Icons.location_on_outlined,
                      title: 'Location (optional)',
                      body: 'Shared only when you join group sessions — used for nearby restaurant picks.',
                    ),
                    _ConsentPoint(
                      icon: Icons.people_outline,
                      title: 'Social connections',
                      body: 'Friends and groups let you discover and decide on food together.',
                    ),
                    _ConsentPoint(
                      icon: Icons.shield_outlined,
                      title: 'Your control',
                      body: 'You can update preferences anytime from Profile. We never sell your data.',
                    ),
                  ],
                ),
              ),
              GoldActionButton(
                label: 'Agree & Continue',
                icon: Icons.check_circle_outline,
                onPressed: onAccepted,
              ),
              const SizedBox(height: 8),
              Text(
                'By continuing you agree to our data use for recommendations and social features.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentPoint extends StatelessWidget {
  const _ConsentPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
