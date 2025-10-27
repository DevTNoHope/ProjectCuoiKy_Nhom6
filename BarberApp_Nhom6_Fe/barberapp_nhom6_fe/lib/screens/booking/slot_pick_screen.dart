// lib/screens/booking/slot_pick_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/booking_services.dart';
import '../../models/booking_models.dart';
import '../../utils/slot_utils.dart';

class SlotPickScreen extends StatefulWidget {
  final int shop;
  final int stylist;

  /// Giữ tham số cũ để tương thích khi chỉ chọn 1 dịch vụ
  final ServiceModel service;

  /// Tham số mới: danh sách dịch vụ đã chọn
  final List<ServiceModel>? services;

  const SlotPickScreen({
    super.key,
    required this.shop,
    required this.stylist,
    required this.service,
    this.services,
  });

  @override
  State<SlotPickScreen> createState() => _SlotPickScreenState();
}

class _SlotPickScreenState extends State<SlotPickScreen> {
  final _sched = ScheduleService();
  final _book = BookingService();

  late final List<ServiceModel> _services;       // danh sách dịch vụ chọn
  late final int _totalDurationMin;              // tổng phút dịch vụ
  late final int _totalPrice;                    // tổng giá (nếu cần hiển thị)

  DateTime _date = DateTime.now();
  late Future<List<DateTime>> _future;

  @override
  void initState() {
    super.initState();
    // chuẩn hoá danh sách dịch vụ: ưu tiên list mới, nếu không có dùng service cũ
    _services = (widget.services != null && widget.services!.isNotEmpty)
        ? List<ServiceModel>.from(widget.services!)
        : <ServiceModel>[widget.service];

    _totalDurationMin =
        _services.fold<int>(0, (sum, s) => sum + s.durationMin);
    _totalPrice = _services.fold<int>(0, (sum, s) => sum + s.price);

    _future = _load();
  }

  Future<List<DateTime>> _load() async {
    // 1) Lấy các block làm việc (theo time-of-day) của stylist
    final blocks = await _sched.getStylistBlocks(widget.stylist);

    // 2) Tạo tất cả slot cho NGÀY đang chọn
    final allSlots = generateSlotsForDate(blocks, _date, stepMin: 15);

    // 3) Lấy danh sách booking đã có trong ngày
    final booked = await _book.getStylistBookings(
      stylistId: widget.stylist,
      date: _date,
    );

    // 4) Lọc theo tổng thời lượng tất cả dịch vụ đã chọn
    final available = filterAvailableSlots(
      slots: allSlots,
      bookings: booked,
      serviceDurationMin: _totalDurationMin,
    );

    return available;
  }

  void _changeDate(int deltaDays) {
    setState(() {
      _date = _date.add(Duration(days: deltaDays));
      _future = _load();
    });
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final serviceSummary = '${_services.length} DV • $_totalDurationMin phút • $_totalPrice đ';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn thời gian'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/stylists/${widget.stylist}/services?shopId=${widget.shop}'),
        ),
      ),
      body: Column(
        children: [
          // Header hiển thị ngày và tổng dịch vụ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _date.toLocal().toString().substring(0, 10),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(serviceSummary, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: -6,
                        children: _services.map((s) => Chip(label: Text(s.name))).toList(),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _changeDate(1),
                  child: const Text('Hôm sau →'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Danh sách slot khả dụng
          Expanded(
            child: FutureBuilder<List<DateTime>>(
              future: _future,
              builder: (context, snap) {
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

                final slots = snap.data ?? const <DateTime>[];
                if (slots.isEmpty) {
                  return const Center(child: Text('Không còn khung giờ trống'));
                }

                return ListView.separated(
                  itemCount: slots.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final startLocal = slots[i];
                    final endLocal = startLocal.add(Duration(minutes: _totalDurationMin));

                    return ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text('${_fmtTime(startLocal)} → ${_fmtTime(endLocal)}'),
                      subtitle: Text(
                        _services.length == 1
                            ? 'Dịch vụ: ${_services.first.name} (${_totalDurationMin} phút)'
                            : 'Tổng ${_services.length} dịch vụ • $_totalDurationMin phút',
                      ),
                      onTap: () {
                        // gửi start (Local) sang màn xác nhận
                        // Truyền cả 'services' (mới) và 'service' (cũ) để tương thích
                        context.go('/booking/confirm', extra: {
                          'shop': widget.shop,
                          'stylist': widget.stylist,
                          'services': _services,
                          'service': _services.first,
                          'start': startLocal,
                          'total_duration_min': _totalDurationMin,
                          'total_price': _totalPrice,
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
