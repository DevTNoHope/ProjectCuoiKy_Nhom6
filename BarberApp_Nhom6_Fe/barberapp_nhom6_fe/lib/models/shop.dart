class Shop {
  final int id;
  final String name;
  final String address;
  final String? phone;
  final bool isActive;
  final double? lat;
  final double? lng;
  final String? openTime;
  final String? closeTime;

  Shop({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    required this.isActive,
    this.lat,
    this.lng,
    this.openTime,
    this.closeTime,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as int,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      lat: (json['lat'] != null)
          ? double.tryParse(json['lat'].toString())
          : null,
      lng: (json['lng'] != null)
          ? double.tryParse(json['lng'].toString())
          : null,
      openTime: json['open_time'],
      closeTime: json['close_time'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'phone': phone,
    'is_active': isActive,
    'lat': lat,
    'lng': lng,
    'open_time': openTime,
    'close_time': closeTime,
  };
}
