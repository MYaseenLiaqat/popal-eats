import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';

class AdminBusinessApprovalsScreen extends StatefulWidget {
  const AdminBusinessApprovalsScreen({super.key});

  @override
  State<AdminBusinessApprovalsScreen> createState() =>
      _AdminBusinessApprovalsScreenState();
}

class _AdminBusinessApprovalsScreenState extends State<AdminBusinessApprovalsScreen> {
  final _admin = AdminService();
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await _admin.listPendingBusinessAccounts();
      _pending = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> account) async {
    await _admin.approveBusinessAccount(account['user_id'] as int);
    _load();
  }

  Future<void> _reject(Map<String, dynamic> account) async {
    await _admin.rejectBusinessAccount(
      account['user_id'] as int,
      reason: 'Does not meet listing requirements',
    );
    _load();
  }

  String _titleFor(Map<String, dynamic> account) {
    final restaurant = account['restaurant'] as Map<String, dynamic>?;
    final chef = account['home_chef'] as Map<String, dynamic>?;
    if (restaurant != null) return restaurant['name']?.toString() ?? 'Restaurant';
    if (chef != null) return chef['display_name']?.toString() ?? 'Home Chef';
    return account['full_name']?.toString() ?? 'Business account';
  }

  String? _subtitleFor(Map<String, dynamic> account) {
    final restaurant = account['restaurant'] as Map<String, dynamic>?;
    final chef = account['home_chef'] as Map<String, dynamic>?;
    if (restaurant != null) {
      return [restaurant['address'], restaurant['cuisine_type']].whereType<String>().join(' · ');
    }
    if (chef != null) {
      return [chef['kitchen_address'], chef['cuisine_specialty']].whereType<String>().join(' · ');
    }
    return account['email']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business approvals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: _pending.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.check_circle_outline,
                          title: 'No pending accounts',
                          subtitle: 'Restaurant and home chef applications are up to date.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppColors.screenPadding),
                      itemCount: _pending.length,
                      itemBuilder: (context, index) {
                        final account = _pending[index];
                        final role = account['role']?.toString() ?? 'business';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ModernCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _titleFor(account),
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        role.replaceAll('_', ' '),
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_subtitleFor(account) != null) ...[
                                  const SizedBox(height: 6),
                                  Text(_subtitleFor(account)!),
                                ],
                                Text(account['email']?.toString() ?? ''),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _reject(account),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: GoldActionButton(
                                        label: 'Approve',
                                        onPressed: () => _approve(account),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
