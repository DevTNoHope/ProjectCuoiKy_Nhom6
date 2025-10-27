// lib/screens/booking/my_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/booking_services.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _svc = BookingService(); // dùng service có sẵn của bạn
  late Future<List<Map<String, dynamic>>> _f;

  final _dateFmt = DateFormat('yyyy-MM-dd HH:mm');
  final _moneyFmt =
  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _f = _svc.getMyBookings(); // hàm này của bạn đã có sẵn
  }

  // --- Helpers ---
  num _asNum(dynamic v) {
    if (v is num) return v;
    if (v is String) {
      final s = v.trim().replaceAll(',', '');
      return num.tryParse(s) ?? 0;
    }
    return 0;
  }

  /// Parse ISO; nếu không có timezone thì mặc định coi là UTC
  DateTime _parseIsoAssumeUtc(String s) {
    final dt = DateTime.parse(s);
    if (dt.isUtc) return dt;
    return DateTime.utc(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond,
      dt.microsecond,
    );
  }

  String _fmtLocal(String iso) {
    final local = _parseIsoAssumeUtc(iso).toLocal();
    return _dateFmt.format(local);
  }

  String _fmtLocalShort(String iso) {
    final local = _parseIsoAssumeUtc(iso).toLocal();
    return DateFormat('HH:mm').format(local);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home),
        ),
        title: const Text('Lịch của tôi'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _f,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Lỗi tải lịch: ${snap.error}'),
              ),
            );
          }
          final items = snap.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có lịch đặt nào'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = items[i];

              final startStr = (b['start_dt'] ?? b['start_time']) as String;
              final endStr = (b['end_dt'] ?? b['end_time']) as String;

              // LUÔN hiển thị LOCAL:
              final startText = _fmtLocal(startStr);
              final endText = _fmtLocalShort(endStr);

              final shopId = b['shop_id'];
              final stylistId = b['stylist_id'];
              final status = (b['status'] ?? '').toString();

              final money = _moneyFmt.format(_asNum(b['total_price']));

              return ListTile(
                leading: const Icon(Icons.event_note),
                title: Text('$startText  →  $endText'),
                subtitle: Text('Cửa hàng #$shopId • Thợ #$stylistId • $status'),
                trailing: Text(money, style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/booking/start'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
