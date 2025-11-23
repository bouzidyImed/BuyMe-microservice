class OrderItem {
  final int id;
  final int qteOrdered;
  final String orderDate;
  final int productId;
  final int userId;
  final String status;

  OrderItem({
    required this.id,
    required this.qteOrdered,
    required this.orderDate,
    required this.productId,
    required this.userId,
    required this.status,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      qteOrdered: json['qteOrdered'] ?? 0,
      orderDate: json['orderDate'] ?? '',
      productId: json['productId'] ?? 0,
      userId: json['userId'] ?? 0,
      status: json['status'] ?? 'PENDING',
    );
  }
}
