class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String storeName;
  final String? storeAddress;
  final String? city;
  final String? state;
  final String storePhoto;
  final String ownerPhoto;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.storeName,
    this.storeAddress,
    this.city,
    this.state,
    required this.storePhoto,
    required this.ownerPhoto,
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
