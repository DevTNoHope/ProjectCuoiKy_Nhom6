import 'package:flutter/material.dart';
import '../../models/shop.dart' hide ShopService;
import '../../services/shop_service.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  final service = ShopService();
  List<Shop> shops = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await service.getAll();
      setState(() {
        shops = data;
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool isActive = true; // default

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thêm cửa hàng"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Tên cửa hàng"),
              ),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: "Địa chỉ"),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: "Số điện thoại"),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setLocal) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kích hoạt'),
                  value: isActive, // luôn là bool
                  onChanged: (v) => setLocal(() => isActive = v),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final addr = addrCtrl.text.trim();
              if (name.isEmpty || addr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nhập tên và địa chỉ')),
                );
                return;
              }
              try {
                // Nếu service.create là positional thì đổi dòng dưới thành:
                // await service.create(name, addr, phoneCtrl.text);
                await service.create(
                  name: name,
                  address: addr,
                  phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  isActive: isActive,
                );
                if (!mounted) return;
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm cửa hàng')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Shop s) {
    final nameCtrl = TextEditingController(text: s.name);
    final addrCtrl = TextEditingController(text: s.address);
    final phoneCtrl = TextEditingController(text: s.phone ?? '');
    bool isActive = s.isActive == true; // ép về bool

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Sửa: ${s.name}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Tên cửa hàng"),
              ),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: "Địa chỉ"),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: "Số điện thoại"),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setLocal) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kích hoạt'),
                  value: isActive, // luôn là bool
                  onChanged: (v) => setLocal(() => isActive = v),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final addr = addrCtrl.text.trim();
              if (name.isEmpty || addr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nhập tên và địa chỉ')),
                );
                return;
              }
              try {
                // Nếu service.update là positional: service.update(s.id, name, addr, phoneCtrl.text, isActive)
                await service.update(
                  id: s.id,
                  name: name,
                  address: addr,
                  phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  isActive: isActive,
                );
                if (!mounted) return;
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật cửa hàng')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Shop s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa cửa hàng?'),
        content: Text('Bạn chắc chắn muốn xóa "${s.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await service.delete(s.id);
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa cửa hàng')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text("Quản lý cửa hàng"),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : RefreshIndicator(
        onRefresh: _load,
        child: shops.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 140),
            Center(child: Text('Chưa có cửa hàng')),
          ],
        )
            : ListView.builder(
          itemCount: shops.length,
          itemBuilder: (context, i) {
            final s = shops[i];
            final active = s.isActive == true; // ép bool
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(s.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.address),
                    if ((s.phone ?? '').isNotEmpty) Text('📞 ${s.phone}'),
                    Text(
                      active ? 'Đang hoạt động' : 'Ngưng hoạt động',
                      style: TextStyle(
                        color: active ? Colors.green[700] : Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(s),
                      tooltip: 'Sửa',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(s),
                      tooltip: 'Xóa',
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
