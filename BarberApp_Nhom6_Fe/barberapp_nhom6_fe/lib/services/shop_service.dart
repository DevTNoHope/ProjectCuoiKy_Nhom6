import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/shop.dart';
import '../utils/secure_store.dart';

class ShopService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final SecureStore _store = SecureStore();

  // 🟢 Lấy danh sách tất cả shop
  Future<List<Shop>> getAll() async {
    final res = await _dio.get('/shops');
    if (res.statusCode == 200 && res.data is List) {
      return (res.data as List)
          .map((e) => Shop.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw Exception('Không thể tải danh sách cửa hàng');
  }

  // 🟡 Thêm mới shop
  Future<void> create({
    required String name,
    required String address,
    String? phone,
    bool isActive = true,
  }) async {
    final token = await _store.getToken();
    final res = await _dio.post(
      '/shops',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
      data: {
        'name': name,
        'address': address,
        'phone': phone,
        'is_active': isActive,
      },
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Thêm cửa hàng thất bại: ${res.data}');
    }
  }

  // ✏️ Cập nhật shop
  Future<void> update({
    required int id,
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) async {
    final token = await _store.getToken();
    final res = await _dio.put(
      '/shops/$id',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
      data: {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (isActive != null) 'is_active': isActive,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Cập nhật cửa hàng thất bại: ${res.data}');
    }
  }

  // 🔴 Xóa shop
  Future<void> delete(int id) async {
    final token = await _store.getToken();
    final res = await _dio.delete(
      '/shops/$id',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Xóa cửa hàng thất bại');
    }
  }
}
