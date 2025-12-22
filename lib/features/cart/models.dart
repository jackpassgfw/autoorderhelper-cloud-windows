import '../products/models.dart';

class CartItem {
  CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  static const double discountRate = 0.1;

  double get unitPrice => product.distributorPriceAud ?? 0;

  double get lineTotal => unitPrice * quantity;

  double get discountAmount => lineTotal * discountRate;

  double get lineTotalAfterDiscount => lineTotal - discountAmount;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class SavedCartItem {
  const SavedCartItem({required this.productId, required this.quantity});

  final int productId;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {'productId': productId, 'quantity': quantity};
  }

  factory SavedCartItem.fromJson(Map<String, dynamic> json) {
    return SavedCartItem(
      productId: json['productId'] as int,
      quantity: json['quantity'] as int,
    );
  }
}

class SavedCart {
  const SavedCart({required this.name, required this.items});

  final String name;
  final List<SavedCartItem> items;

  int get totalQuantity =>
      items.fold(0, (total, item) => total + item.quantity);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory SavedCart.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return SavedCart(
      name: json['name'] as String? ?? '',
      items: itemsJson
          .map((item) => SavedCartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
