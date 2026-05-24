import 'package:flutter/material.dart';

import '../services/admin_service.dart';

/// Admin analytics dashboard (admin role required).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _admin = AdminService();
  Map<String, dynamic>? stats;
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      stats = await _admin.analyticsOverview();
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _tile('Users', stats?['users']),
                      _tile('Restaurants', stats?['restaurants']),
                      _tile('Dishes', stats?['dishes']),
                      _tile('Reviews', stats?['reviews']),
                      _tile('Pending AI', stats?['reviews_pending_processing']),
                      _tile('Failed AI', stats?['reviews_failed_processing']),
                      _tile('Menu uploads', stats?['menu_uploads']),
                    ],
                  ),
                ),
    );
  }

  Widget _tile(String label, dynamic value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text('$value', style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
