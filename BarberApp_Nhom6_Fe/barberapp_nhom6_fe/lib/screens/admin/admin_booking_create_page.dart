import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';
import '../../services/shop_service.dart';
import '../../services/stylist_service.dart';
import '../../services/service_service.dart';
import '../../services/user_service.dart';
import '../../models/shop.dart';
import '../../models/stylist.dart';
import '../../models/service.dart';
import '../../models/user.dart';

class AdminBookingCreatePage extends StatefulWidget {
  const AdminBookingCreatePage({super.key});

  @override
  State<AdminBookingCreatePage> createState() => _AdminBookingCreatePageState();
}

class _AdminBookingCreatePageState extends State<AdminBookingCreatePage> {
  final _bookingSvc = BookingService();
  final _shopSvc = ShopService();
  final _stylistSvc = StylistService();
  final _serviceSvc = ServiceService();
  final _userSvc = UserService();

  int? selectedUserId;
  UserModel? selectedUser;
  Shop? selectedShop;
  Stylist? selectedStylist;
  List<Service> selectedServices = [];
  DateTime? startTime;
  DateTime? endTime;
  double totalPrice = 0;

  Future<void> _submitBooking() async {
    if (selectedUserId == null ||
        selectedShop == null ||
        selectedServices.isEmpty ||
        startTime == null ||
        endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    try {
      await _bookingSvc.create(
        userId: selectedUserId!,
        shopId: selectedShop!.id,
        stylistId: selectedStylist?.id,
        startDt: startTime!.toIso8601String(),
        endDt: endTime!.toIso8601String(),
        totalPrice: totalPrice,
        services: selectedServices
            .map((s) => {
          "service_id": s.id,
          "price": s.price,
          "duration_min": s.durationMin,
        })
            .toList(),
        note: "Admin đặt lịch hộ khách",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đặt lịch thành công!')),
      );
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đặt lịch: $e')),
      );
    }
  }

