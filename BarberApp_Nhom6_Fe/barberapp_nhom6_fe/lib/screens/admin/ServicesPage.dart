import 'package:flutter/material.dart';

import '../../models/service.dart';
import '../../services/service_service.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final ServiceService _service = ServiceService();
  List<Service> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAll();
      setState(() {
        _services = data;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🟢 Dialog thêm dịch vụ
  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thêm dịch vụ"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Tên dịch vụ")),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Mô tả")),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: "Giá (VNĐ)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              try {
                await _service.create(nameCtrl.text, descCtrl.text, double.parse(priceCtrl.text));
                if (context.mounted) Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm dịch vụ!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // ✏️ Dialog chỉnh sửa dịch vụ
  void _showEditDialog(Service s) {
    final nameCtrl = TextEditingController(text: s.name);
    final descCtrl = TextEditingController(text: s.description ?? '');
    final priceCtrl = TextEditingController(text: s.price.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Sửa dịch vụ #${s.id}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Tên dịch vụ")),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Mô tả")),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: "Giá (VNĐ)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              try {
                await _service.update(
                  s.id,
                  nameCtrl.text,
                  descCtrl.text,
                  double.parse(priceCtrl.text),
                );
                if (context.mounted) Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật dịch vụ!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text("Cập nhật"),
          ),
        ],
      ),
    );
  }

  // 🔴 Xóa dịch vụ
  Future<void> _delete(Service s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa '${s.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.delete(s.id);
        _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa dịch vụ!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      // appBar: AppBar(title: const Text("Quản lý Dịch vụ")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: _services.length,
          itemBuilder: (context, i) {
            final s = _services[i];
            return Card(
              child: ListTile(
                title: Text("${s.name} - ${s.price}₫"),
                subtitle: Text(s.description ?? ''),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditDialog(s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _delete(s),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
