import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'group_detail_screen.dart';

/// Create a new group recommendation session.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GroupProvider>();
    final session = await provider.createGroup(_nameController.text.trim());
    if (!mounted) return;

    if (session != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created "${session.name}"')),
      );
      final navigator = Navigator.of(context);
      navigator.pop(true);
      navigator.push(
        MaterialPageRoute(
          builder: (_) => GroupDetailScreen(sessionId: session.id),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.actionError ?? 'Could not create group')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: ListView(
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          ModernCard(
            gradient: AppColors.headerGradient,
            borderColor: AppColors.gold.withValues(alpha: 0.35),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.group_add, color: AppColors.gold, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start a food group',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.gold,
                            ),
                      ),
                      Text(
                        'Invite friends and pick dishes together',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: ModernCard(
              child: TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  hintText: 'Friday Night Biryani Crew',
                  border: InputBorder.none,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Enter a group name';
                  if (text.length > 120) return 'Name is too long';
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          GoldActionButton(
            label: 'Create Group',
            icon: Icons.check_circle_outline,
            loading: provider.actionLoading,
            onPressed: provider.actionLoading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
