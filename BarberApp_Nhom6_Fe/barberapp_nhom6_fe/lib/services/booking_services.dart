// lib/services/booking_services.dart
import 'package:dio/dio.dart';
import '../utils/secure_store.dart';
import '../models/booking_models.dart';

class ApiBase {
  final Dio _dio;
  final SecureStore _store = SecureStore();
  ApiBase({Dio? dio}): _dio = dio ?? Dio(BaseOptions(
    baseUrl: 'http://192.168.1.9:8000', // ví dụ 192.168.1.8
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  )){
    _dio.interceptors.add(LogInterceptor(requestBody:true, responseBody:false));
  }

  Future<Options> _auth() async {
    final t = await _store.getToken();
    return Options(headers: {'Authorization':'Bearer $t'});
  }

  Dio get dio => _dio;
}

class ShopService extends ApiBase {
  Future<List<Shop>> getShops() async {
    final res = await dio.get('/shops');
    final list = (res.data as List).cast<Map>();
    return list.map((e)=> Shop.fromJson(Map<String,dynamic>.from(e))).toList();
  }
}

class StylistService extends ApiBase {
  Future<List<Stylist>> getByShop(int shopId) async {
    final res = await dio.get('/stylists/shop/$shopId');
    final list = (res.data as List).cast<Map>();
    return list.map((e)=> Stylist.fromJson(Map<String,dynamic>.from(e))).toList();
  }
}

class ServiceService extends ApiBase {
  Future<List<ServiceModel>> getServices({int? shopId}) async {
    final res = await (shopId==null
        ? dio.get('/services')
        : dio.get('/services', queryParameters: {'shop_id': shopId}));
    final list = (res.data as List).cast<Map>();
    return list.map((e)=> ServiceModel.fromJson(Map<String,dynamic>.from(e))).toList();
  }
}

class ScheduleService extends ApiBase {
  Future<List<WorkBlock>> getStylistBlocks(int stylistId) async {
    final res = await dio.get('/work-schedules/stylist/$stylistId');
    final list = (res.data as List).cast<Map>();
    return list.map((e) => WorkBlock.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}

class BookingService extends ApiBase {
  Future<List<BookingShort>> getStylistBookings({
    required int stylistId,
    required DateTime date,
  }) async {
    final res = await dio.get(
      '/bookings/stylist/$stylistId',
      queryParameters: {'date': date.toIso8601String().substring(0, 10)},
      options: await _auth(),
    );
    final list = (res.data as List).cast<Map>();
    return list
        .map((e) => BookingShort.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
  Future<List<Map<String, dynamic>>> getMyBookings() async {
    final res = await dio.get('/bookings/me', options: await _auth());
    final list = (res.data as List).cast<Map>();
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  Future<void> create(BookingCreateReq req) async {
    await dio.post('/bookings', data: req.toJson(), options: await _auth());
  }
}
