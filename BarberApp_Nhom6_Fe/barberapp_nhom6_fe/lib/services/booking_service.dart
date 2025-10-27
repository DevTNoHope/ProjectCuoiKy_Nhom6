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

  // 🟢 Admin tạo booking thay user khác
  Future<void> create({
    required int userId,
    required int shopId,
    int? stylistId,
    required String startDt,
    required String endDt,
    required double totalPrice,
    required List<Map<String, dynamic>> services,
    String? note,
  }) async {
    final token = await _store.getToken();
    try {
      final res = await _dio.post(
        '/bookings',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "user_id": userId,
          "shop_id": shopId,
          "stylist_id": stylistId,
          "start_dt": startDt,
          "end_dt": endDt,
          "total_price": totalPrice,
          "note": note ?? "Admin booking for user",
          "services": services,
        },
      );

      if (res.statusCode != 201 && res.statusCode != 200) {
        throw Exception('Tạo booking thất bại: ${res.data}');
      }

      print("✅ Booking created successfully: ${res.statusCode}");
    } on DioException catch (e) {
      print("❌ Booking create error: ${e.response?.data}");
      rethrow;
    }
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

  // 🔵 ✅ Đánh dấu hoàn thành booking
  Future<void> complete(int id) async {
    final token = await _store.getToken();
    try {
      final res = await _dio.put(
        '/bookings/$id',
        data: {'status': 'completed'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print("✅ Complete response: ${res.statusCode}");
    } on DioException catch (e) {
      print("❌ Complete error: ${e.response?.data}");
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

  // 🆕 ✅ Lấy danh sách khung giờ trống của stylist (cho AdminBookingCreatePage)
  Future<List<Map<String, String>>> getAvailableSlots(int stylistId, String date) async {
    final token = await _store.getToken();
    try {
      final res = await _dio.get(
        '/bookings/stylist/$stylistId/available',
        queryParameters: {'date': date},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = (res.data as List).cast<Map<String, dynamic>>();
      return data
          .map((e) => {
        'start': e['start'] as String,
        'end': e['end'] as String,
      })
          .toList();
    } on DioException catch (e) {
      print("❌ Get available slots error: ${e.response?.data}");
      rethrow;
    }
  }
}
