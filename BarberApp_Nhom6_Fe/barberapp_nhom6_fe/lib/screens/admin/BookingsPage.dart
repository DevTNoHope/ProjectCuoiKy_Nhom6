import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final _service = BookingService();
  late Future<List<Booking>> _futureBookings;
  String _filter = 'all'; // 🔹 Trạng thái đang lọc

  @override
  void initState() {
    super.initState();
    _futureBookings = _service.getAll();
  }

  Future<void> _refresh() async {
    setState(() => _futureBookings = _service.getAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt / Hủy Booking'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('Tất cả')),
              PopupMenuItem(value: 'pending', child: Text('Chờ duyệt')),
              PopupMenuItem(value: 'approved', child: Text('Đã duyệt')),
              PopupMenuItem(value: 'cancelled', child: Text('Đã hủy')),
              PopupMenuItem(value: 'completed', child: Text('Hoàn thành')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Booking>>(
        future: _futureBookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải booking: ${snapshot.error}'));
          }

          var bookings = snapshot.data ?? [];
          if (_filter != 'all') {
            bookings = bookings.where((b) => b.status == _filter).toList();
          }

          if (bookings.isEmpty) {
            return const Center(child: Text('Không có booking nào'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                final color = switch (b.status) {
                  'approved' => Colors.green,
                  'cancelled' => Colors.red,
                  'completed' => Colors.blue,
                  _ => Colors.orange,
                };

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: Icon(Icons.calendar_month, color: color),
                    title: Text(
                      'Booking #${b.id} - ${b.status.toUpperCase()}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Từ: ${b.startDt}\nĐến: ${b.endDt}\nTổng tiền: ${b.totalPrice.toStringAsFixed(0)}đ',
                    ),
                    onTap: () => _showDetailDialog(context, b),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        try {
                          if (value == 'approve') {
                            await _service.approve(b.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ Duyệt booking thành công')),
                            );
                          } else if (value == 'cancel') {
                            await _service.cancel(b.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('❌ Hủy booking thành công')),
                            );
                          } else if (value == 'complete') {
                            await _service.complete(b.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🎉 Đã đánh dấu hoàn thành')),
                            );
                          } else if (value == 'delete') {
                            await _service.delete(b.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🗑 Xóa booking thành công')),
                            );
                          }
                          _refresh();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('⚠️ Lỗi khi xử lý: $e')),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        if (b.status == 'pending')
                          const PopupMenuItem(
                            value: 'approve',
                            child: Text('✅ Duyệt'),
                          ),
                        if (b.status == 'approved')
                          const PopupMenuItem(
                            value: 'complete',
                            child: Text('🎉 Hoàn thành'),
                          ),
                        if (b.status != 'cancelled')
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Text('❌ Hủy'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('🗑 Xóa'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // 📄 Hiển thị chi tiết booking trong popup
  void _showDetailDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chi tiết Booking #${booking.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (booking.userName != null)
              Text('👤 Khách hàng: ${booking.userName}'),
            if (booking.userPhone != null)
              Text('📞 SĐT: ${booking.userPhone}'),
            if (booking.shopName != null)
              Text('🏠 Cửa hàng: ${booking.shopName}'),
            if (booking.stylistName != null)
              Text('✂️ Thợ: ${booking.stylistName}'),
            const SizedBox(height: 8),
            Text('🕒 Bắt đầu: ${booking.startDt}'),
            Text('🕒 Kết thúc: ${booking.endDt}'),
            const SizedBox(height: 8),
            Text('💰 Tổng tiền: ${booking.totalPrice.toStringAsFixed(0)}đ'),
            if (booking.note != null && booking.note!.isNotEmpty)
              Text('📝 Ghi chú: ${booking.note}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
