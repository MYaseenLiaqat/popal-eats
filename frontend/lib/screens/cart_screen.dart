import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_colors.dart';
import '../utils/price_formatter.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'checkout_screen.dart';

/// Cart contents with quantity controls (`CartProvider`).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CartProvider>().load();
  }

  Future<void> _changeQuantity(CartItem item, int delta) async {
    final cart = context.read<CartProvider>();
    final next = item.quantity + delta;
    if (next < 1) {
      await cart.removeItem(item.id);
    } else {
      await cart.updateQuantity(item.id, next);
    }
    if (!mounted) return;
    final err = context.read<CartProvider>().error;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _removeItem(CartItem item) async {
    await context.read<CartProvider>().removeItem(item.id);
    if (!mounted) return;
    final err = context.read<CartProvider>().error;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  bool _hasNutrition(List<CartItem> items) {
    for (final item in items) {
      final d = item.dish;
      if (d == null) continue;
      if (d.calories != null ||
          d.protein != null ||
          d.carbs != null ||
          d.fats != null) {
        return true;
      }
    }
    return false;
  }

  ({int? calories, double? protein, double? carbs, double? fats})
      _aggregateNutrition(List<CartItem> items) {
    int calories = 0;
    double protein = 0;
    double carbs = 0;
    double fats = 0;
    var hasCal = false;
    var hasProt = false;
    var hasCarb = false;
    var hasFat = false;

    for (final item in items) {
      final d = item.dish;
      if (d == null) continue;
      final qty = item.quantity;
      if (d.calories != null) {
        calories += d.calories! * qty;
        hasCal = true;
      }
      if (d.protein != null) {
        protein += d.protein! * qty;
        hasProt = true;
      }
      if (d.carbs != null) {
        carbs += d.carbs! * qty;
        hasCarb = true;
      }
      if (d.fats != null) {
        fats += d.fats! * qty;
        hasFat = true;
      }
    }

    return (
      calories: hasCal ? calories : null,
      protein: hasProt ? protein : null,
      carbs: hasCarb ? carbs : null,
      fats: hasFat ? fats : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.cart?.items ?? [];
    final nutrition = _aggregateNutrition(items);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cart.loading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cart.error != null && items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppColors.screenPadding),
                    child: Text(cart.error!, textAlign: TextAlign.center),
                  ),
                )
              : items.isEmpty
                  ? const EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Your cart is empty',
                      subtitle: 'Add dishes from the menu to get started',
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: cart.load,
                            color: AppColors.gold,
                            child: ListView(
                              padding: const EdgeInsets.all(
                                AppColors.screenPadding,
                              ),
                              children: [
                                ...items.map((item) {
                                  final dish = item.dish;
                                  final name =
                                      dish?.name ?? 'Dish #${item.dishId}';
                                  final unitPrice = dish?.price ?? 0;
                                  final lineTotal = unitPrice * item.quantity;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ModernCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: AppColors.green
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.lunch_dining,
                                                  color: AppColors.green,
                                                  size: 22,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${PriceFormatter.format(unitPrice)} each',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                    ),
                                                    if (dish?.calories !=
                                                        null) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '${dish!.calories! * item.quantity} kcal',
                                                        style: const TextStyle(
                                                          color:
                                                              AppColors.green,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: AppColors.error,
                                                ),
                                                onPressed: cart.loading
                                                    ? null
                                                    : () => _removeItem(item),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              QuantityControl(
                                                quantity: item.quantity,
                                                enabled: !cart.loading,
                                                onDecrease: () =>
                                                    _changeQuantity(item, -1),
                                                onIncrease: () =>
                                                    _changeQuantity(item, 1),
                                              ),
                                              const Spacer(),
                                              Text(
                                                PriceFormatter.format(lineTotal),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: AppColors.gold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                if (_hasNutrition(items)) ...[
                                  const SectionHeader(
                                    title: 'Nutrition summary',
                                    subtitle: 'Estimated for your cart',
                                  ),
                                  ModernCard(
                                    borderColor: AppColors.green
                                        .withValues(alpha: 0.35),
                                    child: NutritionGrid(
                                      calories: nutrition.calories,
                                      protein: nutrition.protein,
                                      carbs: nutrition.carbs,
                                      fats: nutrition.fats,
                                    ),
                                  ),
                                ],
                                SectionHeader(
                                  title: 'Order summary',
                                  subtitle: '${cart.itemCount} items',
                                ),
                                ModernCard(
                                  child: Column(
                                    children: [
                                      SummaryLine(
                                        label: 'Items',
                                        value: '${cart.itemCount}',
                                      ),
                                      SummaryLine(
                                        label: 'Subtotal',
                                        value:
                                            PriceFormatter.format(cart.subtotal),
                                        emphasize: true,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              top: BorderSide(
                                color: AppColors.surfaceLight
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          child: SafeArea(
                            minimum: const EdgeInsets.all(
                              AppColors.screenPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TotalAmountCard(
                                  label: 'Total',
                                  amount:
                                      PriceFormatter.format(cart.subtotal),
                                ),
                                const SizedBox(height: 12),
                                GoldActionButton(
                                  label: 'Checkout',
                                  icon: Icons.arrow_forward,
                                  onPressed: cart.isEmpty
                                      ? null
                                      : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CheckoutScreen(),
                                            ),
                                          ),
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
