class Shop {
  final int id;
  final String name;
  final String address;
  final String? phone;
  final bool isActive;

  Shop({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    required this.isActive,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as int,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'phone': phone,
    'is_active': isActive,
  };
}
