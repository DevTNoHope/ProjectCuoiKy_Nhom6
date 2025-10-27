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

  final _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

    Stylist selected = stylists.first;
    List<String> selectedDays = [];
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
        return AlertDialog(
          title: const Text('Thêm ca làm'),
          content: SingleChildScrollView(
            child: Column(
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
                    if (v != null) setLocal(() => selected = v);
                  },
                  decoration: const InputDecoration(labelText: 'Chọn stylist'),
                ),
                const SizedBox(height: 8),

                // Chọn nhiều thứ
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Chọn các ngày làm việc'),
                  child: Wrap(
                    spacing: 6,
                    children: _weekdays.map((day) {
                      final isSelected = selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: isSelected,
                        onSelected: (v) {
                          setLocal(() {
                            if (v) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),
                // Giờ bắt đầu
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(startTime == null
                      ? 'Chọn giờ bắt đầu'
                      : 'Giờ bắt đầu: ${startTime!.format(context)}'),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) setLocal(() => startTime = picked);
                  },
                ),
                const SizedBox(height: 4),
                // Giờ kết thúc
                ListTile(
                  leading: const Icon(Icons.access_time_outlined),
                  title: Text(endTime == null
                      ? 'Chọn giờ kết thúc'
                      : 'Giờ kết thúc: ${endTime!.format(context)}'),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) setLocal(() => endTime = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (selectedDays.isEmpty || startTime == null || endTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chọn đầy đủ thứ và giờ')),
                  );
                  return;
                }
                try {
                  for (final wd in selectedDays) {
                    await _wsService.create(
                      stylistId: selected.id,
                      weekday: wd,
                      startTime:
                      "${startTime?.hour.toString().padLeft(2, '0') ?? '00'}:${startTime?.minute.toString().padLeft(2, '0') ?? '00'}",
                      endTime:
                      "${endTime?.hour.toString().padLeft(2, '0') ?? '00'}:${endTime?.minute.toString().padLeft(2, '0') ?? '00'}",
                    );
                  }

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
        );
      }),
    );
  }

  // -------------------- UPDATE --------------------
  void _showEditShiftDialog(WorkSchedule w) {
    String weekday = w.weekday;
    TimeOfDay? startTime = _parseTime(w.startTime);
    TimeOfDay? endTime = _parseTime(w.endTime);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setLocal) {
        return AlertDialog(
          title: Text('Sửa ca làm #${w.id} (${w.stylistName ?? "Stylist #${w.stylistId}"})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: weekday,
                items: _weekdays
                    .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setLocal(() => weekday = v);
                },
                decoration: const InputDecoration(labelText: 'Chọn thứ'),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(startTime == null
                    ? 'Chọn giờ bắt đầu'
                    : 'Giờ bắt đầu: ${startTime!.format(context)}'),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) setLocal(() => startTime = picked);
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time_outlined),
                title: Text(endTime == null
                    ? 'Chọn giờ kết thúc'
                    : 'Giờ kết thúc: ${endTime!.format(context)}'),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: endTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) setLocal(() => endTime = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (startTime == null || endTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chọn giờ bắt đầu/kết thúc')),
                  );
                  return;
                }
                try {
                  await _wsService.update(
                    w.id,
                    weekday: weekday,
                    startTime:
                    "${startTime?.hour.toString().padLeft(2, '0') ?? '00'}:${startTime?.minute.toString().padLeft(2, '0') ?? '00'}",
                    endTime:
                    "${endTime?.hour.toString().padLeft(2, '0') ?? '00'}:${endTime?.minute.toString().padLeft(2, '0') ?? '00'}",
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
        );
      }),
    );
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  // -------------------- DELETE --------------------
  Future<void> _confirmDeleteShift(WorkSchedule w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa ca làm?'),
        content: Text(
            'Xóa ca ${w.weekday} ${w.startTime}-${w.endTime} của ${w.stylistName ?? "stylist #${w.stylistId}"}?'),
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
