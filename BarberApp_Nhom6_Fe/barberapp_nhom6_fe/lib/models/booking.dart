class Booking {
  final int id;
  final int userId;
  final int shopId;
  final int? stylistId;
  final String? shopName;
  final String? stylistName;
  final String? userPhone;
  final String? userName; // 👈 thêm
  final String status;
  final DateTime startDt;
  final DateTime endDt;
  final double totalPrice;
  final String? note;

  Booking({
    required this.id,
    required this.userId,
    required this.shopId,
    this.stylistId,
    this.shopName,
    this.stylistName,
    this.userPhone,
    this.userName, // 👈 thêm
    required this.status,
    required this.startDt,
    required this.endDt,
    required this.totalPrice,
    this.note,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Booking(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      shopId: parseInt(json['shop_id']),
      stylistId: json['stylist_id'] == null ? null : parseInt(json['stylist_id']),
      shopName: json['shop_name'],
      stylistName: json['stylist_name'],
      userPhone: json['user_phone'],
      userName: json['user_name'], // 👈 thêm
      status: json['status'] ?? 'pending',
      startDt: DateTime.parse(json['start_dt']),
      endDt: DateTime.parse(json['end_dt']),
      totalPrice: parsePrice(json['total_price']),
      note: json['note'],
    );
  }
}
