import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../utils/secure_store.dart';

class UserService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final SecureStore _store = SecureStore();

  // 🟢 Lấy danh sách user (Admin)
  Future<List<UserModel>> getAll() async {
    final token = await _store.getToken();
    final res = await _dio.get(
      '/users', // ✅ endpoint cần có trên backend
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (res.data as List)
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
