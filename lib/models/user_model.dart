class User {
  final int id;
  final String name;
  final String? email;
  final Map<String, dynamic>? role;

  User({required this.id, required this.name, this.email, this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      role: json['role'] is Map ? json['role'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'role': role};
  }

  String get roleName => role?['display_name'] ?? role?['name'] ?? 'User';
}
