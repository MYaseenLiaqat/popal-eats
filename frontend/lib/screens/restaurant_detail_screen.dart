import 'package:flutter/material.dart';

import 'dish_detail_screen.dart';
import '../models/dish.dart';
import '../models/restaurant.dart';
import '../services/dish_service.dart';
import '../services/restaurant_service.dart';
import '../widgets/cart_icon_button.dart';

/// Restaurant profile and menu (`GET /restaurants/{id}` + dishes).
class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  final int restaurantId;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final _restaurants = RestaurantService();
  final _dishes = DishService();

  Restaurant? restaurant;
  List<Dish> dishes = [];
  bool loading = true;
  String? error;

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
      final r = await _restaurants.getById(widget.restaurantId);
      final rawDishes = await _dishes.list(
        restaurantId: widget.restaurantId,
        limit: 100,
      );
      final parsedDishes = rawDishes
          .whereType<Map<String, dynamic>>()
          .map(Dish.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        restaurant = r;
        dishes = parsedDishes;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = restaurant;

    return Scaffold(
      appBar: AppBar(
        title: Text(r?.name ?? 'Restaurant'),
        actions: const [CartIconButton()],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(error!),
                  ),
                )
              : r == null
                  ? const Center(child: Text('Restaurant not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            r.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          if (r.description != null &&
                              r.description!.isNotEmpty) ...[
                            Text(
                              r.description!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (r.address != null && r.address!.isNotEmpty)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.location_on_outlined),
                              title: Text(r.address!),
                              subtitle: r.city != null && r.city!.isNotEmpty
                                  ? Text(r.city!)
                                  : null,
                            ),
                          if (r.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tags',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: r.tags
                                  .map(
                                    (tag) => Chip(
                                      label: Text(tag),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            'Dishes (${dishes.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (dishes.isEmpty)
                            const ListTile(
                              title: Text('No dishes listed for this restaurant'),
                            )
                          else
                            ...dishes.map(
                              (d) => Card(
                                child: ListTile(
                                  title: Text(d.name),
                                  subtitle: d.description != null &&
                                          d.description!.isNotEmpty
                                      ? Text(d.description!)
                                      : null,
                                  trailing: Text('\$${d.price.toStringAsFixed(2)}'),
                                  isThreeLine: d.description != null &&
                                      d.description!.isNotEmpty,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DishDetailScreen(dishId: d.id),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
