import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import 'ReviewsPage.dart';
import 'ServicesPage.dart';
import 'ShopsPage.dart';
import 'StylistsPage.dart';
import 'WorkSchedulesPage.dart';
import 'BookingsPage.dart';
import 'admin_booking_create_page.dart'; // ✅ thêm mới

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
    BookingsPage(), // ✅ Duyệt / Hủy Booking
    ReviewsPage(),
    AdminBookingCreatePage(), // ✅ Đặt lịch cho khách
  ];

  final List<String> _titles = const [
    'Quản lý Chi Nhánh',
    'Quản lý Dịch vụ',
    'Quản lý Stylist',
    'Quản lý Ca làm',
    'Duyệt / Hủy Booking',
    'Đánh giá khách hàng',
    'Đặt lịch cho khách',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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

      // ✅ Drawer thay cho NavigationBar
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Center(
                child: Text(
                  'Bảng điều khiển Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildMenuItem(Icons.store, 'Chi nhánh', 0),
            _buildMenuItem(Icons.cut, 'Dịch vụ', 1),
            _buildMenuItem(Icons.person, 'Stylist', 2),
            _buildMenuItem(Icons.schedule, 'Ca làm', 3),
            _buildMenuItem(Icons.calendar_month, 'Booking', 4),
            _buildMenuItem(Icons.rate_review, 'Đánh giá', 5),
            _buildMenuItem(Icons.add_circle_outline, 'Đặt lịch cho khách', 6),
          ],
        ),
      ),

      body: _pages[_selectedIndex],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.teal : null),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.teal : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context); // đóng Drawer
      },
    );
  }
}
