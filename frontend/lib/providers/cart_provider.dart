import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../models/cart.dart';
import '../services/api_client.dart';
import '../services/cart_service.dart';
import '../utils/recommendation_copy.dart';

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

  void _notify() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  Future<void> load() async {
    if (!ApiClient.instance.isAuthenticated) {
      cart = null;
      error = null;
      _notify();
      return;
    }

    loading = true;
    error = null;
    _notify();

    try {
      cart = await _cartService.getCart();
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
      cart = null;
    } catch (e) {
      error = RecommendationCopy.friendlyError(e);
      cart = null;
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<bool> addItem({required int dishId, int quantity = 1}) async {
    try {
      await _cartService.addItem(dishId: dishId, quantity: quantity);
      await load();
      return true;
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
      _notify();
      return false;
    } catch (e) {
      error = RecommendationCopy.friendlyError(e);
      _notify();
      return false;
    }
  }

  Future<bool> updateQuantity(int itemId, int quantity) async {
    try {
      await _cartService.updateItem(itemId: itemId, quantity: quantity);
      await load();
      return true;
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
      _notify();
      return false;
    } catch (e) {
      error = RecommendationCopy.friendlyError(e);
      _notify();
      return false;
    }
  }

  Future<bool> removeItem(int itemId) async {
    try {
      await _cartService.removeItem(itemId);
      await load();
      return true;
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
      _notify();
      return false;
    } catch (e) {
      error = RecommendationCopy.friendlyError(e);
      _notify();
      return false;
    }
  }

  Future<void> clear() async {
    try {
      await _cartService.clearCart();
      cart = null;
      error = null;
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
    } catch (e) {
      error = RecommendationCopy.friendlyError(e);
    }
    _notify();
  }

  void reset() {
    cart = null;
    loading = false;
    error = null;
    _notify();
  }
}
