import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../products/models.dart';
import 'cart_state.dart';
import 'models.dart';

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState.initial()) {
    _loadSavedCarts();
  }

  void addProduct(Product product) {
    final existingIndex =
        state.items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex == -1) {
      _setItems([
        ...state.items,
        CartItem(product: product, quantity: 1),
      ]);
      return;
    }
    final updated = [...state.items];
    final existing = updated[existingIndex];
    updated[existingIndex] =
        existing.copyWith(quantity: existing.quantity + 1);
    _setItems(updated);
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final updated = [
      for (final item in state.items)
        if (item.product.id == productId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
    _setItems(updated);
  }

  void removeProduct(int productId) {
    final updated =
        state.items.where((item) => item.product.id != productId).toList();
    _setItems(updated);
  }

  void setDiscountAmount(double discountAmount) {
    final clamped = _clampNonNegative(discountAmount);
    state = state.copyWith(discountAmount: clamped);
  }

  void clearCart() {
    state = CartState.initial().copyWith(savedCarts: state.savedCarts);
  }

  void setItemDiscountEnabled(bool enabled) {
    state = state.copyWith(applyItemDiscount: enabled);
  }

  Future<void> saveCurrentCart(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final savedItems = [
      for (final item in state.items)
        SavedCartItem(
          productId: item.product.id,
          quantity: item.quantity,
        ),
    ];
    final updated = [
      for (final cart in state.savedCarts)
        if (cart.name != trimmed) cart,
      SavedCart(name: trimmed, items: savedItems),
    ];
    state = state.copyWith(savedCarts: updated);
    await _persistSavedCarts(updated);
  }

  Future<void> deleteSavedCart(String name) async {
    final updated =
        state.savedCarts.where((cart) => cart.name != name).toList();
    state = state.copyWith(savedCarts: updated);
    await _persistSavedCarts(updated);
  }

  Future<void> renameSavedCart(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final updated = [
      for (final cart in state.savedCarts)
        if (cart.name == oldName)
          SavedCart(name: trimmed, items: cart.items)
        else if (cart.name != trimmed)
          cart,
    ];
    state = state.copyWith(savedCarts: updated);
    await _persistSavedCarts(updated);
  }

  int loadSavedCart(
    SavedCart savedCart,
    Map<int, Product> productsById,
  ) {
    final items = <CartItem>[];
    var missing = 0;
    for (final item in savedCart.items) {
      final product = productsById[item.productId];
      if (product == null) {
        missing += 1;
        continue;
      }
      items.add(CartItem(product: product, quantity: item.quantity));
    }
    state = state.copyWith(items: items, discountAmount: 0);
    return missing;
  }

  void _setItems(List<CartItem> items) {
    final clamped = _clampNonNegative(state.discountAmount);
    state = state.copyWith(items: items, discountAmount: clamped);
  }

  double _calculateSubtotal(List<CartItem> items) {
    return items.fold(0, (total, item) => total + item.lineTotal);
  }

  double _calculateItemDiscount(List<CartItem> items) {
    return items.fold(0, (total, item) => total + item.discountAmount);
  }

  double _clampNonNegative(double value) {
    if (value < 0) return 0;
    return value;
  }

  Future<void> _loadSavedCarts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedCartsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final carts = decoded
          .map((item) => SavedCart.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(savedCarts: carts);
    } catch (_) {
      // Ignore corrupted data.
    }
  }

  Future<void> _persistSavedCarts(List<SavedCart> carts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(carts.map((cart) => cart.toJson()).toList());
    await prefs.setString(_savedCartsKey, encoded);
  }
}

const _savedCartsKey = 'saved_carts';
