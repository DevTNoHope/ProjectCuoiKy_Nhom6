// lib/screens/booking/service_pick_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/booking_services.dart';
import '../../models/booking_models.dart';

class ServicePickScreen extends StatefulWidget {
  final int shopId, stylistId;
  const ServicePickScreen({super.key, required this.shopId, required this.stylistId});
  @override
  State<ServicePickScreen> createState() => _ServicePickScreenState();
}

class _ServicePickScreenState extends State<ServicePickScreen> {
  final _svc = ServiceService();
  late Future<List<ServiceModel>> _future;

  // Các dịch vụ đã chọn (lưu id)
  final Set<int> _selectedIds = <int>{};

  @override
  void initState() {
    super.initState();
    _future = _svc.getServices(shopId: widget.shopId);
  }

  void _toggle(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clear() => setState(() => _selectedIds.clear());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/shops/${widget.shopId}/stylists'),
        ),
        title: const Text('Chọn dịch vụ'),
        actions: [
          IconButton(
            tooltip: 'Bỏ chọn',
            icon: const Icon(Icons.clear_all),
            onPressed: _selectedIds.isEmpty ? null : _clear,
          )
        ],
      ),
      body: FutureBuilder<List<ServiceModel>>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return const Center(child: Text('Lỗi tải dịch vụ'));
          final list = snap.data ?? <ServiceModel>[];

          // Tính tổng theo lựa chọn
          int totalMin = 0;
          int totalPrice = 0;
          final selected = <ServiceModel>[];
          for (final sv in list) {
            if (_selectedIds.contains(sv.id)) {
              selected.add(sv);
              totalMin += sv.durationMin;
              totalPrice += sv.price;
            }
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final sv = list[i];
                    final checked = _selectedIds.contains(sv.id);
                    return ListTile(
                      onTap: () => _toggle(sv.id),
                      title: Text(sv.name),
                      subtitle: Text('${sv.durationMin} phút • ${sv.price} đ'),
                      trailing: Checkbox(
                        value: checked,
                        onChanged: (_) => _toggle(sv.id),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        selected.isEmpty
                            ? 'Chọn ít nhất 1 dịch vụ'
                            : 'Tiếp tục • ${selected.length} DV • ${totalMin} phút',
                      ),
                      onPressed: selected.isEmpty
                          ? null
                          : () {
                        context.go('/booking/slots', extra: {
                          'shop': widget.shopId,
                          'stylist': widget.stylistId,
                          // truyền danh sách dịch vụ thay vì 1 dịch vụ
                          'services': selected,
                          'total_duration_min': totalMin,
                          'total_price': totalPrice,
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
