import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';

class ReviewFormScreen extends StatefulWidget {
  final Review? review;
  final int? bookingId;

  const ReviewFormScreen({super.key, this.review, this.bookingId});

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _svc = ReviewService();
  final _commentCtrl = TextEditingController();
  double _rating = 5;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.review != null) {
      _rating = widget.review!.rating.toDouble();
      _commentCtrl.text = widget.review!.comment ?? '';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      if (widget.review == null && widget.bookingId != null) {
        // ✅ Không gửi user_id = 0 (đã xử lý trong ReviewService)
        await _svc.createReview({
          "booking_id": widget.bookingId,
          "rating": _rating.toInt(),
          "comment": _commentCtrl.text.trim(),
        });
      } else if (widget.review != null) {
        await _svc.updateMyReview(widget.review!.id, {
          "rating": _rating.toInt(),
          "comment": _commentCtrl.text.trim(),
        });
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã lưu đánh giá thành công!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Lỗi lưu review: $e")));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text(widget.review == null ? 'Thêm đánh giá' : 'Sửa đánh giá'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Thoát',
            onPressed: () {
              // 🔹 Thoát hẳn về màn chính
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('⭐ Đánh giá sao'),
            Slider(
              value: _rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: _rating.toString(),
              onChanged: (v) => setState(() => _rating = v),
            ),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nhận xét của bạn',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Đang lưu...' : 'Lưu'),
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                backgroundColor: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
