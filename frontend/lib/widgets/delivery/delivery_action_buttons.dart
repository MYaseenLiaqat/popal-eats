import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Bottom action buttons for active delivery tracking.
class DeliveryActionButtons extends StatelessWidget {
  const DeliveryActionButtons({
    super.key,
    required this.canCancel,
    this.riderFeaturesEnabled = false,
    this.onCallRider,
    this.onChatRider,
    this.onNeedHelp,
    this.onCancel,
    this.onReportIssue,
  });

  final bool canCancel;
  final bool riderFeaturesEnabled;
  final VoidCallback? onCallRider;
  final VoidCallback? onChatRider;
  final VoidCallback? onNeedHelp;
  final VoidCallback? onCancel;
  final VoidCallback? onReportIssue;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!riderFeaturesEnabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Deliveries are handled by the restaurant — rider chat is not available.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: riderFeaturesEnabled ? onCallRider : null,
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Call Rider'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    disabledBackgroundColor: AppColors.borderStrong.withValues(alpha: 0.35),
                    disabledForegroundColor: AppColors.textSecondary,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: riderFeaturesEnabled ? onChatRider : null,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat Rider'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    disabledForegroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.accent.withValues(alpha: 0.45)),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onNeedHelp,
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('Need Help?'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: canCancel && riderFeaturesEnabled ? onCancel : onReportIssue,
                  icon: Icon(
                    canCancel && riderFeaturesEnabled
                        ? Icons.cancel_outlined
                        : Icons.report_outlined,
                    size: 18,
                    color: canCancel && riderFeaturesEnabled
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                  label: Text(
                    canCancel && riderFeaturesEnabled ? 'Cancel Order' : 'Report Issue',
                    style: TextStyle(
                      color: canCancel && riderFeaturesEnabled
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
