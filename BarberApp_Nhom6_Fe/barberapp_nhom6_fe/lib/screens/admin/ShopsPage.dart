import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  // 📍 Lấy vị trí hiện tại
  Future<void> _getCurrentLocation(
      TextEditingController latCtrl, TextEditingController lngCtrl) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng bật GPS')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có quyền truy cập vị trí')),
      );
      return;
    }

    Position pos =
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    latCtrl.text = pos.latitude.toStringAsFixed(6);
    lngCtrl.text = pos.longitude.toStringAsFixed(6);
  }

  // 🟢 Dialog thêm mới
  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    TimeOfDay? openTime;
    TimeOfDay? closeTime;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latCtrl,
                        decoration: const InputDecoration(labelText: "Vĩ độ (lat)"),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lngCtrl,
                        decoration: const InputDecoration(labelText: "Kinh độ (lng)"),
                        readOnly: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.teal),
                      onPressed: () async {
                        await _getCurrentLocation(latCtrl, lngCtrl);
                        setLocal(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: openTime ?? TimeOfDay.now(),
                          );
                          if (t != null) setLocal(() => openTime = t);
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(openTime == null
                            ? 'Giờ mở cửa'
                            : 'Mở: ${openTime!.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: closeTime ?? TimeOfDay.now(),
                          );
                          if (t != null) setLocal(() => closeTime = t);
                        },
                        icon: const Icon(Icons.lock_clock),
                        label: Text(closeTime == null
                            ? 'Giờ đóng cửa'
                            : 'Đóng: ${closeTime!.format(context)}'),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kích hoạt'),
                  value: isActive,
                  onChanged: (v) => setLocal(() => isActive = v),
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
                  await service.create(
                    name: name,
                    address: addr,
                    phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    lat: double.tryParse(latCtrl.text),
                    lng: double.tryParse(lngCtrl.text),
                    openTime: openTime != null
                        ? "${openTime!.hour.toString().padLeft(2, '0')}:${openTime!.minute.toString().padLeft(2, '0')}:00"
                        : null,
                    closeTime: closeTime != null
                        ? "${closeTime!.hour.toString().padLeft(2, '0')}:${closeTime!.minute.toString().padLeft(2, '0')}:00"
                        : null,
                    isActive: isActive,
                  );

                  if (!mounted) return;
                  Navigator.pop(context);
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã thêm cửa hàng')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: const Text("Lưu"),
            ),
          ],
        ),
      ),
    );
  }

  // ✏️ Dialog sửa
  void _showEditDialog(Shop s) {
    final nameCtrl = TextEditingController(text: s.name);
    final addrCtrl = TextEditingController(text: s.address);
    final phoneCtrl = TextEditingController(text: s.phone ?? '');
    final latCtrl = TextEditingController(text: s.lat?.toString() ?? '');
    final lngCtrl = TextEditingController(text: s.lng?.toString() ?? '');
    bool isActive = s.isActive;
    TimeOfDay? openTime;
    TimeOfDay? closeTime;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text("Sửa: ${s.name}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Tên cửa hàng")),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: "Địa chỉ")),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Số điện thoại")),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latCtrl,
                        decoration: const InputDecoration(labelText: "Vĩ độ (lat)"),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lngCtrl,
                        decoration: const InputDecoration(labelText: "Kinh độ (lng)"),
                        readOnly: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.teal),
                      onPressed: () async {
                        await _getCurrentLocation(latCtrl, lngCtrl);
                        setLocal(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: openTime ?? TimeOfDay.now(),
                          );
                          if (t != null) setLocal(() => openTime = t);
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(openTime == null
                            ? 'Giờ mở cửa'
                            : 'Mở: ${openTime!.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: closeTime ?? TimeOfDay.now(),
                          );
                          if (t != null) setLocal(() => closeTime = t);
                        },
                        icon: const Icon(Icons.lock_clock),
                        label: Text(closeTime == null
                            ? 'Giờ đóng cửa'
                            : 'Đóng: ${closeTime!.format(context)}'),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kích hoạt'),
                  value: isActive,
                  onChanged: (v) => setLocal(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () async {
                try {
                  await service.update(
                    id: s.id,
                    name: nameCtrl.text.trim(),
                    address: addrCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    lat: double.tryParse(latCtrl.text),
                    lng: double.tryParse(lngCtrl.text),
                    openTime: openTime != null
                        ? "${openTime!.hour.toString().padLeft(2, '0')}:${openTime!.minute.toString().padLeft(2, '0')}:00"
                        : null,
                    closeTime: closeTime != null
                        ? "${closeTime!.hour.toString().padLeft(2, '0')}:${closeTime!.minute.toString().padLeft(2, '0')}:00"
                        : null,
                    isActive: isActive,
                  );

                  if (!mounted) return;
                  Navigator.pop(context);
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật cửa hàng')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: const Text("Lưu"),
            ),
          ],
        ),
      ),
    );
  }

  // 🗑️ Xóa cửa hàng
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
    await service.delete(s.id);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa cửa hàng')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý cửa hàng"),
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
            final active = s.isActive;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(s.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.address),
                    if ((s.phone ?? '').isNotEmpty) Text('📞 ${s.phone}'),
                    if (s.lat != null && s.lng != null)
                      Text('📍 ${s.lat}, ${s.lng}', style: const TextStyle(fontSize: 12)),
                    if (s.openTime != null && s.closeTime != null)
                      Text('🕒 ${s.openTime} - ${s.closeTime}', style: const TextStyle(fontSize: 12)),
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
