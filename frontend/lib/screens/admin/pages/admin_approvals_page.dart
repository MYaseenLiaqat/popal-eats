import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/recommendation_copy.dart';
import '../../../widgets/admin/admin_charts.dart';
import '../../../widgets/admin/admin_ui.dart';
import '../../../widgets/ui/app_ui_widgets.dart';
import '../admin_portal_notifier.dart';
import '../admin_utils.dart';

class AdminApprovalsPage extends StatefulWidget {
  const AdminApprovalsPage({super.key});

  @override
  State<AdminApprovalsPage> createState() => _AdminApprovalsPageState();
}

class _AdminApprovalsPageState extends State<AdminApprovalsPage> with SingleTickerProviderStateMixin {
  final _admin = AdminService();
  late TabController _tabs;
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String? _error;
  final Set<int> _processing = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _all.isEmpty;
      _error = null;
    });
    try {
      _all = await _admin.listPendingBusinessAccounts();
    } catch (e) {
      _error = RecommendationCopy.friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _filtered(bool restaurants) {
    return _all.where((a) => restaurants ? adminIsRestaurantRole(a) : adminIsHomeChefRole(a)).toList();
  }

  int _userIdFromAccount(Map<String, dynamic> account) {
    final raw = account['user_id'];
    if (raw is int) return raw;
    return int.tryParse('$raw') ?? 0;
  }

  void _notifyChanged() {
    context.read<AdminPortalNotifier>().notifyApprovalsChanged();
  }

  Future<void> _approve(Map<String, dynamic> account) async {
    final userId = _userIdFromAccount(account);
    if (_processing.contains(userId)) return;

    final ok = await adminConfirm(
      context,
      title: 'Approve application',
      message: 'Activate ${adminAccountTitle(account)}?',
      confirm: 'Approve',
    );
    if (ok != true) return;

    setState(() => _processing.add(userId));
    try {
      await _admin.approveBusinessAccount(userId);
      await _load();
      if (!mounted) return;
      _notifyChanged();
      await adminShowSnack(context, 'Approved ${adminAccountTitle(account)}');
    } catch (e) {
      if (!mounted) return;
      await adminShowSnack(context, RecommendationCopy.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _processing.remove(userId));
    }
  }

  Future<void> _reject(Map<String, dynamic> account) async {
    final userId = _userIdFromAccount(account);
    if (_processing.contains(userId)) return;

    final ok = await adminConfirm(
      context,
      title: 'Reject application',
      message: 'Reject ${adminAccountTitle(account)}?',
      confirm: 'Reject',
    );
    if (ok != true) return;

    setState(() => _processing.add(userId));
    try {
      await _admin.rejectBusinessAccount(
        userId,
        reason: 'Does not meet listing requirements',
      );
      await _load();
      if (!mounted) return;
      _notifyChanged();
      await adminShowSnack(context, 'Application rejected');
    } catch (e) {
      if (!mounted) return;
      await adminShowSnack(context, RecommendationCopy.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _processing.remove(userId));
    }
  }

  void _showDetails(Map<String, dynamic> account) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        builder: (_, scroll) => _ApprovalDetailSheet(account: account, scrollController: scroll),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null) {
      return Center(child: EmptyState(icon: Icons.error_outline, title: 'Load failed', subtitle: _error));
    }

    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.accent,
              tabs: [
                Tab(text: 'Restaurants (${_filtered(true).length})'),
                Tab(text: 'Home Chefs (${_filtered(false).length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ApprovalList(
                  accounts: _filtered(true),
                  isRestaurant: true,
                  processing: _processing,
                  onRefresh: _load,
                  onApprove: _approve,
                  onReject: _reject,
                  onDetails: _showDetails,
                ),
                _ApprovalList(
                  accounts: _filtered(false),
                  isRestaurant: false,
                  processing: _processing,
                  onRefresh: _load,
                  onApprove: _approve,
                  onReject: _reject,
                  onDetails: _showDetails,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalList extends StatelessWidget {
  const _ApprovalList({
    required this.accounts,
    required this.isRestaurant,
    required this.processing,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
    required this.onDetails,
  });

  final List<Map<String, dynamic>> accounts;
  final bool isRestaurant;
  final Set<int> processing;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Map<String, dynamic>) onApprove;
  final Future<void> Function(Map<String, dynamic>) onReject;
  final void Function(Map<String, dynamic>) onDetails;

  @override
  Widget build(BuildContext context) {
    final header = AdminPageHeader(
      title: isRestaurant ? 'Restaurant approvals' : 'Home chef approvals',
      subtitle: '${accounts.length} pending application(s) · approve or reject below',
    );

    if (accounts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.accent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            header,
            const SizedBox(height: 80),
            const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No pending accounts',
              subtitle: 'All applications in this category are up to date.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.accent,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: accounts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return header;

          final account = accounts[index - 1];
          final userId = _userId(account);
          final restaurant = account['restaurant'] as Map<String, dynamic>?;
          final chef = account['home_chef'] as Map<String, dynamic>?;
          final logoUrl = isRestaurant
              ? adminMapStr(restaurant, 'image')
              : adminMapStr(chef, 'profile_image');
          final cuisine = isRestaurant
              ? adminMapStr(restaurant, 'cuisine_type')
              : adminMapStr(chef, 'cuisine_specialty');
          final address = isRestaurant
              ? adminMapStr(restaurant, 'address')
              : adminMapStr(chef, 'kitchen_address');
          final busy = processing.contains(userId);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ModernAdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LogoAvatar(url: logoUrl, isRestaurant: isRestaurant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    adminAccountTitle(account),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                const AdminStatusBadge(status: 'pending'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _infoRow(Icons.person_outline, 'Owner', account['full_name']?.toString()),
                            _infoRow(Icons.alternate_email, 'Username', account['username']?.toString()),
                            _infoRow(Icons.email_outlined, 'Email', account['email']?.toString()),
                            _infoRow(Icons.phone_outlined, 'Phone', account['phone']?.toString()),
                            if (cuisine != null) _infoRow(Icons.restaurant_outlined, 'Cuisine', cuisine),
                            if (address != null) _infoRow(Icons.location_on_outlined, 'Address', address),
                            _infoRow(Icons.event_outlined, 'Registered', adminFormatDate(account['created_at']?.toString())),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isRestaurant && chef?['food_license'] != null) ...[
                    const SizedBox(height: 8),
                    _infoRow(Icons.description_outlined, 'License', chef!['food_license']?.toString()),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: busy ? null : () => onDetails(account),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('View Details'),
                      ),
                      if (busy)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        )
                      else ...[
                        OutlinedButton(
                          onPressed: () => onReject(account),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Reject'),
                        ),
                        FilledButton(
                          onPressed: () => onApprove(account),
                          style: FilledButton.styleFrom(
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Approve'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _userId(Map<String, dynamic> account) {
    final raw = account['user_id'];
    if (raw is int) return raw;
    return int.tryParse('$raw') ?? 0;
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar({required this.url, required this.isRestaurant});

  final String? url;
  final bool isRestaurant;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
      backgroundImage: url != null && url!.isNotEmpty ? NetworkImage(url!) : null,
      child: url == null || url!.isEmpty
          ? Icon(isRestaurant ? Icons.storefront : Icons.soup_kitchen, color: AppColors.accent)
          : null,
    );
  }
}

class _ApprovalDetailSheet extends StatelessWidget {
  const _ApprovalDetailSheet({required this.account, required this.scrollController});

  final Map<String, dynamic> account;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final restaurant = account['restaurant'] as Map<String, dynamic>?;
    final chef = account['home_chef'] as Map<String, dynamic>?;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        Text(adminAccountTitle(account), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _detailRow('Status', account['account_status']?.toString() ?? 'pending'),
        _detailRow('Role', account['role']?.toString()),
        _detailRow('Owner', account['full_name']?.toString()),
        _detailRow('Username', account['username']?.toString()),
        _detailRow('Email', account['email']?.toString()),
        _detailRow('Phone', account['phone']?.toString()),
        _detailRow('Registered', adminFormatDate(account['created_at']?.toString())),
        if (restaurant != null) ...[
          const Divider(height: 24),
          Text('Restaurant', style: Theme.of(context).textTheme.titleSmall),
          _detailRow('Name', restaurant['name']?.toString()),
          _detailRow('Address', restaurant['address']?.toString()),
          _detailRow('Cuisine', restaurant['cuisine_type']?.toString()),
          _detailRow('Listing status', restaurant['approval_status']?.toString()),
        ],
        if (chef != null) ...[
          const Divider(height: 24),
          Text('Home Chef', style: Theme.of(context).textTheme.titleSmall),
          _detailRow('Display name', chef['display_name']?.toString()),
          _detailRow('Specialty', chef['cuisine_specialty']?.toString()),
          _detailRow('Kitchen', chef['kitchen_address']?.toString()),
          _detailRow('Food license', chef['food_license']?.toString()),
        ],
      ],
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value ?? '—')),
        ],
      ),
    );
  }
}
