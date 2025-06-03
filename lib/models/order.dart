class Order {
  final int id;
  final Sales? sales;
  final Customer? customer;
  final List<OrderItem> items;
  final List<Payment> payments;
  final int quantity;
  final int totalPrice;
  final String? status;
  final int paid;
  final int remaining;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Sales? shipper;
  final DateTime? shippedAt;
  final String? shippingProof;
  final String? bukti_pengiriman;

  Order({
    required this.id,
    this.sales,
    this.customer,
    required this.items,
    required this.payments,
    required this.quantity,
    required this.totalPrice,
    this.status,
    required this.paid,
    required this.remaining,
    this.createdAt,
    this.updatedAt,
    this.shipper,
    this.shippedAt,
    this.shippingProof,
    this.bukti_pengiriman,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      sales: json['sales'] != null ? Sales.fromJson(json['sales']) : null,
      customer:
          json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      payments: (json['payments'] as List?)
              ?.map((payment) => Payment.fromJson(payment))
              .toList() ??
          [],
      quantity: json['quantity'] ?? 0,
      totalPrice: json['total_price'] ?? 0,
      status: json['status']?.toString(),
      paid: json['paid'] ?? 0,
      remaining: json['remaining'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
      shipper: json['shipper'] != null ? Sales.fromJson(json['shipper']) : null,
      shippedAt: json['shipped_at'] != null
          ? DateTime.parse(json['shipped_at'].toString())
          : null,
      shippingProof: json['shipping_proof']?.toString(),
      bukti_pengiriman: json['bukti_pengiriman']?.toString(),
    );
  }
}

class Sales {
  final int id;
  final String name;
  final String email;
  final Role role;

  Sales({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory Sales.fromJson(Map<String, dynamic> json) {
    return Sales(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role'] != null
          ? Role.fromJson(json['role'])
          : Role(name: '', displayName: ''),
    );
  }
}

class Role {
  final String name;
  final String displayName;

  Role({
    required this.name,
    required this.displayName,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String storeName;
  final String? storeAddress;
  final String city;
  final String state;
  final String? storePhoto;
  final String? ownerPhoto;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.storeName,
    this.storeAddress,
    required this.city,
    required this.state,
    this.storePhoto,
    this.ownerPhoto,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      storeName: json['store_name']?.toString() ?? '',
      storeAddress: json['store_address']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      storePhoto: json['store_photo']?.toString(),
      ownerPhoto: json['owner_photo']?.toString(),
    );
  }
}

class OrderItem {
  final String id;
  final String brand;
  final String name;
  final int quantity;
  final int total;
  final int price;
  final int returns;

  OrderItem({
    required this.id,
    required this.brand,
    required this.name,
    required this.quantity,
    required this.total,
    required this.price,
    required this.returns,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      total: json['total'] ?? 0,
      price: json['price'] ?? 0,
      returns: json['returns'] ?? 0,
    );
  }
}

class Payment {
  final String id;
  final int orderId;
  final String method;
  final DateTime date;
  final int amount;
  final int? userId;
  final int remaining;
  final String customer;
  final String? file;
  final String collector;
  final String? admin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastPaymentDate;
  final String? customerId;

  Payment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.date,
    required this.amount,
    this.file,
    this.userId,
    required this.remaining,
    required this.customer,
    required this.collector,
    this.admin,
    required this.createdAt,
    required this.updatedAt,
    this.lastPaymentDate,
    this.customerId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id'] ?? 0,
      method: json['method']?.toString() ?? '',
      date: DateTime.parse(
          json['date']?.toString() ?? DateTime.now().toIso8601String()),
      amount: json['amount'] ?? 0,
      userId: json['user_id'],
      remaining: json['remaining'] ?? 0,
      customer: json['customer']?.toString() ?? '',
      file: json['file']?.toString(),
      collector: json['collector']?.toString() ?? '',
      admin: json['admin']?.toString(),
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.parse(json['last_payment_date'].toString())
          : null,
      customerId: json['customer_id']?.toString(),
    );
  }
}
