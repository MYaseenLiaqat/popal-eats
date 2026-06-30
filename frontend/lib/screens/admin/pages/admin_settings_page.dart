import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/recommendation_copy.dart';
import '../../../widgets/admin/admin_charts.dart';
import '../../../widgets/admin/admin_ui.dart';
import '../../../widgets/ui/app_ui_widgets.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _admin = AdminService();
  Map<String, dynamic>? _health;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _health = await _admin.platformHealth();
    } catch (e) {
      _error = RecommendationCopy.friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusIcon(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s.contains('connect') || s == 'running' || s == 'active' || s == 'healthy') return 'ok';
    if (s.contains('unavail') || s.contains('error')) return 'error';
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null) {
      return Center(child: EmptyState(icon: Icons.error_outline, title: 'Settings unavailable', subtitle: _error));
    }

    final h = _health ?? {};
    final apiStatus = h['backend_status']?.toString() ?? 'No data available';
    final dbStatus = h['database_status']?.toString() ?? 'No data available';

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AdminPageHeader(title: 'System settings', subtitle: 'Live platform health and version info'),
          ModernAdminCard(
            child: Column(
              children: [
                _statusTile(Icons.cloud_done_outlined, 'Backend status', apiStatus, _statusIcon(apiStatus)),
                const Divider(height: 1),
                _statusTile(Icons.storage_outlined, 'Database status', dbStatus, _statusIcon(dbStatus)),
                const Divider(height: 1),
                _statusTile(Icons.sd_storage_outlined, 'Storage status', 'No data available', 'unknown'),
                const Divider(height: 1),
                _statusTile(
                  Icons.psychology_outlined,
                  'Recommendation engine',
                  h['recommendation_engine_status']?.toString() ?? 'No data available',
                  _statusIcon(h['recommendation_engine_status']?.toString()),
                ),
                const Divider(height: 1),
                _statusTile(Icons.info_outline, 'Platform version', h['platform_version']?.toString() ?? 'No data available', 'ok'),
                const Divider(height: 1),
                _statusTile(Icons.api_outlined, 'API status', apiStatus == 'running' ? 'Healthy' : apiStatus, _statusIcon(apiStatus)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTile(IconData icon, String title, String value, String state) {
    final color = state == 'ok'
        ? AppColors.accent
        : state == 'error'
            ? AppColors.error
            : AppColors.textSecondary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.accent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state == 'ok' ? Icons.check_circle : state == 'error' ? Icons.error_outline : Icons.help_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
