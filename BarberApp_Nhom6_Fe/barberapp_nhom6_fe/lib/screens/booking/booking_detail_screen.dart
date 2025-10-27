// lib/screens/booking/booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../models/booking_detail.dart';
import '../../models/review.dart';
import '../../services/booking_services.dart';
import '../../services/review_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _bookingSvc = BookingService();
  final _reviewSvc = ReviewService();

  late Future<BookingDetail> _future;
  Review? _review; // review hiện có (nếu có)

  @override
  void initState() {
    super.initState();
    _future = _bookingSvc.getDetail(widget.bookingId);
    // Sau khi có chi tiết booking, load review (nếu có)
    _future.then((_) => _loadReview());
  }

  Future<void> _loadReview() async {
    try {
      final r = await _reviewSvc.getByBookingId(widget.bookingId);
      if (!mounted) return;
      setState(() => _review = r);
    } catch (_) {
      // Có thể 404 (chưa có review) -> bỏ qua
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _bookingSvc.getDetail(widget.bookingId);
    });
    await _future;
    await _loadReview();
  }

  // --------- Helpers ----------
  String _fmtDate(DateTime dt) => DateFormat('dd/MM/yyyy HH:mm').format(dt);
  String _fmtMoney(num v) => NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(v);

  bool _canCancel(BookingDetail b) {
    // Chỉ cho hủy khi pending/approved VÀ chưa tới giờ bắt đầu
    final now = DateTime.now();
    final startLocal = b.startDt.toLocal();
    final notStartedYet = startLocal.isAfter(now);
    return (b.status == 'pending' || b.status == 'approved') && notStartedYet;
  }

  bool _canReview(BookingDetail b) => b.status == 'completed';

  // --------- Actions ----------
  Future<void> _cancel(BookingDetail b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy lịch hẹn'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hủy lịch')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _bookingSvc.cancel(b.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy booking.')));
      await _reload();
    } on DioException catch (e) {
      final detail = (e.response?.data is Map && e.response?.data['detail'] != null)
          ? e.response!.data['detail'].toString()
          : e.message ?? 'Có lỗi xảy ra';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hủy thất bại: $detail')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hủy thất bại: $e')));
    }
  }

  Future<void> _openReviewSheet(BookingDetail b) async {
    // BE của bạn yêu cầu user_id khi tạo review.
    // FE có thể lấy luôn từ booking detail (b.userId là chủ booking).
    final userId = b.userId;

    final initRating = _review?.rating ?? 5;
    final initComment = _review?.comment ?? '';

    final result = await showModalBottomSheet<_ReviewData>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(initialRating: initRating, initialComment: initComment),
    );
    if (result == null) return;

    try {
      await _reviewSvc.upsertForBooking(
        bookingId: b.id,
        userId: userId,
        rating: result.rating,
        comment: result.comment,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi đánh giá.')));
      await _loadReview();
    } on DioException catch (e) {
      final detail = (e.response?.data is Map && e.response?.data['detail'] != null)
          ? e.response!.data['detail'].toString()
          : e.message ?? 'Có lỗi xảy ra';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đánh giá thất bại: $detail')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đánh giá thất bại: $e')));
    }
  }

  // --------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Chi tiết booking'),
      ),
      body: FutureBuilder<BookingDetail>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }
          final b = snap.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InfoRow(label: 'Trạng thái', value: b.status.toUpperCase()),
                const SizedBox(height: 8),
                _InfoRow(label: 'Cửa hàng', value: b.shopName ?? '—'),
                _InfoRow(label: 'Thợ', value: b.stylistName ?? '—'),
                _InfoRow(label: 'Bắt đầu', value: _fmtDate(b.startDt)),
                _InfoRow(label: 'Kết thúc', value: _fmtDate(b.endDt)),
                const SizedBox(height: 16),

                const Text('Dịch vụ', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (b.services.isEmpty)
                  const Text('Không có dịch vụ', style: TextStyle(color: Colors.grey))
                else
                  ...b.services.map((s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(s.serviceName ?? 'Dịch vụ #${s.serviceId}'),
                    subtitle: Text('Thời lượng: ${s.durationMin} phút'),
                    trailing: Text(_fmtMoney(s.price)),
                  )),
                const Divider(height: 28),

                _InfoRow(label: 'Tổng tiền', value: _fmtMoney(b.totalPrice)),
                if ((b.note ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(b.note!),
                ],

                const SizedBox(height: 24),
                if (_review != null) ...[
                  const Text('Đánh giá của bạn', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      return Icon(idx <= _review!.rating ? Icons.star : Icons.star_border);
                    }),
                  ),
                  if ((_review!.comment ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_review!.comment!),
                    ),

                  // ====== HIỂN THỊ PHẢN HỒI TỪ ADMIN ======
                  const SizedBox(height: 16),
                  const Divider(height: 24),
                  const Text('Phản hồi từ Admin', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if ((_review!.replies).isEmpty)
                    const Text('Chưa có phản hồi', style: TextStyle(color: Colors.grey))
                  else
                    ..._review!.replies.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black12.withOpacity(0.04),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tiêu đề: Admin #id + thời gian
                                Row(
                                  children: [
                                    Text('Admin #${r.adminId}',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    Text(_fmtDate(r.createdAt),
                                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(r.reply),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  const SizedBox(height: 12),
                ],

                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _canCancel(b) ? () => _cancel(b) : null,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Hủy booking'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _canReview(b) ? () => _openReviewSheet(b) : null,
                        icon: const Icon(Icons.star_rate),
                        label: Text(_review == null ? 'Đánh giá' : 'Sửa đánh giá'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }
}

// ==== Bottom sheet đánh giá ====
class _ReviewData {
  final int rating;
  final String? comment;
  _ReviewData(this.rating, this.comment);
}

class _ReviewSheet extends StatefulWidget {
  final int initialRating;
  final String initialComment;
  const _ReviewSheet({required this.initialRating, required this.initialComment});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _rating;
  late TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _c = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Đánh giá dịch vụ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final idx = i + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = idx),
                icon: Icon(idx <= _rating ? Icons.star : Icons.star_border),
                iconSize: 32,
              );
            }),
          ),
          TextField(
            controller: _c,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Nhận xét (tuỳ chọn)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final comment = _c.text.trim();
                    Navigator.pop(context, _ReviewData(_rating, comment.isEmpty ? null : comment));
                  },
                  child: const Text('Gửi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
