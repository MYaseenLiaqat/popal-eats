import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'admin_charts.dart';

/// Computes day-over-day trend from a 7-day timeseries key.
String? seriesTrend(Map<String, dynamic> timeseries, String key) {
  final counts = dailySeriesCounts(timeseries, key);
  if (counts.length < 2) return null;
  final today = counts.last;
  final yesterday = counts[counts.length - 2];
  if (today == 0 && yesterday == 0) return null;
  if (yesterday == 0) return '+$today today';
  final pct = ((today - yesterday) / yesterday * 100).round();
  if (pct == 0) return 'No change';
  return pct > 0 ? '+$pct% vs yesterday' : '$pct% vs yesterday';
}

int ordersToday(Map<String, dynamic> timeseries) {
  final counts = dailySeriesCounts(timeseries, 'orders');
  return counts.isEmpty ? 0 : counts.last;
}

String platformHealthLabel(Map<String, dynamic>? health) {
  if (health == null || health.isEmpty) return 'No data available';
  final db = health['database_status']?.toString() ?? '';
  final backend = health['backend_status']?.toString() ?? '';
  if (db == 'connected' && backend == 'running') return 'Healthy';
  if (db == 'unavailable') return 'Degraded';
  return backend.isNotEmpty ? backend : 'Unknown';
}

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class AdminKpiCard extends StatelessWidget {
  const AdminKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.description,
    this.trend,
    this.trendUp,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? description;
  final String? trend;
  final bool? trendUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trendColor = trendUp == null
        ? AppColors.textSecondary
        : trendUp!
            ? AppColors.accent
            : AppColors.error;

    final card = ModernAdminCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.accent, size: 20),
              ),
              const Spacer(),
              if (trend != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp == true
                          ? Icons.trending_up
                          : trendUp == false
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      size: 14,
                      color: trendColor,
                    ),
                    const SizedBox(width: 2),
                    Text(trend!, style: TextStyle(fontSize: 11, color: trendColor, fontWeight: FontWeight.w600)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(description!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppColors.cardRadius), child: card);
  }
}

class AdminQuickAction {
  const AdminQuickAction({
    required this.label,
    required this.icon,
    required this.section,
    this.badge,
  });

  final String label;
  final IconData icon;
  final dynamic section;
  final int? badge;
}

class AdminQuickActionsPanel extends StatelessWidget {
  const AdminQuickActionsPanel({
    super.key,
    required this.actions,
    required this.onAction,
  });

  final List<AdminQuickAction> actions;
  final void Function(dynamic section) onAction;

  @override
  Widget build(BuildContext context) {
    return ModernAdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 4 : c.maxWidth >= 600 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.4,
                ),
                itemCount: actions.length,
                itemBuilder: (context, i) {
                  final a = actions[i];
                  return Material(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onAction(a.section),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Icon(a.icon, size: 18, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(a.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                            ),
                            if (a.badge != null && a.badge! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('${a.badge}', style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    Color bg;
    Color fg;
    switch (normalized) {
      case 'active':
      case 'approved':
      case 'completed':
      case 'delivered':
        bg = AppColors.accent.withValues(alpha: 0.15);
        fg = AppColors.accent;
        break;
      case 'pending':
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange;
        break;
      case 'suspended':
      case 'rejected':
      case 'cancelled':
      case 'failed':
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        break;
      default:
        bg = AppColors.surfaceLight;
        fg = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class AdminUserRow extends StatelessWidget {
  const AdminUserRow({
    super.key,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    this.imageUrl,
    this.onView,
    this.onSuspend,
    this.onActivate,
    this.trailing,
  });

  final String name;
  final String? username;
  final String email;
  final String role;
  final String status;
  final String createdAt;
  final String? imageUrl;
  final VoidCallback? onView;
  final VoidCallback? onSuspend;
  final VoidCallback? onActivate;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ModernAdminCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null || imageUrl!.isEmpty
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name, style: Theme.of(context).textTheme.titleSmall)),
                    AdminStatusBadge(status: status),
                  ],
                ),
                Text('@${username ?? '—'} · $email', style: Theme.of(context).textTheme.bodySmall),
                Text('$role · Joined $createdAt', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else ...[
            if (onView != null) TextButton(onPressed: onView, child: const Text('View')),
            if (status != 'suspended' && onSuspend != null)
              TextButton(onPressed: onSuspend, child: const Text('Suspend'))
            else if (onActivate != null)
              TextButton(onPressed: onActivate, child: const Text('Activate')),
          ],
        ],
      ),
    );
  }
}

class AdminChartSection extends StatelessWidget {
  const AdminChartSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        child,
      ],
    );
  }
}
