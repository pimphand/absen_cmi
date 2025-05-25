class CartItem {
  final String productId;
  final String name;
  final String brand;
  final String imageUrl;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'brand': brand,
      'image_url': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'],
      name: json['name'],
      brand: json['brand'],
      imageUrl: json['image_url'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
    );
  }
}
