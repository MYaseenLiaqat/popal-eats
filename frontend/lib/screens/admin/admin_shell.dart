import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import 'admin_nav.dart';
import 'admin_portal_notifier.dart';
import 'pages/admin_ai_page.dart';
import 'pages/admin_analytics_page.dart';
import 'pages/admin_approvals_page.dart';
import 'pages/admin_content_page.dart';
import 'pages/admin_customers_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_home_chefs_page.dart';
import 'pages/admin_orders_page.dart';
import 'pages/admin_profile_page.dart';
import 'pages/admin_reports_page.dart';
import 'pages/admin_restaurants_page.dart';
import 'pages/admin_reviews_page.dart';
import 'pages/admin_settings_page.dart';
import 'admin_search.dart';

/// Responsive admin portal shell with sidebar / drawer navigation.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, this.initialSection});

  final AdminSection? initialSection;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late AdminSection _section;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection ?? AdminSection.dashboard;
  }

  Widget _pageFor(AdminSection section) {
    switch (section) {
      case AdminSection.dashboard:
        return AdminDashboardPage(onNavigate: _select);
      case AdminSection.approvals:
        return const AdminApprovalsPage();
      case AdminSection.restaurants:
        return const AdminRestaurantsPage();
      case AdminSection.homeChefs:
        return const AdminHomeChefsPage();
      case AdminSection.customers:
        return const AdminCustomersPage();
      case AdminSection.content:
        return const AdminContentPage();
      case AdminSection.orders:
        return const AdminOrdersPage();
      case AdminSection.reviews:
        return const AdminReviewsPage();
      case AdminSection.analytics:
        return const AdminAnalyticsPage();
      case AdminSection.ai:
        return const AdminAiPage();
      case AdminSection.reports:
        return const AdminReportsPage();
      case AdminSection.settings:
        return const AdminSettingsPage();
      case AdminSection.profile:
        return AdminProfilePage(onNavigate: _select);
    }
  }

  void _select(AdminSection section) {
    setState(() => _section = section);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminPortalNotifier(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _buildShell(context, constraints);
        },
      ),
    );
  }

  Widget _buildShell(BuildContext context, BoxConstraints constraints) {
    final width = constraints.maxWidth;
        final isDesktop = width >= 1100;
        final isTablet = width >= 720;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                _Sidebar(
                  selected: _section,
                  onSelect: _select,
                  onLogout: _logout,
                  expanded: true,
                ),
                Expanded(child: _contentArea(isDesktop: true)),
              ],
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: Drawer(
            backgroundColor: AppColors.surface,
            child: SafeArea(
              child: _Sidebar(
                selected: _section,
                onSelect: _select,
                onLogout: _logout,
                expanded: true,
                inDrawer: true,
              ),
            ),
          ),
          appBar: AppBar(
            title: Text(_section.label),
            backgroundColor: AppColors.surface,
            actions: [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: () => showAdminGlobalSearch(context),
              ),
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => showAdminNotifications(context),
              ),
              if (isTablet)
                IconButton(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.menu_open),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
          ),
          body: _contentArea(isDesktop: false),
        );
  }

  Widget _contentArea({required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
              color: AppColors.surface,
            ),
            child: Row(
              children: [
                Text(
                  _section.label,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.search),
                  onPressed: () => showAdminGlobalSearch(context),
                ),
                IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => showAdminNotifications(context),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                ),
              ],
            ),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: AppColors.animDuration,
            child: KeyedSubtree(
              key: ValueKey(_section),
              child: _pageFor(_section),
            ),
          ),
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.onSelect,
    required this.onLogout,
    required this.expanded,
    this.inDrawer = false,
  });

  final AdminSection selected;
  final ValueChanged<AdminSection> onSelect;
  final VoidCallback onLogout;
  final bool expanded;
  final bool inDrawer;

  static const _mainSections = [
    AdminSection.dashboard,
    AdminSection.approvals,
    AdminSection.restaurants,
    AdminSection.customers,
    AdminSection.content,
    AdminSection.orders,
    AdminSection.reviews,
    AdminSection.reports,
    AdminSection.analytics,
    AdminSection.ai,
  ];

  static const _bottomSections = [
    AdminSection.settings,
    AdminSection.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: inDrawer ? null : 260,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: inDrawer ? null : const Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Popal Eats',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text('Admin Portal', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text('MANAGEMENT', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 1)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                ..._mainSections.map((s) => _NavTile(
                      section: s,
                      selected: selected == s,
                      expanded: expanded,
                      onTap: () => onSelect(s),
                    )),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: Text('ACCOUNT', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ),
                ..._bottomSections.map((s) => _NavTile(
                      section: s,
                      selected: selected == s,
                      expanded: expanded,
                      onTap: () => onSelect(s),
                    )),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.textSecondary),
            title: const Text('Logout'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.section,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final AdminSection section;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent;
    final fg = selected ? AppColors.accent : AppColors.textSecondary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(section.icon, size: 22, color: fg),
              if (expanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.label,
                    style: TextStyle(
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
