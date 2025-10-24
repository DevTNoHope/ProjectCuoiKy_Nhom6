import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final service = ReviewService();
  List<Review> reviews = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _safeRating(int? r) => (r ?? 0).clamp(1, 5);

  Future<void> _load() async {
    try {
      final data = await service.getAll();
      setState(() {
        reviews = data;
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }


  String? _latestReplyText(Review r) {
    DateTime? _toDate(dynamic v) {
      try {
        if (v == null) return null;
        if (v is DateTime) return v;
        if (v is String && v.trim().isNotEmpty) return DateTime.parse(v);
      } catch (_) {}
      return null;
    }

    try {
      final dyn = r as dynamic;
      final reps = dyn.replies;
      if (reps is List && reps.isNotEmpty) {

        reps.sort((a, b) {
          final ad = _toDate((a as dynamic).createdAt ?? (a as dynamic).created_at);
          final bd = _toDate((b as dynamic).createdAt ?? (b as dynamic).created_at);
          final ai = ad?.millisecondsSinceEpoch ?? 0;
          final bi = bd?.millisecondsSinceEpoch ?? 0;
          return bi.compareTo(ai); // desc
        });
        final latest = reps.first;
        final text = (latest as dynamic).reply ?? (latest as dynamic).content;
        final s = text?.toString().trim();
        if (s != null && s.isNotEmpty) return s;
      }
    } catch (_) {

    }


    try {
      final dyn = r as dynamic;
      final s = dyn.reply?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    } catch (_) {}

    return null;
  }

  void _replyDialog(Review r) {
    final replyCtrl = TextEditingController(text: _latestReplyText(r) ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Phản hồi đánh giá #${r.id}"),
        content: TextField(
          controller: replyCtrl,
          decoration: const InputDecoration(
            labelText: "Nội dung phản hồi",
            hintText: "Nhập phản hồi gửi cho khách...",
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await service.reply(r.id, replyCtrl.text.trim(), adminId: 1);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gửi phản hồi')),
                );
                _load();
              } catch (e) {
                if (!mounted) return;
                // Hiển thị lỗi đầy đủ (có cả status/data nếu có)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text("Gửi"),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(int rating) {
    final safe = _safeRating(rating);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
            (i) => Icon(i < safe ? Icons.star : Icons.star_border, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quản lý Đánh giá")),
        body: Center(child: Text(error!)),
      );
    }

    return Scaffold(
      // appBar: AppBar(title: const Text("Quản lý Đánh giá")),
      body: RefreshIndicator(
        onRefresh: _load,
        child: reviews.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text("Chưa có đánh giá")),
          ],
        )
            : ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, i) {
            final r = reviews[i];
            final safeRating = _safeRating(r.rating);
            final latestReply = _latestReplyText(r);

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Row(
                  children: [
                    _buildStars(safeRating),
                    const SizedBox(width: 8),
                    Text("$safeRating/5"),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((r.comment ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(r.comment!.trim()),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      "User ${r.userId ?? '-'}  |  Booking ${r.bookingId ?? '-'}  |  ID #${r.id}",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                    if (latestReply != null && latestReply.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.subdirectory_arrow_right, size: 16),
                            const SizedBox(width: 4),
                            Expanded(child: Text("Phản hồi: $latestReply")),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.reply),
                  onPressed: () => _replyDialog(r),
                  tooltip: "Phản hồi",
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
