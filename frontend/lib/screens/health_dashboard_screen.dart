import 'package:flutter/material.dart';

/// Health dashboard with mock nutrition data (Sprint 5C).
class HealthDashboardScreen extends StatelessWidget {
  const HealthDashboardScreen({super.key});

  static const _weeklyCalories = {
    'Mon': 1800,
    'Tue': 2100,
    'Wed': 1950,
    'Thu': 2200,
    'Fri': 1850,
    'Sat': 2300,
    'Sun': 1900,
  };

  static const _maxCalories = 2300;
  static const _avgDay = 2014;
  static const _goal = 2200;
  static const _progress = 0.92;

  static const _insights = [
    'Calorie intake is close to goal.',
    'Protein intake is healthy.',
    'Water intake should be increased.',
  ];

  @override
  Widget build(BuildContext context) {
    final progressPct = (_progress * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Health Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly calories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ..._weeklyCalories.entries.map((e) {
                    final factor = e.value / _maxCalories;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(e.key),
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 12,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: factor,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${e.value}',
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: Card(
                  child: ListTile(
                    title: Text('Avg/Day'),
                    trailing: Text('$_avgDay cal'),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: ListTile(
                    title: Text('Goal'),
                    trailing: Text('$_goal cal'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('$progressPct%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progress,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nutrition summary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: Card(
                  child: ListTile(
                    title: Text('Protein'),
                    trailing: Text('120g'),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: ListTile(
                    title: Text('Carbs'),
                    trailing: Text('250g'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: Card(
                  child: ListTile(
                    title: Text('Fat'),
                    trailing: Text('70g'),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: ListTile(
                    title: Text('Water'),
                    trailing: Text('2.3L'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Health insights',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < _insights.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: Text(_insights[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
