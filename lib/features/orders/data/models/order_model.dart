class Order {
  final String id;
  final String clientName;
  final String status;
  final double totalAmount;
  final DateTime orderDate;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.clientName,
    required this.status,
    required this.totalAmount,
    required this.orderDate,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      clientName: json['clientName']?.isNotEmpty == true 
          ? json['clientName'] 
          : (json['user'] != null && json['user']['firstName'] != null)
              ? '${json['user']['firstName']} ${json['user']['lastName'] ?? ''}'.trim()
              : 'Guest',
      status: json['status'],
      totalAmount: double.parse(json['totalAmount'].toString()),
      orderDate: DateTime.parse(json['orderDate']),
      items: (json['items'] as List?)?.map((i) => OrderItem.fromJson(i)).toList() ?? [],
    );
  }
}

class OrderItem {
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['product']?['name'] ?? 'Item',
      quantity: json['quantity'] ?? 1,
      price: double.parse(json['finalPricePerUnit']?.toString() ?? '0'),
    );
  }
}
