// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../utils/secure_store.dart';
import '../models/auth_models.dart';

class AuthService {
  final Dio _dio;
  final SecureStore _store;

  // Đổi BASE_URL theo server của bạn

  static const String BASE_URL = 'http://192.168.1.27:8000'; // emulator Android -> host

  // Nếu chạy máy thật cùng LAN, đổi thành IP máy: http://192.168.x.x:8000

  AuthService({Dio? dio, SecureStore? store})
      : _dio = dio ??
      Dio(BaseOptions(
        baseUrl: BASE_URL,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
      )),
        _store = store ?? SecureStore();


  // Helpers
  Future<Options> _authHeader() async {
    final token = await _store.getToken();
    return Options(headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
  }

  Future<void> register(RegisterRequest req) async {
    try {
      await _dio.post('/auth/register', data: req.toJson());
    } on DioException catch (e) {
      throw _extractError(e);
    }
  }

  Future<void> login(LoginRequest req) async {
    try {
      final res = await _dio.post('/auth/login', data: req.toJson());
      final Map<String, dynamic> data =
      res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      final loginRes = LoginResponse.fromJson(data);
      await _store.saveToken(loginRes.accessToken);
    } on DioException catch (e) {
      throw _extractError(e);
    }
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final res = await _dio.get('/auth/me', options: await _authHeader());
      final Map<String, dynamic> meData =
      res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      return meData;

    } on DioException catch (e) {
      throw _extractError(e);
    }
  }

  Future<void> logout() async {
    await _store.deleteToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _store.getToken();
    if (token == null || token.isEmpty) return false;
    if (JwtDecoder.isExpired(token)) {
      await logout();
      return false;
    }
    return true;
  }

  Future<String?> getRole() async {
    final token = await _store.getToken();
    if (token == null) return null;
    try {
      final decoded = JwtDecoder.decode(token);
      // BE đã nhúng role trong payload (vd: {"sub": "user_id", "role":"Admin"})
      return decoded['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _extractError(DioException e) {
    // Chuẩn hoá thông báo lỗi trả về từ FastAPI
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        // lỗi validation
        final first = detail.first;
        if (first is Map && first['msg'] != null) return first['msg'];
      }
      return detail.toString();
    }
    return e.message ?? 'Network error';
  }
}
