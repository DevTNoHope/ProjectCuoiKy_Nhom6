num _toNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  if (v is String) {
    final s = v.trim().replaceAll(',', '');
    return num.tryParse(s) ?? 0;
  }
  return 0;
}

int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

int _toInt(dynamic v) => _toIntOrNull(v) ?? 0;

class BookingServiceDetail {
  final int serviceId;
  final String? serviceName;
  final num price;
  final int durationMin;

  BookingServiceDetail({
    required this.serviceId,
    this.serviceName,
    required this.price,
    required this.durationMin,
  });

  factory BookingServiceDetail.fromJson(Map<String, dynamic> j) => BookingServiceDetail(
    serviceId: _toInt(j['service_id']),
    serviceName: j['service_name'] as String?,
    price: _toNum(j['price']),
    durationMin: _toInt(j['duration_min']),
  );
}

class BookingDetail {
  final int id;
  final int userId;
  final int? shopId;
  final int? stylistId;
  final String status; // pending|approved|completed|cancelled...
  final DateTime startDt;
  final DateTime endDt;
  final num totalPrice;
  final String? note;
  final DateTime createdAt;
  final String? shopName;
  final String? stylistName;
  final List<BookingServiceDetail> services;

  BookingDetail({
    required this.id,
    required this.userId,
    this.shopId,
    this.stylistId,
    required this.status,
    required this.startDt,
    required this.endDt,
    required this.totalPrice,
    this.note,
    required this.createdAt,
    this.shopName,
    this.stylistName,
    required this.services,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> j) => BookingDetail(
    id: _toInt(j['id']),
    userId: _toInt(j['user_id']),
    shopId: _toIntOrNull(j['shop_id']),
    stylistId: _toIntOrNull(j['stylist_id']),
    status: (j['status'] ?? '').toString(),
    startDt: DateTime.parse(j['start_dt'] as String),
    endDt: DateTime.parse(j['end_dt'] as String),
    totalPrice: _toNum(j['total_price']),
    note: j['note'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    shopName: j['shop_name'] as String?,
    stylistName: j['stylist_name'] as String?,
    services: (j['services'] as List? ?? const [])
        .map((x) => BookingServiceDetail.fromJson(Map<String, dynamic>.from(x as Map)))
        .toList(),
  );
}
