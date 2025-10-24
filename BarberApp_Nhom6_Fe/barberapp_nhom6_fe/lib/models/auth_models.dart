// lib/models/auth_models.dart
class LoginRequest {
  final String username; // email hoặc phone (BE hỗ trợ cả 2)
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {
    "username": username,
    "password": password,
  };
}

class RegisterRequest {
  final String fullName;
  final String? email;
  final String? phone;
  final String password;

  RegisterRequest({
    required this.fullName,
    required this.password,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName, // BE dùng snake_case
    'email': email,
    'phone': phone,
    'password': password,
  }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
}

class LoginResponse {
  final String accessToken;
  final String tokenType;

  LoginResponse({required this.accessToken, required this.tokenType});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json["access_token"] as String,
      tokenType: json["token_type"] as String? ?? "bearer",
    );
  }
}
