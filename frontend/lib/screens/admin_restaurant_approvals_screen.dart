import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../services/admin_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';

class AdminRestaurantApprovalsScreen extends StatefulWidget {
  const AdminRestaurantApprovalsScreen({super.key});

  @override
  State<AdminRestaurantApprovalsScreen> createState() =>
      _AdminRestaurantApprovalsScreenState();
}

class _AdminRestaurantApprovalsScreenState extends State<AdminRestaurantApprovalsScreen> {
  final _admin = AdminService();
  List<Restaurant> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await _admin.listRestaurants(approvalStatus: 'pending');
      _pending = raw
          .whereType<Map>()
          .map((e) => Restaurant.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Restaurant restaurant) async {
    await _admin.updateRestaurantApproval(restaurant.id, approvalStatus: 'approved');
    _load();
  }

  Future<void> _reject(Restaurant restaurant) async {
    await _admin.updateRestaurantApproval(
      restaurant.id,
      approvalStatus: 'rejected',
      rejectionReason: 'Does not meet listing requirements',
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant approvals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.gold,
              child: _pending.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.check_circle_outline,
                          title: 'No pending restaurants',
                          subtitle: 'All submissions have been reviewed.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppColors.screenPadding),
                      itemCount: _pending.length,
                      itemBuilder: (context, index) {
                        final r = _pending[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ModernCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: Theme.of(context).textTheme.titleMedium),
                                if (r.city != null) Text(r.city!),
                                if (r.address != null) Text(r.address!),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _reject(r),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: GoldActionButton(
                                        label: 'Approve',
                                        onPressed: () => _approve(r),
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
