import 'package:flutter/material.dart';
import '../../services/stylist_service.dart';
import '../../services/shop_service.dart';
import '../../models/stylist.dart';
import '../../models/shop.dart';

class StylistsPage extends StatefulWidget {
  const StylistsPage({super.key});

  @override
  State<StylistsPage> createState() => _StylistsPageState();
}

class _StylistsPageState extends State<StylistsPage> {
  final _stylistService = StylistService();
  final _shopService = ShopService();

  List<Stylist> _stylists = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _stylistService.getAll();
      setState(() {
        _stylists = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // -------------------- CREATE --------------------
  Future<void> _openAddStylistDialog() async {
    // Load shop trước cho dropdown
    List<Shop> shops;
    try {
      shops = await _shopService.getAll();
      if (shops.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có shop nào. Hãy tạo shop trước.')),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không tải được shop: $e')));
      return;
    }

    final nameCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    Shop selected = shops.first;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm Stylist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Shop>(
              value: selected,
              items: shops
                  .map((s) =>
                  DropdownMenuItem(value: s, child: Text('${s.name} (ID ${s.id})')))
                  .toList(),
              onChanged: (v) {
                if (v != null) selected = v;
              },
              decoration: const InputDecoration(labelText: 'Chọn Shop'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên stylist'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bioCtrl,
              decoration: const InputDecoration(labelText: 'Tiểu sử / mô tả'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final bio = bioCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên stylist')),
                );
                return;
              }
              try {
                await _stylistService.create(
                  shopId: selected.id,
                  name: name,
                  bio: bio.isEmpty ? null : bio,
                  avatarUrl: null,
                  isActive: true,
                  serviceIds: const [],
                );

                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Đã thêm stylist')));
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Lỗi tạo stylist: $e')));
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // -------------------- UPDATE --------------------
  void _showEditStylistDialog(Stylist s) {
    final nameCtrl = TextEditingController(text: s.name);
    final bioCtrl = TextEditingController(text: s.bio ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sửa stylist: ${s.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên stylist'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bioCtrl,
              decoration: const InputDecoration(labelText: 'Tiểu sử / mô tả'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final bio = bioCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên')),
                );
                return;
              }
              try {

                await _stylistService.update(
                  s.id,
                  name,
                  bio.isEmpty ? null : bio,
                );



                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Đã cập nhật stylist')));
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // -------------------- DELETE --------------------
  Future<void> _confirmDeleteStylist(Stylist s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa stylist?'),
        content: Text('Bạn chắc chắn muốn xóa "${s.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _stylistService.delete(s.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã xóa stylist')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text(_error!));
    } else if (_stylists.isEmpty) {
      body = const Center(child: Text('Chưa có stylist'));
    } else {
      body = ListView.builder(
        itemCount: _stylists.length,
        itemBuilder: (_, i) {
          final s = _stylists[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text('${s.name} (Shop #${s.shopId})'),
              subtitle: Text((s.bio ?? '').isEmpty ? '—' : s.bio!),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Sửa',
                    onPressed: () => _showEditStylistDialog(s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Xóa',
                    onPressed: () => _confirmDeleteStylist(s),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        // title: const Text('Quản lý Thợ Tóc'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddStylistDialog,
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}
