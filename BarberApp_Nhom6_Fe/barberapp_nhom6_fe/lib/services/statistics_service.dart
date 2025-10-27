import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../utils/secure_store.dart';

class StatisticsService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final SecureStore _store = SecureStore();

  Future<List<Map<String, dynamic>>> getBookingsByMonth() async {
    final token = await _store.getToken();
    final res = await _dio.get(
      '/statistics/bookings/monthly',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> getTopServices() async {
    final token = await _store.getToken();
    final res = await _dio.get(
      '/statistics/top-services',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<Map<String, dynamic>> getSummary() async {
    final token = await _store.getToken();
    final res = await _dio.get(
      '/statistics/summary',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(res.data);
  }
}
