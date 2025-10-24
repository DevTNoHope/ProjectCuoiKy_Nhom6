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
}
