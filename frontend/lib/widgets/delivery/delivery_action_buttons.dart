import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Bottom action buttons for active delivery tracking.
class DeliveryActionButtons extends StatelessWidget {
  const DeliveryActionButtons({
    super.key,
    required this.canCancel,
    this.onCallRider,
    this.onChatRider,
    this.onNeedHelp,
    this.onCancel,
    this.onReportIssue,
  });

  final bool canCancel;
  final VoidCallback? onCallRider;
  final VoidCallback? onChatRider;
  final VoidCallback? onNeedHelp;
  final VoidCallback? onCancel;
  final VoidCallback? onReportIssue;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCallRider,
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Call Rider'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
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
                  onPressed: onChatRider,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat Rider'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
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
                  onPressed: canCancel ? onCancel : onReportIssue,
                  icon: Icon(
                    canCancel ? Icons.cancel_outlined : Icons.report_outlined,
                    size: 18,
                    color: canCancel ? AppColors.error : AppColors.textSecondary,
                  ),
                  label: Text(
                    canCancel ? 'Cancel Order' : 'Report Issue',
                    style: TextStyle(
                      color: canCancel ? AppColors.error : AppColors.textSecondary,
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
