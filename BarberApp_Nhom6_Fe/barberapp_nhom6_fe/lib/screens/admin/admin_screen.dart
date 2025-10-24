import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
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
