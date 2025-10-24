import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import 'review_form_screen.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final _svc = ReviewService();
  late Future<List<Review>> _f;
  bool _reloading = false; // hiển thị loading mỏng khi vừa sửa xong và đang tải lại

  @override
  void initState() {
    super.initState();
    _f = _svc.getMyReviews();
  }

  Future<void> _refresh() async {
    setState(() => _reloading = true);
    final future = _svc.getMyReviews();
    setState(() => _f = future);
    // đợi future hoàn tất để chắc chắn dữ liệu mới đã về
    await future;
    if (mounted) setState(() => _reloading = false);
  }

  Future<void> _delete(int id) async {
    await _svc.deleteMyReview(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã xóa review")),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá của tôi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home'); // Exit an toàn nếu không có màn trước
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Thoát về Trang người dùng',
            onPressed: () => context.go('/home'),
          ),
        ],
        bottom: _reloading
            ? const PreferredSize(
          preferredSize: Size.fromHeight(3),
          child: LinearProgressIndicator(minHeight: 3),
        )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Review>>(
          future: _f,
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text("Lỗi tải dữ liệu: ${snap.error}"));
            }

            final list = snap.data ?? <Review>[];
            if (list.isEmpty) {
              return const Center(child: Text("Chưa có đánh giá nào"));
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final r = list[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text("⭐ ${r.rating}/5"),
                    subtitle: Text(r.comment ?? "Không có nhận xét"),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          // Chờ form đóng lại, nếu saved -> reload ngay
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewFormScreen(review: r),
                            ),
                          );
                          if (!mounted) return;
                          if (result == true || result is Review) {
                            await _refresh();
                          }
                        } else if (v == 'delete') {
                          await _delete(r.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Sửa')),
                        PopupMenuItem(value: 'delete', child: Text('Xóa')),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
