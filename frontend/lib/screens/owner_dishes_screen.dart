import 'package:flutter/material.dart';

import '../models/dish.dart';
import '../services/restaurant_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/price_formatter.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'owner_dish_form_screen.dart';

class OwnerDishesScreen extends StatefulWidget {
  const OwnerDishesScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  final int restaurantId;
  final String restaurantName;

  @override
  State<OwnerDishesScreen> createState() => _OwnerDishesScreenState();
}

class _OwnerDishesScreenState extends State<OwnerDishesScreen> {
  final _service = RestaurantOwnerService();
  List<Dish> _dishes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _dishes = await _service.listDishes(restaurantId: widget.restaurantId);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteDish(Dish dish) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete dish?'),
        content: Text('Remove "${dish.name}" from your menu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await _service.deleteDish(dish.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.restaurantName} · Menu')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerDishFormScreen(restaurantId: widget.restaurantId),
          ),
        ).then((_) => _load()),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.gold,
                  child: _dishes.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            EmptyState(
                              icon: Icons.restaurant_outlined,
                              title: 'No dishes yet',
                              subtitle: 'Tap + to add your first dish.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppColors.screenPadding),
                          itemCount: _dishes.length,
                          itemBuilder: (context, index) {
                            final dish = _dishes[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ModernCard(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OwnerDishFormScreen(
                                      restaurantId: widget.restaurantId,
                                      dish: dish,
                                    ),
                                  ),
                                ).then((_) => _load()),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dish.name,
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(PriceFormatter.format(dish.price)),
                                          if (!dish.isAvailable)
                                            const Text(
                                              'Unavailable',
                                              style: TextStyle(color: AppColors.error),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _deleteDish(dish),
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
