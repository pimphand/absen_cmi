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
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
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
      status: json['status'],
      paid: json['paid'] ?? 0,
      remaining: json['remaining'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
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
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: Role.fromJson(json['role']),
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
      name: json['name'],
      displayName: json['display_name'],
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
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      storeName: json['store_name'],
      storeAddress: json['store_address'],
      city: json['city'],
      state: json['state'],
      storePhoto: json['store_photo'],
      ownerPhoto: json['owner_photo'],
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
      id: json['id'],
      brand: json['brand'],
      name: json['name'],
      quantity: json['quantity'],
      total: json['total'],
      price: json['price'],
      returns: json['returns'],
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
      id: json['id'],
      orderId: json['order_id'],
      method: json['method'],
      date: DateTime.parse(json['date']),
      amount: json['amount'],
      file: json['file'],
      userId: json['user_id'],
      remaining: json['remaining'],
      customer: json['customer'],
      collector: json['collector'],
      admin: json['admin'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.parse(json['last_payment_date'])
          : null,
      customerId: json['customer_id'],
    );
  }
}
