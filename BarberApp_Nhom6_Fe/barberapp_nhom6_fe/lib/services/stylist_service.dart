import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../utils/secure_store.dart';
import '../models/stylist.dart';

class StylistService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)); // ✅
  final SecureStore _store = SecureStore();

  // 🟢 Lấy danh sách stylist
  Future<List<Stylist>> getAll() async {
    final res = await _dio.get('/stylists');
    return (res.data as List)
        .map((e) => Stylist.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // 🟡 Tạo stylist (Admin)
  Future<void> create({
    required int shopId,
    required String name,
    String? bio,
    String? avatarUrl,
    bool isActive = true,
    List<int>? serviceIds,
  }) async {
    final token = await _store.getToken();
    final res = await _dio.post(
      '/stylists',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
      data: {
        'shop_id': shopId,
        'name': name,
        'bio': bio,
        'is_active': true,
        'service_ids': serviceIds ?? [],
      },
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Tạo stylist thất bại: ${res.data}');
    }
  }

  // ✏️ Cập nhật stylist
  Future<void> update(
      int id,
      String name,
      String? bio, {
        List<int>? serviceIds,
      }) async {
    final token = await _store.getToken();
    final res = await _dio.put(
      '/stylists/$id',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
      data: {
        'name': name,
        'bio': bio,
        'service_ids': serviceIds ?? [],
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Cập nhật stylist thất bại: ${res.data}');
    }
  }

  // 🔴 Xóa stylist
  Future<void> delete(int id) async {
    final token = await _store.getToken();
    final res = await _dio.delete(
      '/stylists/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Xóa stylist thất bại');
    }
  }
}
