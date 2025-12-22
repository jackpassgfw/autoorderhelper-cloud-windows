import 'models.dart';

class CartState {
  const CartState({
    required this.items,
    required this.discountAmount,
    required this.savedCarts,
    required this.applyItemDiscount,
  });

  final List<CartItem> items;
  final double discountAmount;
  final List<SavedCart> savedCarts;
  final bool applyItemDiscount;

  int get itemCount =>
      items.fold(0, (total, item) => total + item.quantity);

  double get subtotal =>
      items.fold(0, (total, item) => total + item.lineTotal);

  double get itemDiscountTotal => applyItemDiscount
      ? items.fold(0, (total, item) => total + item.discountAmount)
      : 0;

  double get total {
    final totalValue = subtotal - itemDiscountTotal + discountAmount;
    return totalValue < 0 ? 0 : totalValue;
  }

  CartState copyWith({
    List<CartItem>? items,
    double? discountAmount,
    List<SavedCart>? savedCarts,
    bool? applyItemDiscount,
  }) {
    return CartState(
      items: items ?? this.items,
      discountAmount: discountAmount ?? this.discountAmount,
      savedCarts: savedCarts ?? this.savedCarts,
      applyItemDiscount: applyItemDiscount ?? this.applyItemDiscount,
    );
  }

  factory CartState.initial() {
    return const CartState(
      items: [],
      discountAmount: 0,
      savedCarts: [],
      applyItemDiscount: true,
    );
  }
}
