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
  Future<List<DateTime>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DateTime>> _load() async {
    final blocks = await _sched.getStylistBlocks(widget.stylist);
    final allSlots = generateSlotsForDate(blocks, _date, stepMin: 15);
    final booked = await _book.getStylistBookings(stylistId: widget.stylist, date: _date);
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

  String _fmtTime(DateTime dt) => TimeOfDay.fromDateTime(dt).format(context);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            // fallback khi trang này là root
            context.go('/home'); // đổi route theo app của bạn
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home'); // fallback
              }
            },
          ),
          title: const Text('Chọn thời gian'),
        ),
        body: Column(
          children: [
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
                      final endLocal =
                      startLocal.add(Duration(minutes: widget.service.durationMin));
                      return ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text('${_fmtTime(startLocal)} → ${_fmtTime(endLocal)}'),
                        subtitle: Text(
                            'Dịch vụ: ${widget.service.name} (${widget.service.durationMin} phút)'),
                        onTap: () {
                          // ĐI TIẾP BẰNG push để có thể back về SlotPick
                          context.push('/booking/confirm', extra: {
                            'shop': widget.shop,
                            'stylist': widget.stylist,
                            'service': widget.service,
                            'start': startLocal, // DateTime local; xử lý ở confirm
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
      ),
    );
  }
}
