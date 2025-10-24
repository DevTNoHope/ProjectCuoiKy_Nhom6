import 'package:dio/dio.dart';
import '../models/booking.dart';
import '../utils/secure_store.dart';
import '../config/api_config.dart';

class BookingService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final SecureStore _store = SecureStore();

  // 🟢 Lấy toàn bộ booking (admin)
  Future<List<Booking>> getAll() async {
    final token = await _store.getToken();
    final res = await _dio.get(
      '/bookings',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (res.data as List)
        .map((e) => Booking.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // 🟡 Duyệt booking
  Future<void> approve(int id) async {
    final token = await _store.getToken();
    try {
      final res = await _dio.put(
        '/bookings/$id',
        data: {'status': 'approved'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print("✅ Approve response: ${res.statusCode}");
    } on DioException catch (e) {
      print("❌ Approve error: ${e.response?.data}");
      rethrow;
    }
  }

  // 🔴 Hủy booking
  Future<void> cancel(int id) async {
    final token = await _store.getToken();
    try {
      final res = await _dio.put(
        '/bookings/$id',
        data: {'status': 'cancelled'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print("✅ Cancel response: ${res.statusCode}");
    } on DioException catch (e) {
      print("❌ Cancel error: ${e.response?.data}");
      rethrow;
    }
  }

  // 🗑 Xóa booking
  Future<void> delete(int id) async {
    final token = await _store.getToken();
    try {
      final res = await _dio.delete(
        '/bookings/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print("✅ Delete response: ${res.statusCode}");
    } on DioException catch (e) {
      print("❌ Delete error: ${e.response?.data}");
      rethrow;
    }
  }
}
