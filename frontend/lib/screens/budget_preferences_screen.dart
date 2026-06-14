import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/preferences_provider.dart';
import '../theme/app_colors.dart';
import '../utils/preference_display.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Budget preferences synced with backend GET/PUT /preferences.
class BudgetPreferencesScreen extends StatefulWidget {
  const BudgetPreferencesScreen({super.key});

  @override
  State<BudgetPreferencesScreen> createState() =>
      _BudgetPreferencesScreenState();
}

class _BudgetPreferencesScreenState extends State<BudgetPreferencesScreen> {
  final _weeklyBudgetController = TextEditingController(text: '150');
  final _monthlyBudgetController = TextEditingController(text: '600');

  static const _budgetModes = [
    ('Economy', 'Best value picks', Icons.savings_outlined),
    ('Balanced', 'Mix of quality & price', Icons.balance_outlined),
    ('Premium', 'Top-tier selections', Icons.diamond_outlined),
  ];

  String _budgetMode = 'Balanced';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromBackend());
  }

  Future<void> _loadFromBackend() async {
    final provider = context.read<PreferencesProvider>();
    await provider.fetch(force: true);
    if (!mounted) return;

    final prefs = provider.preferences;
    if (provider.error != null || prefs == null) {
      setState(() => _initialized = true);
      return;
    }

    setState(() {
      _budgetMode = PreferenceDisplay.budgetLabelFromBackend(prefs.budgetLevel);
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _weeklyBudgetController.dispose();
    _monthlyBudgetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<PreferencesProvider>();
    final ok = await provider.updateBudget(
      budgetLevel: PreferenceDisplay.budgetToBackend(_budgetMode),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not save preferences')),
      );
    }
  }

  Widget _buildBody(PreferencesProvider provider) {
    if (!_initialized || (provider.loading && provider.preferences == null)) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (provider.error != null && provider.preferences == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load preferences',
            subtitle: provider.error,
          ),
          TextButton(
            onPressed: _loadFromBackend,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return ListView(
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
          subtitle: 'Max spend per week (display only)',
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
          subtitle: 'Max spend per month (display only)',
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
          loading: provider.saving,
          onPressed: provider.saving ? null : _save,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PreferencesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Preferences')),
      body: _buildBody(provider),
    );
  }
}
