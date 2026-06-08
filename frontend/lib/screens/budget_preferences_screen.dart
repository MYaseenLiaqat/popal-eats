import 'package:flutter/material.dart';

import '../data/local_preferences_store.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Local-only budget preferences (Sprint 5B).
class BudgetPreferencesScreen extends StatefulWidget {
  const BudgetPreferencesScreen({super.key});

  @override
  State<BudgetPreferencesScreen> createState() =>
      _BudgetPreferencesScreenState();
}

class _BudgetPreferencesScreenState extends State<BudgetPreferencesScreen> {
  final _store = LocalPreferencesStore();
  final _weeklyBudgetController = TextEditingController();
  final _monthlyBudgetController = TextEditingController();

  static const _budgetModes = [
    ('Economy', 'Best value picks', Icons.savings_outlined),
    ('Balanced', 'Mix of quality & price', Icons.balance_outlined),
    ('Premium', 'Top-tier selections', Icons.diamond_outlined),
  ];

  String _budgetMode = LocalPreferencesStore.defaultBudgetMode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await _store.loadBudget();
    if (!mounted) return;
    setState(() {
      _weeklyBudgetController.text = saved.weeklyBudget;
      _monthlyBudgetController.text = saved.monthlyBudget;
      _budgetMode = saved.budgetMode;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _weeklyBudgetController.dispose();
    _monthlyBudgetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _store.saveBudget(
      weeklyBudget: _weeklyBudgetController.text.trim().isEmpty
          ? LocalPreferencesStore.defaultWeeklyBudget
          : _weeklyBudgetController.text.trim(),
      monthlyBudget: _monthlyBudgetController.text.trim().isEmpty
          ? LocalPreferencesStore.defaultMonthlyBudget
          : _monthlyBudgetController.text.trim(),
      budgetMode: _budgetMode,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Budget Preferences')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          ModernCard(
            gradient: AppColors.headerGradient,
            borderColor: AppColors.green.withValues(alpha: 0.35),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending limits',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.gold,
                            ),
                      ),
                      Text(
                        'Control your food budget',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(
            title: 'Weekly budget',
            subtitle: 'Max spend per week',
          ),
          ModernCard(
            borderColor: AppColors.gold.withValues(alpha: 0.4),
            child: TextField(
              controller: _weeklyBudgetController,
              keyboardType: TextInputType.number,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.gold,
                  ),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: AppColors.gold),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SectionHeader(
            title: 'Monthly budget',
            subtitle: 'Max spend per month',
          ),
          ModernCard(
            borderColor: AppColors.green.withValues(alpha: 0.4),
            child: TextField(
              controller: _monthlyBudgetController,
              keyboardType: TextInputType.number,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.green,
                  ),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: AppColors.green),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SectionHeader(
            title: 'Budget mode',
            subtitle: 'How recommendations prioritize price',
          ),
          ..._budgetModes.map((mode) {
            final selected = _budgetMode == mode.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ModernCard(
                onTap: () => setState(() => _budgetMode = mode.$1),
                borderColor: selected
                    ? AppColors.gold.withValues(alpha: 0.5)
                    : null,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (selected ? AppColors.gold : AppColors.green)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        mode.$3,
                        color: selected ? AppColors.gold : AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.$1,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            mode.$2,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, color: AppColors.gold),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          GoldActionButton(
            label: 'Save Preferences',
            icon: Icons.check,
            onPressed: _save,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
