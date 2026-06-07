import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.cart?.items ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cart.loading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cart.error != null && items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(cart.error!),
                  ),
                )
              : items.isEmpty
                  ? const Center(child: Text('Your cart is empty'))
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: cart.load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final dish = item.dish;
                                final name =
                                    dish?.name ?? 'Dish #${item.dishId}';
                                final unitPrice = dish?.price ?? 0;
                                final lineTotal = unitPrice * item.quantity;

                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline),
                                              onPressed: cart.loading
                                                  ? null
                                                  : () => _removeItem(item),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '\$${unitPrice.toStringAsFixed(2)} each',
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: cart.loading
                                                  ? null
                                                  : () => _changeQuantity(
                                                        item,
                                                        -1,
                                                      ),
                                              icon: const Icon(Icons.remove),
                                            ),
                                            Text('${item.quantity}'),
                                            IconButton(
                                              onPressed: cart.loading
                                                  ? null
                                                  : () => _changeQuantity(
                                                        item,
                                                        1,
                                                      ),
                                              icon: const Icon(Icons.add),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '\$${lineTotal.toStringAsFixed(2)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subtotal',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '\$${cart.subtotal.toStringAsFixed(2)}',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: cart.isEmpty
                                    ? null
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CheckoutScreen(),
                                          ),
                                        ),
                                child: const Text('Checkout'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
