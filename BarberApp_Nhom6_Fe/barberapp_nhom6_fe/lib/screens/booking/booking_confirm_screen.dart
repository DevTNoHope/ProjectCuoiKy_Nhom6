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
  String? _shopName;
  String? _shopAddress;
  @override
  void dispose() {
    _noteCtl.dispose();
    super.dispose();
  }

  String _fmtLocal(DateTime dt) => _fmtDateTime.format(dt.toLocal());

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      // 1) Chuẩn hoá thời gian
      final startUtc = widget.start.isUtc ? widget.start : widget.start.toUtc();
      final durationMin = widget.service.durationMin;
      final endUtc = startUtc.add(Duration(minutes: durationMin));
      final price = widget.service.price;

      // (Tuỳ chọn) cảnh báo nếu giá = 0
      if (price == 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Giá dịch vụ đang = 0. Kiểm tra ServiceModel.price!')),
        );
      }

      // 2) Tạo payload đúng schema BE
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

      // 3) Loader "Đang xử lý..."
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ProcessingDialog(),
      );

      // 4) Gọi API tạo booking (service KHÔNG điều hướng)
      await _svc.create(req);

      // 5) Tắt loader
      if (!mounted) return;
      Navigator.pop(context);

      // 6) Lấy thông tin shop để hiển thị (nếu bạn có service thật thì thay vào)
      if (_shopName == null) {
        // TODO: thay bằng ShopService().getById(widget.shop) nếu có
        _shopName = 'Cửa hàng #${widget.shop}';
        _shopAddress = '';
      }

      final shopTitle = _shopName ?? 'Cửa hàng #${widget.shop}';
      final shopAddr  = _shopAddress ?? '';
      final startUi   = startUtc.toLocal();

      // 7) Dialog "Đặt lịch thành công"
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, size: 48, color: Colors.green),
          title: const Text('Đặt lịch thành công!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.service.name} (${widget.service.durationMin} phút)'),
              const SizedBox(height: 6),
              Text(
                DateFormat('HH:mm dd/MM/yyyy').format(startUi),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(shopTitle),
              if (shopAddr.isNotEmpty) Text(shopAddr),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);      // đóng dialog
                if (!mounted) return;
                // Quay về màn hình trước đó (Lịch của tôi)
                Navigator.of(context).popUntil((route) => route.isFirst);
                context.pushReplacement('/bookings/me');  // sang "Lịch của tôi"
              },
              child: const Text('Xem lịch hẹn'),
            ),
          ],
        ),
      );

      // 8) DỪNG Ở ĐÂY để KHÔNG chạy bất kỳ điều hướng cũ nào phía dưới
      return;

    } on DioException catch (e) {
      final d = e.response?.data;
      final msg = (d is Map && d['detail'] != null) ? d['detail'].toString() : e.toString();
      if (!mounted) return;
      // đóng mọi popup nếu còn mở
      Navigator.popUntil(context, (route) => route is! PopupRoute);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route is! PopupRoute);
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

/// ====== WIDGET HIỂN THỊ "ĐẶT LỊCH THÀNH CÔNG" NGAY TRONG TRANG ======
class _BookingSuccessSheet extends StatelessWidget {
  final String serviceName;
  final int durationMin;
  final DateTime startDtUtc;
  final int shopId;
  final String? shopName;
  final String? shopAddress;

  const _BookingSuccessSheet({
    required this.serviceName,
    required this.durationMin,
    required this.startDtUtc,
    required this.shopId,
    this.shopName,
    this.shopAddress,
  });

  String _fmt(DateTime utc) => DateFormat('HH:mm dd/MM/yyyy').format(utc.toLocal());

  @override
  Widget build(BuildContext context) {
    final title = shopName?.isNotEmpty == true ? shopName! : 'Cửa hàng #$shopId';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Đặt lịch thành công!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('$serviceName ($durationMin phút)'),
            const SizedBox(height: 6),
            Text(
              _fmt(startDtUtc),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center),
            if ((shopAddress ?? '').isNotEmpty)
              Text(shopAddress!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context), // Đóng sheet, ở lại trang
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context); // đóng bottom sheet
                      // chuyển về trang home (root)
                      context.go('/home'); // hoặc context.go('/home') tùy route bạn đang dùng
                    },
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class _ProcessingDialog extends StatelessWidget {
  const _ProcessingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Đang xử lý', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}