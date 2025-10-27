import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking_models.dart';   // BookingCreateReq, ServiceModel
import '../../services/booking_services.dart';

class BookingConfirmScreen extends StatefulWidget {
  final int shopId;
  final int stylistId;
  final List<ServiceModel> services;   // danh sách dịch vụ đã chọn
  final DateTime startLocal;           // giờ bắt đầu (Local time)
  final int totalDurationMin;          // tổng phút (đã nhận từ slot)
  final int totalPrice;                // tổng tiền (đã nhận từ slot)

  const BookingConfirmScreen({
    super.key,
    required this.shopId,
    required this.stylistId,
    required this.services,
    required this.startLocal,
    required this.totalDurationMin,
    required this.totalPrice,
  });

  /// Đọc từ state.extra, tương thích với payload bạn truyền từ slot_pick_screen:
  /// {
  ///   'shop': int, 'stylist': int,
  ///   'services': List<ServiceModel>,
  ///   'service': ServiceModel (fallback cũ),
  ///   'start': DateTime,
  ///   'total_duration_min': int,
  ///   'total_price': int
  /// }
  factory BookingConfirmScreen.fromExtra(Map<String, dynamic>? extra) {
    if (extra == null) {
      throw StateError('Missing route extra for /booking/confirm');
    }
    final int shop = (extra['shop'] ?? extra['shopId']) as int;
    final int stylist = (extra['stylist'] ?? extra['stylistId']) as int;

    // start có dạng DateTime (đã truyền từ slot)
    late final DateTime startLocal;
    if (extra['start'] is DateTime) {
      startLocal = extra['start'] as DateTime;
    } else if (extra['start_time'] is String) {
      startLocal = DateTime.parse(extra['start_time'] as String);
    } else {
      throw StateError('Missing "start" in route extra');
    }

    // danh sách dịch vụ
    List<ServiceModel> services;
    if (extra['services'] is List<ServiceModel>) {
      services = (extra['services'] as List<ServiceModel>);
    } else if (extra['services'] is List) {
      services = (extra['services'] as List).cast<ServiceModel>();
    } else if (extra['service'] is ServiceModel) {
      services = [extra['service'] as ServiceModel];
    } else {
      services = const <ServiceModel>[];
    }
    if (services.isEmpty) {
      throw StateError('No service selected');
    }

    // tổng thời lượng & tổng tiền
    final int totalDurationMin =
        (extra['total_duration_min'] as int?) ??
            services.fold<int>(0, (a, b) => a + b.durationMin);

    final int totalPrice =
        (extra['total_price'] as int?) ??
            services.fold<int>(0, (a, b) => a + b.price);

    return BookingConfirmScreen(
      shopId: shop,
      stylistId: stylist,
      services: services,
      startLocal: startLocal,
      totalDurationMin: totalDurationMin,
      totalPrice: totalPrice,
    );
  }

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  final _bookingSvc = BookingService();
  bool _submitting = false;

  late final DateTime _endLocal =
  widget.startLocal.add(Duration(minutes: widget.totalDurationMin));

  // chuyển sang UTC ISO-8601 theo model: startDtUtc / endDtUtc
  DateTime get _startDtUtc => widget.startLocal.toUtc();
  DateTime get _endDtUtc => _endLocal.toUtc();

  String _fmtDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$h:$m • $d/$mo/$y';
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      // BookingCreateReq của bạn yêu cầu:
      // shopId, stylistId, startDtUtc, endDtUtc, services (List<int>), totalPrice
      final items = widget.services
          .map((s) => BookingServiceItemReq(
        serviceId: s.id,
        price: s.price,
        durationMin: s.durationMin,
      ))
          .toList();
      final req = BookingCreateReq(
        shopId: widget.shopId,
        stylistId: widget.stylistId,
        startDtUtc: _startDtUtc,
        endDtUtc: _endDtUtc,
        services: items,
        totalPrice: widget.totalPrice,
      );

      await _bookingSvc.create(req);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt lịch thành công!')),
      );
      context.go('/bookings/me');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt lịch thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startStr = _fmtDateTime(widget.startLocal);
    final endStr = _fmtDateTime(_endLocal);
    final totalMin = widget.totalDurationMin;
    final totalPrice = widget.totalPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đặt lịch'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/booking/slots', extra: {
            'shop': widget.shopId,
            'stylist': widget.stylistId,
            // truyền danh sách dịch vụ thay vì 1 dịch vụ
            'services': widget.services,
            'total_duration_min': totalMin,
            'total_price': totalPrice,
          }),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest, // tránh cảnh báo deprecated
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bắt đầu: $startStr', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Kết thúc: $endStr', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Tổng thời lượng: $totalMin phút'),
                Text('Tổng tiền: $totalPrice đ'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: widget.services.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = widget.services[i];
                return ListTile(
                  leading: const Icon(Icons.design_services_outlined),
                  title: Text(s.name),
                  subtitle: Text('${s.durationMin} phút'),
                  trailing: Text('${s.price} đ'),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(_submitting
                      ? 'Đang gửi...'
                      : 'Xác nhận • ${widget.services.length} DV'),
                  onPressed: _submitting ? null : _confirm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
