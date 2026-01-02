class OrderItem {
  final int id;
  final int qteOrdered;
  final String orderDate;
  final int productId;
  final int userId;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? mobile;
  final int? approvedBy;
  final String? approvedAt;

  OrderItem({
    required this.id,
    required this.qteOrdered,
    required this.orderDate,
    required this.productId,
    required this.userId,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.mobile,
    this.approvedBy,
    this.approvedAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      qteOrdered: json['qteOrdered'] ?? 0,
      orderDate: json['orderDate'] ?? '',
      productId: json['productId'] ?? 0,
      userId: json['userId'] ?? 0,
      status: json['status'] ?? 'PENDING',
      paymentStatus: json['paymentStatus'] ?? (json['payment_status'] ?? 'PENDING'),
      paymentMethod: json['paymentMethod'] ?? json['payment_method'],
      mobile: json['mobile'] ?? json['phone'],
      approvedBy: json['approvedBy'] != null ? (json['approvedBy'] as num).toInt() : null,
      approvedAt: json['approvedAt'] ?? json['approved_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'qteOrdered': qteOrdered,
        'orderDate': orderDate,
        'productId': productId,
        'userId': userId,
        'status': status,
        'paymentStatus': paymentStatus,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (mobile != null) 'mobile': mobile,
        if (approvedBy != null) 'approvedBy': approvedBy,
        if (approvedAt != null) 'approvedAt': approvedAt,
      };
}
