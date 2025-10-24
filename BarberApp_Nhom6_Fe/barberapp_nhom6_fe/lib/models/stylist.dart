class Stylist {
  final int id;
  final int shopId;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final bool isActive;
  final List<int>? serviceIds; // <-- Thêm

  Stylist({
    required this.id,
    required this.shopId,
    required this.name,
    this.bio,
    this.avatarUrl,
    required this.isActive,
    this.serviceIds,
  });

  factory Stylist.fromJson(Map<String, dynamic> json) {
    return Stylist(
      id: json['id'] as int,
      shopId: json['shop_id'] as int,
      name: json['name'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
      serviceIds: json['service_ids'] != null
          ? List<int>.from(json['service_ids'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shop_id': shopId,
    'name': name,
    'bio': bio,
    'avatar_url': avatarUrl,
    'is_active': isActive,
    'service_ids': serviceIds,
  };
}
