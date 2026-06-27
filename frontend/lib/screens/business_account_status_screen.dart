import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Pending, rejected, or suspended state for restaurant / home chef accounts.
class BusinessAccountStatusScreen extends StatelessWidget {
  const BusinessAccountStatusScreen({
    super.key,
    required this.status,
    this.rejectionReason,
    required this.roleLabel,
  });

  final String status;
  final String? rejectionReason;
  final String roleLabel;

  bool get _isPending => status == 'pending';
  bool get _isRejected => status == 'rejected';
  bool get _isSuspended => status == 'suspended';

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, accent) = _content();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppColors.screenPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ModernCard(
                borderColor: accent.withValues(alpha: 0.45),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(icon, size: 56, color: accent),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_isPending) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Estimated review time',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '24–48 hours',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We will notify you once your $roleLabel account is approved.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_isRejected && rejectionReason != null && rejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reason',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.error,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(rejectionReason!, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                    if (_isRejected || _isSuspended) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Contact support at support@popaleats.com if you have questions.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => context.read<AuthProvider>().logout(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  (IconData, String, String, Color) _content() {
    if (_isPending) {
      return (
        Icons.hourglass_top_outlined,
        'Application Submitted',
        'Your $roleLabel account is currently under review.',
        AppColors.accent,
      );
    }
    if (_isRejected) {
      return (
        Icons.cancel_outlined,
        'Application Rejected',
        'Unfortunately we could not approve your $roleLabel application at this time.',
        AppColors.error,
      );
    }
    return (
      Icons.block_outlined,
      'Account Suspended',
      'Your $roleLabel account has been suspended. Please contact support.',
      AppColors.error,
    );
  }
}
