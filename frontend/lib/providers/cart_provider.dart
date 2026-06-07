import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../services/api_client.dart';
import '../services/cart_service.dart';

/// Global cart state for Sprint 2+ screens.
class CartProvider extends ChangeNotifier {
  CartProvider({CartService? cartService})
      : _cartService = cartService ?? CartService();

  final CartService _cartService;

  Cart? cart;
  bool loading = false;
  String? error;

  int get itemCount => cart?.itemCount ?? 0;
  double get subtotal => cart?.subtotal ?? 0;
  bool get isEmpty => cart == null || cart!.isEmpty;

  Future<void> load() async {
    if (!ApiClient.instance.isAuthenticated) {
      cart = null;
      error = null;
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      cart = await _cartService.getCart();
    } on ApiException catch (e) {
      error = e.message;
      cart = null;
    } catch (e) {
      error = e.toString();
      cart = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem({required int dishId, int quantity = 1}) async {
    try {
      await _cartService.addItem(dishId: dishId, quantity: quantity);
      await load();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuantity(int itemId, int quantity) async {
    try {
      await _cartService.updateItem(itemId: itemId, quantity: quantity);
      await load();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeItem(int itemId) async {
    try {
      await _cartService.removeItem(itemId);
      await load();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> clear() async {
    try {
      await _cartService.clearCart();
      cart = null;
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  void reset() {
    cart = null;
    loading = false;
    error = null;
    notifyListeners();
  }
}
