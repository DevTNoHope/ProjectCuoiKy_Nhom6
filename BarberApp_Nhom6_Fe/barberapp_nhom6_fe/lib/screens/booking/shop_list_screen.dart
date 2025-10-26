// lib/screens/booking/shop_list_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/booking_models.dart';
import '../../services/booking_services.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({super.key});
  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final _svc = ShopService();
  late Future<List<Shop>> _f;

  @override
  void initState() {
    super.initState();
    _f = _svc.getShops();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {

            context.go('/home');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                // fallback khi không có gì để pop
                context.go('/home');
              }
            },
          ),
          title: const Text('Chọn cửa hàng'),
        ),
        body: FutureBuilder<List<Shop>>(
          future: _f,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Text('Lỗi tải danh sách: ${snap.error}'),
              );
            }
            final shops = snap.data ?? const <Shop>[];
            if (shops.isEmpty) {
              return const Center(child: Text('Chưa có cửa hàng nào.'));
            }
            return ListView.separated(
              itemCount: shops.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = shops[i];
                return ListTile(
                  title: Text(s.name),
                  subtitle: Text(s.address ?? ''),
                  // DÙNG push để có thể back về ShopList
                  onTap: () => context.push('/shops/${s.id}/stylists'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
