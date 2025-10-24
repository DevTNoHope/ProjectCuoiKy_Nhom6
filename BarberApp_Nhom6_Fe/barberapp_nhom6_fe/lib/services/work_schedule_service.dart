import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/work_schedule.dart';
import '../utils/secure_store.dart';

class WorkScheduleService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)); // ✅
  final SecureStore _store = SecureStore();

  // 🟢 Lấy tất cả ca làm
  Future<List<WorkSchedule>> getAll() async {
    final res = await _dio.get('/work-schedules');
    return (res.data as List)
        .map((e) => WorkSchedule.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // 🟢 Lấy ca làm của 1 stylist
  Future<List<WorkSchedule>> getByStylist(int stylistId) async {
    final res = await _dio.get('/work-schedules/stylist/$stylistId');
    return (res.data as List)
        .map((e) => WorkSchedule.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // 🟡 Tạo mới ca làm
  Future<void> create({
    required int stylistId,
    required String weekday,
    required String startTime,
    required String endTime,
  }) async {
    final token = await _store.getToken();
    final res = await _dio.post(
      '/work-schedules',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
      data: {
        'stylist_id': stylistId,
        'weekday': weekday,
        'start_time': startTime,
        'end_time': endTime,
      },
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Tạo ca làm thất bại: ${res.data}');
    }
  }

  // ✏️ Cập nhật
  Future<void> update(
      int id, {
        String? weekday,
        String? startTime,
        String? endTime,
      }) async {
    final token = await _store.getToken();
    final res = await _dio.put(
      '/work-schedules/$id',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
      data: {
        if (weekday != null) 'weekday': weekday,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Cập nhật thất bại: ${res.data}');
    }
  }

  // 🔴 Xóa
  Future<void> delete(int id) async {
    final token = await _store.getToken();
    final res = await _dio.delete(
      '/work-schedules/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Xóa ca làm thất bại');
    }
  }
}
