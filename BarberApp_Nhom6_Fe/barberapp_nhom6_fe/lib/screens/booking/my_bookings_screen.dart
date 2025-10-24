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
  final _svc = BookingService(); // service gọi API
  late Future<List<Map<String, dynamic>>> _f;

  final _dateFmt = DateFormat('yyyy-MM-dd HH:mm');
  final _moneyFmt =
  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _f = _svc.getMyBookings(); // load danh sách booking
  }

  num _asNum(dynamic v) {
    if (v is num) return v;
    if (v is String) {
      final s = v.trim().replaceAll(',', '');
      return num.tryParse(s) ?? 0;
    }
    return 0;
  }

  /// Parse ISO string -> UTC
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

  // ✅ Hàm xác nhận xóa booking
  Future<void> _confirmDelete(int bookingId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hủy lịch đặt"),
        content: const Text("Bạn có chắc muốn hủy lịch này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _svc.deleteMyBooking(bookingId);
                setState(() {
                  _f = _svc.getMyBookings(); // load lại danh sách sau khi xóa
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã hủy lịch thành công")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi khi xóa: $e")),
                );
              }
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch của tôi'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Thoát về trang người dùng',
          onPressed: () {
            // ✅ Sử dụng GoRouter để điều hướng chính xác
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home'); // hoặc route trang chính của bạn
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Thoát hẳn về Trang chủ',
            onPressed: () {
              context.go('/home'); // ✅ đảm bảo thoát được kể cả khi stack rỗng
            },
          ),
        ],
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
              final startStr = (b['start_dt'] ?? b['start_time'])?.toString() ?? '';
              final endStr = (b['end_dt'] ?? b['end_time'])?.toString() ?? '';


              final startText = _fmtLocal(startStr);
              final endText = _fmtLocalShort(endStr);

              final shopId = b['shop_id'];
              final stylistId = b['stylist_id'];
              final status = (b['status'] ?? '').toString();
              final money = _moneyFmt.format(_asNum(b['total_price']));

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text('$startText → $endText'),
                  subtitle: Text(
                    'Cửa hàng #$shopId • Thợ #$stylistId\nTrạng thái: $status',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push('/booking/edit', extra: b);
                      } else if (value == 'delete') {
                        _confirmDelete(b['id']);
                      } else if (value == 'review') {
                        context.push('/review/add', extra: b);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Sửa lịch đặt'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hủy lịch đặt'),
                      ),
                      if (status == 'completed')
                        const PopupMenuItem(
                          value: 'review',
                          child: Text('Đánh giá'),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                ),
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
