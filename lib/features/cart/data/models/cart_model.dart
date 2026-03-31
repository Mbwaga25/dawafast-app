class CartItem {
  final String productId;
  final String name;
  final double price;
  final String? image;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.image,
    this.quantity = 1,
  });

  double get total => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      price: price,
      image: image,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  final List<CartItem> items;
  final double deliveryFee;

  CartState({
    this.items = const [],
    this.deliveryFee = 1500.0, // Base delivery fee in local currency
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get total => subtotal + (items.isEmpty ? 0 : deliveryFee);

  CartState copyWith({List<CartItem>? items, double? deliveryFee}) {
    return CartState(
      items: items ?? this.items,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }
}
