import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../models/notification_model.dart';
import '../utils/secure_store.dart';
import '../config/api_config.dart';

class NotificationService {
  // Ví dụ: http://10.0.2.2:8000 hoặc http://192.168.1.x:8000
  static const String _baseUrl = ApiConfig.baseUrl;

  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'accept': 'application/json',
        'content-type': 'application/json',
      },
    ),
  );

  final SecureStore _store = SecureStore();

  // ---------------- OneSignal ----------------
  static Future<String?> getPlayerId() async {
    return OneSignal.User.getOnesignalId();
  }

  static Future<bool> registerPlayerId(String jwt) async {
    final id = await getPlayerId();
    if (id == null) return false;

    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
      ),
    );

    final res = await dio.post('/auth/me/onesignal', data: {
      'player_id': id,
      'platform': 'android',
    });

    return res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
  }

  // ---------------- Notifications API ----------------

  /// Lấy danh sách thông báo của *chính user* đang đăng nhập
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final token = await _store.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('🔒 No JWT -> return []');
      return [];
    }

    try {
      final uri = '/notifications/me';
      debugPrint('📡 GET $_baseUrl$uri?unread_only=$unreadOnly&limit=$limit&offset=$offset');

      final res = await _dio.get(
        uri,
        queryParameters: {
          'unread_only': unreadOnly,
          'limit': limit,
          'offset': offset,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode != 200) {
        debugPrint('⚠️ Status ${res.statusCode} - ${res.data}');
        return [];
      }

      final raw = res.data;
      if (raw is! List) {
        debugPrint('⚠️ Response is not a List. Data: ${res.data}');
        return [];
      }

      final list = raw.cast<Map>();
      final items = list
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // cập nhật badge
      final unread = items.where((n) => n.isRead == false).length;
      NotificationService.unreadCount.value = unread;

      debugPrint('📊 Loaded ${items.length} notifications (unread=$unread)');
      return items;
    } on DioException catch (e) {
      debugPrint('❌ getNotifications DioError: ${e.response?.statusCode} - ${e.response?.data}');
      return [];
    } catch (e) {
      debugPrint('❌ getNotifications error: $e');
      return [];
    }
  }

  /// Đánh dấu 1 thông báo đã đọc
  Future<bool> markAsRead(int notificationId) async {
    final token = await _store.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final uri = '/notifications/$notificationId/read';
      debugPrint('📡 PUT $_baseUrl$uri');

      await _dio.put(
        uri,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } on DioException catch (e) {
      debugPrint('❌ markAsRead DioError: ${e.response?.statusCode} - ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('❌ markAsRead error: $e');
      return false;
    }
  }

  // (Tuỳ chọn) lắng nghe push
  static void setupOpenedHandler() {
    final service = NotificationService();

    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData ?? {};
      final screen = data['screen'];
      final bookingId = data['bookingId'];
      debugPrint('🔔 Click push: screen=$screen, bookingId=$bookingId');
      // TODO: điều hướng nếu cần
    });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault();
      event.notification.display();
      debugPrint('🔔 Push in foreground');

      // tăng badge tạm thời & reload thật từ server
      unreadCount.value = unreadCount.value + 1;
      service.getNotifications().catchError((e) {
        debugPrint('❌ reload after push error: $e');
      });
    });
  }

  static void resetUnread() {
    unreadCount.value = 0;
  }
}
