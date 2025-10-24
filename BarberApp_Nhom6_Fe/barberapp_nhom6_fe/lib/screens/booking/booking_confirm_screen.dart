// lib/screens/booking/booking_confirm_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/booking_models.dart';
import '../../services/booking_services.dart';

class BookingConfirmScreen extends StatefulWidget {
  final int shop;
  final int stylist;
  final ServiceModel service;
  /// start: thời điểm user chọn ở màn SlotPick.
  /// Ở SlotPick bạn nên truyền start là LOCAL hoặc UTC đều được,
  /// dưới đây mình chuẩn hoá: nếu chưa là UTC thì mới toUtc().
  final DateTime start;

  const BookingConfirmScreen({
    super.key,
    required this.shop,
    required this.stylist,
    required this.service,
    required this.start,
  });

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  final _noteCtl = TextEditingController();
  final _fmtDateTime = DateFormat('yyyy-MM-dd HH:mm');
  bool _loading = false;

  // Dùng service chung của dự án bạn
  final _svc = BookingService();

  @override
  void dispose() {
    _noteCtl.dispose();
    super.dispose();
  }

  String _fmtLocal(DateTime dt) => _fmtDateTime.format(dt.toLocal());

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      // 1) Chuẩn hoá thời gian:
      //    - Hiển thị: LOCAL
      //    - Gửi BE: UTC ISO
      final startLocal = widget.start.toLocal();
      final startUtc = widget.start.isUtc ? widget.start : widget.start.toUtc();

      final durationMin = widget.service.durationMin;
      final endLocal = startLocal.add(Duration(minutes: durationMin));
      final endUtc = startUtc.add(Duration(minutes: durationMin));

      // 2) Lấy giá từ ServiceModel (đã parse an toàn ở booking_models.dart)
      final price = widget.service.price;

      // (Debug) Cảnh báo nếu giá bằng 0 để bạn biết ngay từ UI
      if (price == 0) {
        // Không chặn gửi, chỉ cảnh báo. Nếu muốn chặn, return sau khi show SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Giá dịch vụ đang = 0. Kiểm tra ServiceModel.price!'),
          ),
        );
      }

      // 3) Tạo payload đúng schema BE
      final req = BookingCreateReq(
        shopId: widget.shop,
        stylistId: widget.stylist,
        startDtUtc: startUtc,
        endDtUtc: endUtc,
        totalPrice: price,
        note: _noteCtl.text.trim().isEmpty ? null : _noteCtl.text.trim(),
        services: [
          BookingServiceItemReq(
            serviceId: widget.service.id,
            price: price,
            durationMin: durationMin,
          ),
        ],
      );

      // 4) Gọi API
      await _svc.create(req);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt lịch thành công!')),
      );
      context.go('/bookings/me');
    } on DioException catch (e) {
      final d = e.response?.data;
      final msg =
      (d is Map && d['detail'] != null) ? d['detail'].toString() : e.toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startLocal = widget.start.toLocal();
    final durationMin = widget.service.durationMin;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Xác nhận đặt lịch'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dịch vụ: ${widget.service.name} ($durationMin phút)'),
            const SizedBox(height: 6),
            Text('Bắt đầu: ${_fmtLocal(startLocal)}'),
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tuỳ chọn)',
                border: UnderlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Xác nhận'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
