import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/recommendation_copy.dart';
import '../../../widgets/admin/admin_charts.dart';
import '../../../widgets/admin/admin_ui.dart';
import '../../../widgets/ui/app_ui_widgets.dart';
import '../admin_nav.dart';
import '../admin_portal_notifier.dart';
import '../admin_utils.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.onNavigate});

  final ValueChanged<AdminSection> onNavigate;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _admin = AdminService();
  AdminDashboardMetrics? _metrics;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final portal = context.read<AdminPortalNotifier>();
    portal.removeListener(_onPortalChanged);
    portal.addListener(_onPortalChanged);
  }

  @override
  void dispose() {
    context.read<AdminPortalNotifier>().removeListener(_onPortalChanged);
    super.dispose();
  }

  void _onPortalChanged() {
    if (mounted) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      _metrics = await _admin.loadDashboardMetrics();
    } catch (e) {
      _error = RecommendationCopy.friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _pendingRestaurants(AdminDashboardMetrics m) {
    return m.pendingAccounts.where(adminIsRestaurantRole).length;
  }

  int _pendingChefs(AdminDashboardMetrics m) {
    return m.pendingAccounts.where(adminIsHomeChefRole).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _metrics == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null && _metrics == null) {
      return Center(
        child: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Unable to load dashboard',
          subtitle: _error,
        ),
      );
    }

    final m = _metrics!;
    final ts = m.timeseries;
    final today = DateTime.now();
    final dateLabel = '${today.month}/${today.day}/${today.year}';
    final adminName = context.watch<AuthProvider>().user?['full_name']?.toString() ?? 'Admin';
    final healthLabel = platformHealthLabel(m.health);
    final pendingRest = _pendingRestaurants(m);
    final pendingChef = _pendingChefs(m);
    final ordersTodayCount = ordersToday(ts);

    return RefreshIndicator(
      onRefresh: () => _load(),
      color: AppColors.accent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          ModernAdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, $adminName', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text("What requires your attention today · $dateLabel", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Platform summary', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 3 : c.maxWidth >= 600 ? 2 : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  AdminKpiCard(
                    label: 'Pending restaurant approvals',
                    value: '$pendingRest',
                    icon: Icons.storefront_outlined,
                    description: 'Awaiting review',
                    onTap: () => widget.onNavigate(AdminSection.approvals),
                  ),
                  AdminKpiCard(
                    label: 'Pending home chef approvals',
                    value: '$pendingChef',
                    icon: Icons.soup_kitchen_outlined,
                    description: 'Awaiting review',
                    onTap: () => widget.onNavigate(AdminSection.approvals),
                  ),
                  AdminKpiCard(
                    label: 'Orders today',
                    value: '$ordersTodayCount',
                    icon: Icons.shopping_bag_outlined,
                    description: 'Placed today',
                    onTap: () => widget.onNavigate(AdminSection.orders),
                  ),
                  AdminKpiCard(
                    label: 'Platform health',
                    value: healthLabel,
                    icon: Icons.health_and_safety_outlined,
                    description: 'Backend & database',
                    onTap: () => widget.onNavigate(AdminSection.settings),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          AdminQuickActionsPanel(
            onAction: (s) => widget.onNavigate(s as AdminSection),
            actions: [
              AdminQuickAction(label: 'Approve Restaurants', icon: Icons.approval_outlined, section: AdminSection.approvals, badge: pendingRest),
              AdminQuickAction(label: 'Approve Home Chefs', icon: Icons.approval_outlined, section: AdminSection.approvals, badge: pendingChef),
              AdminQuickAction(label: 'View Orders', icon: Icons.receipt_long_outlined, section: AdminSection.orders),
              AdminQuickAction(label: 'User Management', icon: Icons.people_outline, section: AdminSection.customers),
              AdminQuickAction(label: 'Content Moderation', icon: Icons.shield_outlined, section: AdminSection.content),
              AdminQuickAction(label: 'Reports', icon: Icons.flag_outlined, section: AdminSection.reports),
            ],
          ),
          if (m.pendingAccounts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Needs approval now', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(onPressed: () => widget.onNavigate(AdminSection.approvals), child: const Text('Open approvals')),
              ],
            ),
            const SizedBox(height: 8),
            ...m.pendingAccounts.take(3).map(
                  (a) => _PendingPreview(
                    account: a,
                    onOpen: () => widget.onNavigate(AdminSection.approvals),
                  ),
                ),
          ],
          const SizedBox(height: 14),
          Text('Recent notifications', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (m.notifications.isEmpty)
            ModernAdminCard(
              padding: const EdgeInsets.all(12),
              child: Text('No new alerts', style: Theme.of(context).textTheme.bodySmall),
            )
          else
            ...m.notifications.take(5).map((n) => _NotificationRow(notification: n)),
          const SizedBox(height: 14),
          Text('Recent activity', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _ActivityList(
            title: 'Latest registrations',
            items: m.recentUsers.map((u) => '${u['full_name'] ?? u['email']} · ${u['role']}').toList(),
            emptyLabel: 'No recent users',
          ),
        ],
      ),
    );
  }
}

class _PendingPreview extends StatelessWidget {
  const _PendingPreview({required this.account, required this.onOpen});

  final Map<String, dynamic> account;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ModernAdminCard(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          onTap: onOpen,
          child: Row(
            children: [
              Icon(
                adminIsRestaurantRole(account) ? Icons.storefront_outlined : Icons.soup_kitchen_outlined,
                color: AppColors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(adminAccountTitle(account), style: Theme.of(context).textTheme.titleSmall),
                    Text('${account['full_name']} · ${account['role']}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const AdminStatusBadge(status: 'pending'),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification});

  final Map<String, dynamic> notification;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ModernAdminCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.notifications_outlined, size: 18, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification['title']?.toString() ?? 'Notification', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  Text(notification['subtitle']?.toString() ?? '', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            Text(adminFormatDate(notification['created_at']?.toString()), style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.title, required this.items, required this.emptyLabel});

  final String title;
  final List<String> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return ModernAdminCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text(emptyLabel, style: Theme.of(context).textTheme.bodySmall)
          else
            ...items.take(5).map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('· $line', style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
        ],
      ),
    );
  }
}
