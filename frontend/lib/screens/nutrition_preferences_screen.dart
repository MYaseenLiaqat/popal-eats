import 'package:flutter/material.dart';

/// Local-only nutrition preferences (Sprint 5B).
class NutritionPreferencesScreen extends StatefulWidget {
  const NutritionPreferencesScreen({super.key});

  @override
  State<NutritionPreferencesScreen> createState() =>
      _NutritionPreferencesScreenState();
}

class _NutritionPreferencesScreenState
    extends State<NutritionPreferencesScreen> {
  final _calorieGoalController = TextEditingController(text: '2100');
  final _cuisinesController = TextEditingController(text: 'Pakistani, Italian');

  static const _dietTypes = [
    'None',
    'Vegetarian',
    'Vegan',
    'Keto',
    'High Protein',
  ];

  String _dietType = 'None';

  @override
  void dispose() {
    _calorieGoalController.dispose();
    _cuisinesController.dispose();
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
      appBar: AppBar(title: const Text('Nutrition Preferences')),
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
                    controller: _calorieGoalController,
                    decoration: const InputDecoration(
                      labelText: 'Daily calorie goal',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cuisinesController,
                    decoration: const InputDecoration(
                      labelText: 'Preferred cuisines',
                      hintText: 'e.g. Pakistani, Italian',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Diet type',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _dietType,
                        isExpanded: true,
                        items: _dietTypes
                            .map(
                              (d) =>
                                  DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _dietType = value);
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
