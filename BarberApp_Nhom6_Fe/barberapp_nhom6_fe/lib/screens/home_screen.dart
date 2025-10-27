import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final auth = AuthService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Load thông báo khi user mở app để cập nhật badge
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      await _notificationService.getNotifications();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {

    Widget actionButton({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang người dùng'),
        actions: [
          // Nút chuông thông báo với badge cho user
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.unreadCount,
            builder: (context, count, _) {
              return Stack(
                children: [
                  IconButton(
                    tooltip: 'Thông báo',
                    icon: const Icon(Icons.notifications),
                    onPressed: () async {
                      // Load lại thông báo trước khi vào
                      await _loadNotifications();
                      NotificationService.resetUnread();
                      if (context.mounted) {
                        context.go('/notifications');
                      }
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Center(
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            actionButton(
              icon: Icons.event_available,
              label: 'Đặt lịch',
              onTap: () => context.go('/shops'), // bước 1: chọn shop
            ),
            actionButton(
              icon: Icons.schedule,
              label: 'Lịch của tôi',
              onTap: () => context.go('/bookings/me'),
            ),
            actionButton(
              icon: Icons.storefront,
              label: 'Cửa hàng',
              onTap: () => context.go('/shops'),
            ),
            actionButton(
              icon: Icons.person_search,
              label: 'Thợ theo tiệm',
              onTap: () => context.go('/shops'), // mở lại chọn shop rồi thợ
            ),
            actionButton(
              icon: Icons.cut,
              label: 'Dịch vụ',
              onTap: () => context.go('/services'), // nếu bạn có route /services
            ),
            actionButton(
              icon: Icons.help_outline,
              label: 'Hỗ trợ',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Liên hệ: 0123 456 789')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
