// lib/services/review_service.dart
import 'package:dio/dio.dart';
import '../models/review.dart';
import 'auth_service.dart';
import '../utils/secure_store.dart';
import 'package:flutter/foundation.dart';

class ReviewService {
  final Dio _dio;
  final SecureStore _store;

  ReviewService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: AuthService.BASE_URL)),
        _store = SecureStore();

  Future<List<Review>> getAll() async {
    final token = await _store.getToken();
    final res = await _dio.get(
      '/reviews',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (res.statusCode == 200 && res.data is List) {
      final list = <Review>[];
      for (final e in (res.data as List)) {
        try { list.add(Review.fromJson(Map<String, dynamic>.from(e))); } catch (_) {}
      }
      return list;
    }
    throw Exception('Failed to load reviews (${res.statusCode})');
  }


  Future<void> reply(int reviewId, String replyText, {int adminId = 1}) async {
    final token = await _store.getToken();
    if (token == null || token.isEmpty) throw Exception("Bạn chưa đăng nhập");


    const path = '/reviews/reply';

    final body = {
      'review_id': reviewId,
      'reply': replyText.trim(),
      'admin_id': adminId, // nếu BE không cần thì bỏ dòng này
    };

    // Log để xác nhận URL thực sự đang gọi
    debugPrint('🛰️ POST ${AuthService.BASE_URL}$path  body=$body');

    final res = await _dio.post(
      path,
      data: body,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        validateStatus: (code) => true,
      ),
    );

    if (res.statusCode == 200 || res.statusCode == 201) return;

    if (res.statusCode == 404) {
      throw Exception('404 Not Found: Sai endpoint "$path" hoặc review_id=$reviewId không tồn tại. '
          'Response: ${res.data}');
    }
    if (res.statusCode == 401) {
      throw Exception('401 Unauthorized: Token thiếu/sai/hết hạn.');
    }
    if (res.statusCode == 422) {
      throw Exception('422 Unprocessable: Body không hợp lệ. Response: ${res.data}');
    }
    throw Exception('Reply failed at $path (${res.statusCode}): ${res.data}');
  }

  /// 🔹 Lấy danh sách review của user hiện tại
  Future<List<Review>> getMyReviews() async {
    final token = await _store.getToken();
    final res = await _dio.get(
      '/reviews/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (res.statusCode == 200 && res.data is List) {
      return (res.data as List)
          .map((e) => Review.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw Exception('Failed to load my reviews (${res.statusCode})');
  }

  /// 🔹 Lấy chi tiết review của user theo ID
  Future<Review> getMyReview(int id) async {
    final token = await _store.getToken();
    final res = await _dio.get(
      '/reviews/me/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Review.fromJson(Map<String, dynamic>.from(res.data));
  }

  /// 🔹 Tạo review mới cho booking đã hoàn thành
  Future<void> createReview(Map<String, dynamic> data) async {
    final token = await _store.getToken();

    // ✅ Lấy user_id từ token
    final userId = await AuthService().getCurrentUserId();
    if (userId == null) {
      throw Exception('Không thể xác định user_id (chưa đăng nhập?)');
    }

    // ✅ Bổ sung user_id vào body nếu chưa có
    final body = Map<String, dynamic>.from(data);
    body['user_id'] = userId;

    debugPrint('🛰️ POST /reviews  body=$body');

    final res = await _dio.post(
      '/reviews',
      data: body,
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      debugPrint('❌ Review create failed: ${res.statusCode} ${res.data}');
      throw Exception('Create review failed: ${res.data}');
    }

    debugPrint('✅ Review created successfully!');
  }


  /// 🔹 Cập nhật review của chính user
  Future<void> updateMyReview(int id, Map<String, dynamic> data) async {
    final token = await _store.getToken();
    final res = await _dio.put(
      '/reviews/me/$id',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (res.statusCode != 200) {
      throw Exception('Update review failed (${res.statusCode}): ${res.data}');
    }
  }

  /// 🔹 Xóa review của user hiện tại
  Future<void> deleteMyReview(int id) async {
    final token = await _store.getToken();
    final res = await _dio.delete(
      '/reviews/me/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (res.statusCode != 200) {
      throw Exception('Delete review failed (${res.statusCode}): ${res.data}');
    }
  }
}
