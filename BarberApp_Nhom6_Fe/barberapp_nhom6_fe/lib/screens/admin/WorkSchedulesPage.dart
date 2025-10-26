import 'package:flutter/material.dart';
import '../../services/work_schedule_service.dart';
import '../../services/stylist_service.dart';
import '../../models/work_schedule.dart';
import '../../models/stylist.dart';

class WorkSchedulesPage extends StatefulWidget {
  const WorkSchedulesPage({super.key});

  @override
  State<WorkSchedulesPage> createState() => _WorkSchedulesPageState();
}

class _WorkSchedulesPageState extends State<WorkSchedulesPage> {
  final _wsService = WorkScheduleService();
  final _styService = StylistService();

  List<WorkSchedule> _schedules = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _wsService.getAll();
      setState(() {
        _schedules = data;
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
  Future<void> _openAddShiftDialog() async {
    // 1) Load stylists trước
    List<Stylist> stylists = [];
    try {
      stylists = await _styService.getAll();
      if (stylists.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có stylist nào. Hãy tạo stylist trước.')),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được danh sách stylist: $e')),
      );
      return;
    }

    final weekdayCtrl = TextEditingController(); // Mon/Tue/Wed/...
    final startCtrl = TextEditingController();   // HH:mm
    final endCtrl = TextEditingController();     // HH:mm
    Stylist selected = stylists.first;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm ca làm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Stylist>(
              value: selected,
              items: stylists
                  .map((s) => DropdownMenuItem(
                value: s,
                child: Text('${s.name} (ID ${s.id})'),
              ))
                  .toList(),
              onChanged: (v) {
                if (v != null) selected = v;
              },
              decoration: const InputDecoration(labelText: 'Chọn stylist'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weekdayCtrl,
              decoration: const InputDecoration(labelText: 'Thứ (Mon/Tue/Wed/...)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: startCtrl,
              decoration: const InputDecoration(labelText: 'Giờ bắt đầu (HH:mm)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: endCtrl,
              decoration: const InputDecoration(labelText: 'Giờ kết thúc (HH:mm)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final wd = weekdayCtrl.text.trim();
              final st = startCtrl.text.trim();
              final en = endCtrl.text.trim();
              if (wd.isEmpty || st.isEmpty || en.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Điền đủ thông tin')),
                );
                return;
              }
              try {
                await _wsService.create(
                  stylistId: selected.id,
                  weekday: wd,
                  startTime: st,
                  endTime: en,
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm ca làm')),
                );
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi tạo ca làm: $e')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // -------------------- UPDATE --------------------
  void _showEditShiftDialog(WorkSchedule w) {
    final weekdayCtrl = TextEditingController(text: w.weekday);
    final startCtrl = TextEditingController(text: w.startTime);
    final endCtrl = TextEditingController(text: w.endTime);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sửa ca làm #${w.id} (${w.stylistName ?? "Stylist #${w.stylistId}"})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weekdayCtrl,
              decoration: const InputDecoration(labelText: 'Thứ (Mon/Tue/...)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: startCtrl,
              decoration: const InputDecoration(labelText: 'Giờ bắt đầu (HH:mm)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: endCtrl,
              decoration: const InputDecoration(labelText: 'Giờ kết thúc (HH:mm)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final wd = weekdayCtrl.text.trim();
              final st = startCtrl.text.trim();
              final en = endCtrl.text.trim();
              if (wd.isEmpty || st.isEmpty || en.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Điền đủ thông tin')),
                );
                return;
              }
              try {
                await _wsService.update(
                  w.id,
                  weekday: wd,
                  startTime: st,
                  endTime: en,
                );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật ca làm')),
                );
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi cập nhật: $e')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // -------------------- DELETE --------------------
  Future<void> _confirmDeleteShift(WorkSchedule w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa ca làm?'),
        content: Text('Xóa ca ${w.weekday} ${w.startTime}-${w.endTime} của ${w.stylistName ?? "stylist #${w.stylistId}"}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _wsService.delete(w.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa ca làm')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xóa: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text(_error!));
    } else if (_schedules.isEmpty) {
      body = const Center(child: Text('Chưa có ca làm'));
    } else {
      body = ListView.builder(
        itemCount: _schedules.length,
        itemBuilder: (_, i) {
          final w = _schedules[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text('${w.stylistName ?? "Stylist #${w.stylistId}"} • ${w.weekday}'),
              subtitle: Text('${w.startTime} - ${w.endTime}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Sửa',
                    onPressed: () => _showEditShiftDialog(w),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Xóa',
                    onPressed: () => _confirmDeleteShift(w),
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
        // title: const Text('Ca Làm Của Nhân Viên'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddShiftDialog,
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}
