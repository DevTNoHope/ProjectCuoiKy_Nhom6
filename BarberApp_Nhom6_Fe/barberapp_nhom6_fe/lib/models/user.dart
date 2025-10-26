class UserModel {
  final int id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? role;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.role,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      role: json['role'],
      avatarUrl: json['avatar_url'],
    );
  }
}
