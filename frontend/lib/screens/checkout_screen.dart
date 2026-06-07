import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';
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
        error = e.message;
        placing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        placing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.cart?.items ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.loading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Order summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Items'),
                                Text('${cart.itemCount}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  '\$${cart.subtotal.toStringAsFixed(2)}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      final dish = item.dish;
                      final name = dish?.name ?? 'Dish #${item.dishId}';
                      final unitPrice = dish?.price ?? 0;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(name),
                        subtitle: Text('Qty ${item.quantity}'),
                        trailing: Text(
                          '\$${(unitPrice * item.quantity).toStringAsFixed(2)}',
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      enabled: !placing,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: placing ? null : _placeOrder,
                        child: placing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Place order'),
                      ),
                    ),
                  ],
                ),
    );
  }
}
