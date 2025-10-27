// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = NotificationService();
  final _authService = AuthService();
  late Future<List<NotificationModel>> _notificationsFuture;

  List<NotificationModel> _items = []; // giữ local để update nhanh

  @override
  void initState() {
    super.initState();
    NotificationService.resetUnread();
    _notificationsFuture = _load();
  }

  Future<List<NotificationModel>> _load() async {
    final data = await _service.getNotifications();
    // sắp xếp mới nhất lên đầu
    data.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return data;
    setState(() => _items = data);
    return data;
  }

  Future<void> _refresh() async {
    _notificationsFuture = _load();
    await _notificationsFuture;
  }

  Future<void> _goHome() async {
    final role = await _authService.getRole();
    if (!mounted) return;
    if (role == 'Admin') {
      context.go('/admin');
    } else {
      context.go('/home');
    }
  }

  String _formatDateTime(DateTime dt) =>
      DateFormat('HH:mm dd/MM/yyyy').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Về trang chủ',
            icon: const Icon(Icons.home),
            onPressed: _goHome, // ⬅️ nếu muốn trên AppBar
          ),
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && _items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError && _items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snap.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refresh, child: const Text('Thử lại')),
                ],
              ),
            );
          }

          if (_items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Không có thông báo', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final n = _items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: n.isRead ? 1 : 3,
                  color: n.isRead ? Colors.grey[50] : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      n.isRead ? Icons.notifications : Icons.notifications_active,
                      color: n.isRead ? Colors.grey : Colors.blue,
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.content),
                        const SizedBox(height: 4),
                        Text(_formatDateTime(n.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      // Optimistic update: set read ngay lập tức
                      if (!n.isRead) {
                        setState(() => _items[i] = n.copyWith(isRead: true));
                        final ok = await _service.markAsRead(n.id);
                        if (!ok && mounted) {
                          // revert nếu fail
                          setState(() => _items[i] = n);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đánh dấu đã đọc thất bại')),
                          );
                        }
                      }
                      // Tuỳ nhu cầu, có thể điều hướng qua màn khác
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${n.title}: ${n.content}')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      // Bạn đã có FAB về Home – giữ hoặc bỏ vì đã có nút trên AppBar ở trên
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _goHome,
      //   icon: const Icon(Icons.home),
      //   label: const Text('Về trang chủ'),
      // ),
    );
  }
}
