// lib/screens/booking/slot_pick_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/booking_services.dart';
import '../../models/booking_models.dart';
import '../../utils/slot_utils.dart';

class SlotPickScreen extends StatefulWidget {
  final int shop;
  final int stylist;
  final ServiceModel service;

  const SlotPickScreen({
    super.key,
    required this.shop,
    required this.stylist,
    required this.service,
  });

  @override
  State<SlotPickScreen> createState() => _SlotPickScreenState();
}

class _SlotPickScreenState extends State<SlotPickScreen> {
  final _sched = ScheduleService();
  final _book = BookingService();

  DateTime _date = DateTime.now();
  Future<List<DateTime>>? _future; // cache để tránh gọi lại liên tục

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DateTime>> _load() async {
    // 1) lấy block làm việc time-of-day của stylist
    final blocks = await _sched.getStylistBlocks(widget.stylist);

    // 2) tạo tất cả slot cho NGÀY đang chọn (dựa theo time-of-day)
    final allSlots = generateSlotsForDate(blocks, _date, stepMin: 15);

    // 3) lấy danh sách booking đã có trong ngày (UTC/ISO từ server)
    final booked =
    await _book.getStylistBookings(stylistId: widget.stylist, date: _date);

    // 4) lọc slot không đủ thời lượng hoặc bị chồng lên booking đã có
    final available = filterAvailableSlots(
      slots: allSlots,
      bookings: booked,
      serviceDurationMin: widget.service.durationMin,
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
    final t = TimeOfDay.fromDateTime(dt);
    return t.format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Chọn thời gian'),
      ),
      body: Column(
        children: [
          // thanh đổi ngày
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => _changeDate(-1),
                  child: const Text('← Hôm trước'),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _date.toLocal().toString().substring(0, 10),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                    final endLocal = startLocal.add(
                      Duration(minutes: widget.service.durationMin),
                    );
                    return ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text('${_fmtTime(startLocal)} → ${_fmtTime(endLocal)}'),
                      subtitle: Text(
                          'Dịch vụ: ${widget.service.name} (${widget.service.durationMin} phút)'),
                      onTap: () {
                        // gửi start UTC sang màn xác nhận
                        context.push('/booking/confirm', extra: {
                          'shop': widget.shop,
                          'stylist': widget.stylist,
                          'service': widget.service.toJson(), // serialize service
                          'start': startLocal,
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
