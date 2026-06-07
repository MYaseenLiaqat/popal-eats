import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dish.dart';
import '../providers/cart_provider.dart';
import '../services/dish_service.dart';
import '../widgets/cart_icon_button.dart';

/// Dish profile from `GET /dishes/{id}` with add-to-cart.
class DishDetailScreen extends StatefulWidget {
  const DishDetailScreen({super.key, required this.dishId});

  final int dishId;

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  final _dishes = DishService();

  Dish? dish;
  bool loading = true;
  bool adding = false;
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
      final d = await _dishes.getById(widget.dishId);
      if (!mounted) return;
      setState(() {
        dish = d;
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

  Future<void> _addToCart() async {
    final d = dish;
    if (d == null || adding) return;

    setState(() => adding = true);
    final ok = await context.read<CartProvider>().addItem(dishId: d.id);
    if (!mounted) return;
    setState(() => adding = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${d.name} added to cart')),
      );
    } else {
      final msg = context.read<CartProvider>().error ?? 'Could not add to cart';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = dish;

    return Scaffold(
      appBar: AppBar(
        title: Text(d?.name ?? 'Dish'),
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
              : d == null
                  ? const Center(child: Text('Dish not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          d.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${d.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (d.description != null &&
                            d.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            d.description!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                        if (_hasNutrition(d)) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Nutrition',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (d.calories != null)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('Calories'),
                              trailing: Text('${d.calories} kcal'),
                            ),
                          if (d.protein != null)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('Protein'),
                              trailing: Text('${d.protein!.toStringAsFixed(1)} g'),
                            ),
                          if (d.carbs != null)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('Carbs'),
                              trailing: Text('${d.carbs!.toStringAsFixed(1)} g'),
                            ),
                          if (d.fats != null)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('Fats'),
                              trailing: Text('${d.fats!.toStringAsFixed(1)} g'),
                            ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: d.isAvailable && !adding ? _addToCart : null,
                            child: adding
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Add To Cart'),
                          ),
                        ),
                      ],
                    ),
    );
  }

  bool _hasNutrition(Dish d) =>
      d.calories != null ||
      d.protein != null ||
      d.carbs != null ||
      d.fats != null;
}
