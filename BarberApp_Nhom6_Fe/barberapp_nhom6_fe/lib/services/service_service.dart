import 'package:dio/dio.dart';
import '../models/service.dart';
import 'auth_service.dart';
import '../utils/secure_store.dart';

class ServiceService {
  final Dio _dio;
  final SecureStore _store;

  ServiceService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: AuthService.BASE_URL)),
        _store = SecureStore();

  // Lấy tất cả dịch vụ
  Future<List<Service>> getAll() async {
    final res = await _dio.get('/services');
    if (res.statusCode == 200) {
      final data = res.data;
      if (data is List) return data.map((e) => Service.fromJson(e)).toList();
    }
    throw Exception('Failed to load services');
  }

  // Thêm dịch vụ mới (Admin)
  Future<void> create(String name, String description, double price) async {
    final token = await _store.getToken();
    if (token == null || token.isEmpty) throw Exception("Bạn chưa đăng nhập");

    final res = await _dio.post(
      '/services',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
      data: {'name': name, 'description': description, 'price': price},
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Create failed: ${res.data}');
    }
  }

  // Xóa dịch vụ
  Future<void> delete(int id) async {
    final token = await _store.getToken();
    if (token == null || token.isEmpty) throw Exception("Bạn chưa đăng nhập");

    final res = await _dio.delete(
      '/services/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Delete failed: ${res.data}');
    }
  }

  // 🟢 Cập nhật dịch vụ
  Future<void> update(int id, String name, String description, double price) async {
    final token = await _store.getToken();
    if (token == null || token.isEmpty) throw Exception("Bạn chưa đăng nhập");

    final res = await _dio.put(
      '/services/$id',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
      data: {
        'name': name,
        'description': description,
        'price': price,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Update failed: ${res.data}');
    }
  }

}
