import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/recommendation_copy.dart';
import '../../../widgets/admin/admin_ui.dart';
import '../admin_utils.dart';

enum _UserSort { newest, oldest, active, suspended }

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  final _admin = AdminService();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  String? _statusFilter;
  _UserSort _sort = _UserSort.newest;
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
      final page = await _admin.listUsers(page: 1, limit: 100, role: 'customer');
      _items = page.items;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    var list = _items.where((u) {
      final status = u['account_status']?.toString() ?? 'active';
      if (_statusFilter != null && status != _statusFilter) return false;
      if (_sort == _UserSort.active && status != 'active') return false;
      if (_sort == _UserSort.suspended && status != 'suspended') return false;
      if (q.isEmpty) return true;
      final name = u['full_name']?.toString().toLowerCase() ?? '';
      final email = u['email']?.toString().toLowerCase() ?? '';
      final username = u['username']?.toString().toLowerCase() ?? '';
      final role = u['role']?.toString().toLowerCase() ?? '';
      return name.contains(q) || email.contains(q) || username.contains(q) || role.contains(q);
    }).toList();

    list.sort((a, b) {
      final ad = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return _sort == _UserSort.oldest ? ad.compareTo(bd) : bd.compareTo(ad);
    });
    return list;
  }

  Future<void> _setStatus(Map<String, dynamic> user, String status) async {
    final label = status == 'suspended' ? 'Suspend' : 'Activate';
    final ok = await adminConfirm(
      context,
      title: '$label account',
      message: '$label ${user['full_name'] ?? user['email']}?',
      confirm: label,
    );
    if (ok != true) return;
    try {
      await _admin.updateUserAccountStatus(user['id'] as int, status);
      if (!mounted) return;
      await adminShowSnack(context, 'Account $status');
      await _load();
    } catch (e) {
      if (!mounted) return;
      await adminShowSnack(context, RecommendationCopy.friendlyError(e), error: true);
    }
  }

  void _view(Map<String, dynamic> user) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user['full_name']?.toString() ?? 'Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${user['username'] ?? '—'}'),
            Text('Email: ${user['email']}'),
            Text('Role: ${user['role']}'),
            Text('Phone: ${user['phone'] ?? '—'}'),
            Text('City: ${user['city'] ?? '—'}'),
            Text('Status: ${user['account_status'] ?? 'active'}'),
            Text('Joined: ${adminFormatDate(user['created_at']?.toString())}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminPageHeader(title: 'User management', subtitle: 'Customers · search, filter, and manage accounts'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name, username, email, or role',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Sort:', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<_UserSort>(
                value: _sort,
                isDense: true,
                items: const [
                  DropdownMenuItem(value: _UserSort.newest, child: Text('Newest')),
                  DropdownMenuItem(value: _UserSort.oldest, child: Text('Oldest')),
                  DropdownMenuItem(value: _UserSort.active, child: Text('Active')),
                  DropdownMenuItem(value: _UserSort.suspended, child: Text('Suspended')),
                ],
                onChanged: (v) => setState(() => _sort = v ?? _UserSort.newest),
              ),
              const Spacer(),
              _filterChip('All', null),
              _filterChip('Active', 'active'),
              _filterChip('Suspended', 'suspended'),
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
                      ? ListView(children: const [SizedBox(height: 80), Center(child: Text('No users match your filters'))])
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final u = _filtered[i];
                            final status = u['account_status']?.toString() ?? 'active';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AdminUserRow(
                                name: u['full_name']?.toString() ?? 'Customer',
                                username: u['username']?.toString(),
                                email: u['email']?.toString() ?? '',
                                role: u['role']?.toString() ?? 'customer',
                                status: status,
                                createdAt: adminFormatDate(u['created_at']?.toString()),
                                onView: () => _view(u),
                                onSuspend: status != 'suspended' ? () => _setStatus(u, 'suspended') : null,
                                onActivate: status == 'suspended' ? () => _setStatus(u, 'active') : null,
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? status) {
    final selected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = status),
        selectedColor: AppColors.accent.withValues(alpha: 0.2),
        checkmarkColor: AppColors.accent,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
