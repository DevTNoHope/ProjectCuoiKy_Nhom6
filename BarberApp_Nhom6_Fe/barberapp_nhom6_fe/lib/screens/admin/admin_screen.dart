import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'ReviewsPage.dart';
import 'ServicesPage.dart';
import 'ShopsPage.dart';
import 'StylistsPage.dart';
import 'WorkSchedulesPage.dart';
import 'BookingsPage.dart'; // ✅ thêm mới

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final auth = AuthService();
  int _selectedIndex = 0;
  final NotificationService _notificationService = NotificationService();

  final List<Widget> _pages = const [
    ShopsPage(),
    ServicesPage(),
    StylistsPage(),
    WorkSchedulesPage(),
    BookingsPage(), // ✅ thêm mới
    ReviewsPage(),
  ];

  final List<String> _titles = const [
    'Quản lý Chi Nhánh',
    'Quản lý Dịch vụ',
    'Quản lý Stylist',
    'Quản lý Ca làm',
    'Duyệt / Hủy Booking',
    'Đánh giá khách hàng',
  ];

  @override
  void initState() {
    super.initState();
    // Load thông báo khi admin mở app để cập nhật badge
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
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
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.store), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.cut), label: 'Service'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Stylist'),
          NavigationDestination(icon: Icon(Icons.schedule), label: 'Ca làm'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Booking',
          ), // ✅ thêm
          NavigationDestination(
            icon: Icon(Icons.rate_review),
            label: 'Đánh giá',
          ),
        ],
      ),
    );
  }
}
