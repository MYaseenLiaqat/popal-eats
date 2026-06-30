import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/admin/admin_charts.dart';
import '../../../widgets/admin/admin_ui.dart';
import '../../../widgets/ui/app_ui_widgets.dart';
import '../admin_utils.dart';

class AdminHomeChefsPage extends StatefulWidget {
  const AdminHomeChefsPage({super.key});

  @override
  State<AdminHomeChefsPage> createState() => _AdminHomeChefsPageState();
}

class _AdminHomeChefsPageState extends State<AdminHomeChefsPage> {
  final _admin = AdminService();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  String _statusFilter = 'active';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _admin.listBusinessAccounts(
        role: 'home_chef',
        accountStatus: _statusFilter,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((a) {
      final chef = a['home_chef'] as Map<String, dynamic>?;
      final name = chef?['display_name']?.toString().toLowerCase() ?? '';
      final email = a['email']?.toString().toLowerCase() ?? '';
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminPageHeader(
          title: 'Home chefs',
          subtitle: 'Approved home chefs only — pending applications are in Business Approvals',
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search home chefs',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _statusFilter = v);
                  _load();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  child: _filtered.isEmpty
                      ? ListView(children: const [SizedBox(height: 80), EmptyState(icon: Icons.soup_kitchen_outlined, title: 'No home chefs', subtitle: '')])
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => _ChefCard(
                            account: _filtered[i],
                            onChanged: _load,
                            admin: _admin,
                          ),
                        ),
                ),
        ),
      ],
    );
  }
}

class _ChefCard extends StatelessWidget {
  const _ChefCard({required this.account, required this.onChanged, required this.admin});

  final Map<String, dynamic> account;
  final Future<void> Function() onChanged;
  final AdminService admin;

  @override
  Widget build(BuildContext context) {
    final chef = account['home_chef'] as Map<String, dynamic>?;
    final status = account['account_status']?.toString() ?? '—';
    final userId = account['user_id'] as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ModernAdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chef?['display_name']?.toString() ?? adminAccountTitle(account), style: Theme.of(context).textTheme.titleSmall),
            Text(account['email']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall),
            Text('${chef?['cuisine_specialty'] ?? ''} · ${chef?['kitchen_address'] ?? ''}', style: Theme.of(context).textTheme.bodySmall),
            Chip(label: Text(status), visualDensity: VisualDensity.compact),
            Wrap(
              spacing: 8,
              children: [
                if (status == 'active')
                  TextButton(
                    onPressed: () async {
                      await admin.suspendBusinessAccount(userId, reason: 'Suspended by admin');
                      await onChanged();
                    },
                    child: const Text('Suspend'),
                  ),
                if (status == 'suspended' || status == 'rejected')
                  TextButton(
                    onPressed: () async {
                      await admin.reactivateBusinessAccount(userId);
                      await onChanged();
                    },
                    child: const Text('Activate'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