  void _resetForm() {
    setState(() {
      selectedUserId = null;
      selectedUser = null;
      selectedShop = null;
      selectedStylist = null;
      selectedServices = [];
      startTime = null;
      endTime = null;
      totalPrice = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📅 Admin đặt lịch hộ khách"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("👤 Chọn khách hàng", style: TextStyle(fontSize: 18)),
            ListTile(
              title: Text(
                selectedUser == null
                    ? "Chọn khách hàng"
                    : "${selectedUser!.phone ?? 'Không có SĐT'} - ${selectedUser!.fullName}",
              ),
              trailing: const Icon(Icons.person),
              onTap: () async {
                try {
                  final users = await _userSvc.getAll();
                  if (users.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không có khách hàng nào')),
                    );
                    return;
                  }

                  final chosen = await showDialog<UserModel>(
                    context: context,
                    builder: (_) => SimpleDialog(
                      title: const Text("Chọn khách hàng"),
                      children: users
                          .map((u) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, u),
                        child: Text(
                          "${u.phone ?? 'Không có SĐT'} - ${u.fullName}",
                        ),
                      ))
                          .toList(),
                    ),
                  );

                  if (chosen != null) {
                    setState(() {
                      selectedUser = chosen;
                      selectedUserId = chosen.id;
                    });
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi tải khách hàng: $e')),
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            // 🔹 Shop
            ListTile(
              title: Text(selectedShop?.name ?? "Chọn chi nhánh"),
              trailing: const Icon(Icons.store),
              onTap: () async {
                final shops = await _shopSvc.getAll();
                final shop = await showDialog<Shop>(
                  context: context,
                  builder: (_) => SimpleDialog(
                    title: const Text("Chọn chi nhánh"),
                    children: shops
                        .map((s) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, s),
                      child: Text(s.name),
                    ))
                        .toList(),
                  ),
                );
                if (shop != null) setState(() => selectedShop = shop);
              },
            ),

            // 🔹 Stylist
            ListTile(
              title: Text(selectedStylist?.name ?? "Chọn stylist (tùy chọn)"),
              trailing: const Icon(Icons.cut),
              onTap: () async {
                if (selectedShop == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hãy chọn chi nhánh trước')),
                  );
                  return;
                }
                final stylists = await _stylistSvc.getByShop(selectedShop!.id);
                final st = await showDialog<Stylist>(
                  context: context,
                  builder: (_) => SimpleDialog(
                    title: const Text("Chọn stylist"),
                    children: stylists
                        .map((s) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, s),
                      child: Text(s.name),
                    ))
                        .toList(),
                  ),
                );
                if (st != null) setState(() => selectedStylist = st);
              },
            ),

            // 🔹 Dịch vụ
            ListTile(
              title: Text(
                selectedServices.isEmpty
                    ? "Chọn dịch vụ"
                    : "Đã chọn: ${selectedServices.map((s) => s.name).join(', ')}",
                style: const TextStyle(fontSize: 16),
              ),
              trailing: const Icon(Icons.miscellaneous_services),
              onTap: () async {
                final allServices = await _serviceSvc.getAll();
                List<Service> tempSelected = List.from(selectedServices);

                await showDialog(
                  context: context,
                  builder: (_) => StatefulBuilder(
                    builder: (context, setDialogState) => AlertDialog(
                      title: const Text("Chọn dịch vụ"),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: allServices.map((s) {
                            final isChecked = tempSelected.contains(s);
                            return CheckboxListTile(
                              value: isChecked,
                              title: Text(
                                  "${s.name} - ${s.price}đ (${s.durationMin}p)"),
                              onChanged: (v) {
                                setDialogState(() {
                                  if (v == true) {
                                    tempSelected.add(s);
                                  } else {
                                    tempSelected.remove(s);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              selectedServices = tempSelected;
                              totalPrice = selectedServices.fold(
                                  0, (sum, s) => sum + s.price);
                            });
                          },
                          child: const Text("Xong"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 🔹 Thời gian
            ElevatedButton.icon(
              icon: const Icon(Icons.access_time),
              label: Text(startTime == null
                  ? "Chọn thời gian bắt đầu"
                  : "Bắt đầu: ${DateFormat('dd/MM HH:mm').format(startTime!)}"),
              onPressed: () async {
                if (selectedStylist == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hãy chọn stylist trước')),
                  );
                  return;
                }
                if (selectedServices.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hãy chọn ít nhất 1 dịch vụ')),
                  );
                  return;
                }

                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (pickedDate == null) return;
                final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);

                try {
                  final slots = await _bookingSvc.getAvailableSlots(
                      selectedStylist!.id, dateStr);
                  if (slots.isEmpty) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                          Text('Thợ này nghỉ hoặc kín lịch ngày này')),
                    );
                    return;
                  }

                  final totalDuration = selectedServices.fold<int>(
                      0, (sum, s) => sum + (s.durationMin ?? 30));

                  final choices = <DateTime>[];
                  for (final s in slots) {
                    final st = DateTime.parse(s['start']!);
                    final en = DateTime.parse(s['end']!);
                    DateTime cur = st;
                    while (cur
                        .add(Duration(minutes: totalDuration))
                        .isBefore(en)) {
                      choices.add(cur);
                      cur = cur.add(const Duration(minutes: 15));
                    }
                  }

                  if (choices.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Không đủ thời gian trống cho dịch vụ đã chọn')),
                    );
                    return;
                  }

                  final chosen = await showDialog<DateTime>(
                    context: context,
                    builder: (_) => SimpleDialog(
                      title: const Text("Chọn giờ bắt đầu"),
                      children: choices
                          .map((t) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, t),
                        child: Text(DateFormat('HH:mm').format(t)),
                      ))
                          .toList(),
                    ),
                  );

                  if (chosen != null) {
                    setState(() {
                      startTime = chosen;
                      endTime = chosen.add(Duration(minutes: totalDuration));
                    });
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không lấy được giờ trống: $e')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),

            if (endTime != null)
              Text(
                "⏰ Kết thúc dự kiến: ${DateFormat('dd/MM HH:mm').format(endTime!)}",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            const SizedBox(height: 20),

            Text(
              "💰 Tổng tiền: ${totalPrice.toStringAsFixed(0)}đ",
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text("Xác nhận đặt lịch"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submitBooking,
            ),
          ],
        ),
      ),
    );
  }
}
