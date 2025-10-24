// lib/models/booking_models.dart
import 'dart:convert';

/// ================== Helpers ==================

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is num) return v.toInt();
  if (v is String) {
    final s = v.trim().replaceAll(',', '');
    // Try int first
    final i = int.tryParse(s);
    if (i != null) return i;
    // Then decimal "120000.00"
    final d = double.tryParse(s);
    if (d != null) return d.round();
  }
  return 0;
}

num _asNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  if (v is String) {
    final s = v.trim().replaceAll(',', '');
    final d = double.tryParse(s);
    if (d != null) return d;
    final i = int.tryParse(s);
    if (i != null) return i;
  }
  return 0;
}

/// Parse ISO string; if no timezone info, assume it's UTC to avoid local-time drift.
DateTime _parseIsoAssumeUtc(String s) {
  final dt = DateTime.parse(s);
  if (dt.isUtc) return dt;
  // dt is naive (no Z); treat as UTC
  return DateTime.utc(
    dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.millisecond, dt.microsecond,
  );
}

/// ================== Core Models ==================

class Shop {
  final int id;
  final String name;
  final String? address;

  Shop({required this.id, required this.name, this.address});

  factory Shop.fromJson(Map<String, dynamic> j) =>
      Shop(id: j['id'] as int, name: j['name'] as String, address: j['address'] as String?);
}

class Stylist {
  final int id;
  final String name;
  final int shopId;

  Stylist({required this.id, required this.name, required this.shopId});

  factory Stylist.fromJson(Map<String, dynamic> j) =>
      Stylist(id: j['id'] as int, name: j['name'] as String, shopId: j['shop_id'] as int);
}

class ServiceModel {
  final int id;
  final String name;
  final int durationMin;
  final int price;

  ServiceModel({
    required this.id,
    required this.name,
    required this.durationMin,
    required this.price,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> j) => ServiceModel(
    id: j['id'] as int,
    name: j['name'] as String,
    durationMin: _asInt(j['duration_min'] ?? j['duration']),
    price: _asInt(j['price']),
  );
}

/// Lịch làm việc theo giờ trong ngày (HH:MM:SS)
class WorkBlock {
  final String startTime; // "HH:MM:SS"
  final String endTime;   // "HH:MM:SS"

  WorkBlock({required this.startTime, required this.endTime});

  factory WorkBlock.fromJson(Map<String, dynamic> j) => WorkBlock(
    startTime: (j['start_time'] ?? j['start'] ?? '') as String,
    endTime:   (j['end_time']   ?? j['end']   ?? '') as String,
  );

  DateTime _parse(String hhmmss, DateTime date) {
    final p = hhmmss.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    final s = p.length > 2 ? int.parse(p[2]) : 0;
    return DateTime(date.year, date.month, date.day, h, m, s);
  }

  DateTime startOn(DateTime date) => _parse(startTime, date);
  DateTime endOn(DateTime date)   => _parse(endTime, date);
}

/// Booking rút gọn để lọc slot (server trả ISO datetime)
class BookingShort {
  final DateTime start; // UTC inside
  final DateTime end;   // UTC inside

  BookingShort({required this.start, required this.end});

  factory BookingShort.fromJson(Map<String, dynamic> j) {
    final s = (j['start_dt'] ?? j['start_time']) as String;
    final e = (j['end_dt']   ?? j['end_time']) as String;
    return BookingShort(
      start: _parseIsoAssumeUtc(s),
      end:   _parseIsoAssumeUtc(e),
    );
  }
}

/// ================== Request tạo booking ==================

class BookingServiceItemReq {
  final int serviceId;
  final int price;
  final int durationMin;

  BookingServiceItemReq({
    required this.serviceId,
    required this.price,
    required this.durationMin,
  });

  Map<String, dynamic> toJson() => {
    'service_id': serviceId,
    'price': price,
    'duration_min': durationMin,
  };
}

class BookingCreateReq {
  final int shopId;
  final int stylistId;
  final DateTime startDtUtc; // must be UTC when sending
  final DateTime endDtUtc;   // must be UTC when sending
  final int totalPrice;
  final String? note;
  final List<BookingServiceItemReq> services;

  BookingCreateReq({
    required this.shopId,
    required this.stylistId,
    required this.startDtUtc,
    required this.endDtUtc,
    required this.totalPrice,
    required this.services,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'shop_id': shopId,
    'stylist_id': stylistId,
    'start_dt': startDtUtc.isUtc ? startDtUtc.toIso8601String() : startDtUtc.toUtc().toIso8601String(),
    'end_dt':   endDtUtc.isUtc   ? endDtUtc.toIso8601String()   : endDtUtc.toUtc().toIso8601String(),
    'total_price': totalPrice,
    if (note != null && note!.trim().isNotEmpty) 'note': note,
    'services': services.map((e) => e.toJson()).toList(),
  };

  @override
  String toString() => jsonEncode(toJson());
}
/// ================== Booking Detail (dành cho màn hình sửa lịch) ==================

class BookingDetail {
  final int id;
  final int shopId;
  final int stylistId;
  final DateTime startDt;
  final DateTime endDt;
  final num totalPrice;
  final String? note;
  final List<BookingServiceItem> services;

  BookingDetail({
    required this.id,
    required this.shopId,
    required this.stylistId,
    required this.startDt,
    required this.endDt,
    required this.totalPrice,
    this.note,
    required this.services,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> j) => BookingDetail(
    id: _asInt(j['id']),
    shopId: _asInt(j['shop_id']),
    stylistId: _asInt(j['stylist_id']),
    startDt: _parseIsoAssumeUtc(j['start_dt'] as String),
    endDt: _parseIsoAssumeUtc(j['end_dt'] as String),
    totalPrice: _asNum(j['total_price']),
    note: j['note'] as String?,
    services: (j['services'] as List? ?? [])
        .map((e) =>
        BookingServiceItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

class BookingServiceItem {
  final int id;
  final int serviceId;
  final num price;
  final int durationMin;
  final String? serviceName;

  BookingServiceItem({
    required this.id,
    required this.serviceId,
    required this.price,
    required this.durationMin,
    this.serviceName,
  });

  factory BookingServiceItem.fromJson(Map<String, dynamic> j) =>
      BookingServiceItem(
        id: _asInt(j['id']),
        serviceId: _asInt(j['service_id']),
        price: _asNum(j['price']),
        durationMin: _asInt(j['duration_min']),
        serviceName: j['service_name'] as String?,
      );
}

