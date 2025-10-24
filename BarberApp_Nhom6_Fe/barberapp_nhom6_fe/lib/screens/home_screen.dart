import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

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

            // 🆕 ⭐ Thêm nút "Đánh giá của tôi"
            actionButton(
              icon: Icons.reviews,
              label: 'Đánh giá của tôi',
              onTap: () => context.go('/review/my'),
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
