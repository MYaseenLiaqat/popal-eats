import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/admin/admin_charts.dart';
import '../admin_nav.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key, required this.onNavigate});

  final ValueChanged<AdminSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ModernAdminCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                child: const Icon(Icons.admin_panel_settings, color: AppColors.accent, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?['full_name']?.toString() ?? 'Admin', style: Theme.of(context).textTheme.titleLarge),
                    Text(user?['email']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    const Chip(label: Text('Administrator'), visualDensity: VisualDensity.compact),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ModernAdminCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.approval_outlined),
                title: const Text('Business approvals'),
                onTap: () => onNavigate(AdminSection.approvals),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () => onNavigate(AdminSection.settings),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Sign out'),
                onTap: () => context.read<AuthProvider>().logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
