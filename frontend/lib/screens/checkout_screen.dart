import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';
import '../theme/app_colors.dart';
import '../utils/price_formatter.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'order_success_screen.dart';

/// Checkout with delivery address (`POST /checkout`).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _orders = OrderService();
  final _addressController = TextEditingController();
  bool placing = false;
  String? error;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() => error = 'Enter a delivery address');
      return;
    }

    setState(() {
      placing = true;
      error = null;
    });

    try {
      final order = await _orders.checkout(deliveryAddress: address);
      if (!mounted) return;
      await context.read<CartProvider>().clear();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(order: order),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        error = RecommendationCopy.friendlyError(e);
        placing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = RecommendationCopy.friendlyError(e);
        placing = false;
      });
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
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.loading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Your cart is empty',
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppColors.screenPadding),
                        children: [
                          ModernCard(
                            gradient: AppColors.headerGradient,
                            borderColor:
                                AppColors.gold.withValues(alpha: 0.35),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: AppColors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delivery address',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your delivery address',
                                    filled: true,
                                    fillColor: AppColors.surfaceLight,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColors.green
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  ),
                                  maxLines: 2,
                                  enabled: !placing,
                                ),
                                if (error != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    error!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SectionHeader(
                            title: 'Order summary',
                            subtitle: 'Review your items',
                          ),
                          ModernCard(
                            child: Column(
                              children: [
                                SummaryLine(
                                  label: 'Items',
                                  value: '${cart.itemCount}',
                                ),
                                ...items.map((item) {
                                  final dish = item.dish;
                                  final name =
                                      dish?.name ?? 'Dish #${item.dishId}';
                                  final unitPrice = dish?.price ?? 0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge,
                                              ),
                                              Text(
                                                'Qty ${item.quantity}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          PriceFormatter.format(unitPrice * item.quantity),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: AppColors.gold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(height: 20),
                                SummaryLine(
                                  label: 'Subtotal',
                                  value:
                                      PriceFormatter.format(cart.subtotal),
                                ),
                              ],
                            ),
                          ),
                          if (_hasNutrition(items)) ...[
                            const SectionHeader(
                              title: 'Nutrition summary',
                              subtitle: 'Estimated for this order',
                            ),
                            ModernCard(
                              borderColor:
                                  AppColors.green.withValues(alpha: 0.35),
                              child: NutritionGrid(
                                calories: nutrition.calories,
                                protein: nutrition.protein,
                                carbs: nutrition.carbs,
                                fats: nutrition.fats,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TotalAmountCard(
                            label: 'Total amount',
                            amount: PriceFormatter.format(cart.subtotal),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(
                            color:
                                AppColors.surfaceLight.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        minimum: const EdgeInsets.all(AppColors.screenPadding),
                        child: GoldActionButton(
                          label: 'Place Order',
                          icon: Icons.check_circle_outline,
                          loading: placing,
                          onPressed: placing ? null : _placeOrder,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
