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
  /// GET /reviews/booking/{booking_id}
  /// Nếu BE trả 404 -> return null thay vì throw.
  Future<Review?> getByBookingId(int bookingId) async {
    final token = await _store.getToken();
    if (token == null || token.isEmpty) throw Exception("Bạn chưa đăng nhập");

    final path = '/reviews/booking/$bookingId';
    debugPrint('🛰️ GET ${AuthService.BASE_URL}$path');

    final res = await _dio.get(
      path,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (code) => true,
      ),
    );

    if (res.statusCode == 200 && res.data is Map) {
      return Review.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    if (res.statusCode == 404) return null;

    if (res.statusCode == 401) throw Exception('401 Unauthorized: Token thiếu/sai/hết hạn.');
    throw Exception('GET $path failed (${res.statusCode}): ${res.data}');
  }

  /// POST /reviews
  /// Body (BE hiện yêu cầu): { booking_id, user_id, rating, comment? }
  Future<Review> create({
    required int bookingId,
    required int userId,
    required int rating,
    String? comment,
  }) async {
    final token = await _store.getToken();
    if (token == null || token.isEmpty) throw Exception("Bạn chưa đăng nhập");

    const path = '/reviews';
    final body = {
      'booking_id': bookingId,
      'user_id': userId,          // BE của bạn đang yêu cầu field này
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    };

    debugPrint('🛰️ POST ${AuthService.BASE_URL}$path body=$body');

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

    if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map) {
      return Review.fromJson(Map<String, dynamic>.from(res.data as Map));
    }

    if (res.statusCode == 400) {
      throw Exception('400 Bad Request: ${res.data}');
    }
    if (res.statusCode == 401) {
      throw Exception('401 Unauthorized: Token thiếu/sai/hết hạn.');
    }
    if (res.statusCode == 404) {
      throw Exception('404 Not Found: booking_id hoặc endpoint không đúng. ${res.data}');
    }
    if (res.statusCode == 422) {
      throw Exception('422 Unprocessable: Body không hợp lệ. ${res.data}');
    }
    throw Exception('POST $path failed (${res.statusCode}): ${res.data}');
  }

  /// PUT /reviews/{id}
  /// Body: { rating, comment? }
  Future<Review> update({
    required int reviewId,
    required int rating,
    String? comment,
  }) async {
    final token = await _store.getToken();
    if (token == null || token.isEmpty) throw Exception("Bạn chưa đăng nhập");

    final path = '/reviews/$reviewId';
    final body = {
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    };

    debugPrint('🛰️ PUT ${AuthService.BASE_URL}$path body=$body');

    final res = await _dio.put(
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

    if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map) {
      return Review.fromJson(Map<String, dynamic>.from(res.data as Map));
    }

    if (res.statusCode == 401) throw Exception('401 Unauthorized: Token thiếu/sai/hết hạn.');
    if (res.statusCode == 404) throw Exception('404 Not Found: review_id không tồn tại.');
    if (res.statusCode == 422) throw Exception('422 Unprocessable: Body không hợp lệ. ${res.data}');
    throw Exception('PUT $path failed (${res.statusCode}): ${res.data}');
  }

  /// Upsert: đã có review cho booking -> update; chưa có -> create.
  Future<Review> upsertForBooking({
    required int bookingId,
    required int userId,
    required int rating,
    String? comment,
  }) async {
    final existing = await getByBookingId(bookingId);
    if (existing == null) {
      return await create(
        bookingId: bookingId,
        userId: userId,
        rating: rating,
        comment: comment,
      );
    }
    return await update(
      reviewId: existing.id,
      rating: rating,
      comment: comment,
    );
  }

}
