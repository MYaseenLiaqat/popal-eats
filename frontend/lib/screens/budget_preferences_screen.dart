import 'package:flutter/material.dart';

/// Local-only budget preferences (Sprint 5B).
class BudgetPreferencesScreen extends StatefulWidget {
  const BudgetPreferencesScreen({super.key});

  @override
  State<BudgetPreferencesScreen> createState() =>
      _BudgetPreferencesScreenState();
}

class _BudgetPreferencesScreenState extends State<BudgetPreferencesScreen> {
  final _weeklyBudgetController = TextEditingController(text: '150');
  final _monthlyBudgetController = TextEditingController(text: '600');

  static const _budgetModes = ['Economy', 'Balanced', 'Premium'];

  String _budgetMode = 'Balanced';

  @override
  void dispose() {
    _weeklyBudgetController.dispose();
    _monthlyBudgetController.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _weeklyBudgetController,
                    decoration: const InputDecoration(
                      labelText: 'Weekly budget',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _monthlyBudgetController,
                    decoration: const InputDecoration(
                      labelText: 'Monthly budget',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Budget mode',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _budgetMode,
                        isExpanded: true,
                        items: _budgetModes
                            .map(
                              (m) =>
                                  DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _budgetMode = value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
