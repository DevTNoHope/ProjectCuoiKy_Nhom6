import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import '../../services/shop_service.dart';
import '../../services/stylist_service.dart';
import '../../services/service_service.dart';
import '../../models/shop.dart';
import '../../models/stylist.dart';
import '../../models/service.dart';

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

  int? selectedUserId;
  Shop? selectedShop;
  Stylist? selectedStylist;
  List<Service> selectedServices = [];
  DateTime? startTime;
  DateTime? endTime;
  double totalPrice = 0;

  final _userIdCtrl = TextEditingController();

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
          "duration_min": 30,
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
      selectedShop = null;
      selectedStylist = null;
      selectedServices = [];
      startTime = null;
      endTime = null;
      totalPrice = 0;
      _userIdCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("👤 Nhập User ID", style: TextStyle(fontSize: 18)),
            TextField(
              controller: _userIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Nhập ID khách hàng...",
              ),
              onChanged: (v) => selectedUserId = int.tryParse(v),
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

            // 🔹 Dịch vụ (đã sửa logic hiển thị)
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
                              title: Text("${s.name} - ${s.price}đ"),
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
                  : "Bắt đầu: ${startTime.toString().substring(0, 16)}"),
              onPressed: () async {
                final dt = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (dt != null) {
                  final t = await showTimePicker(
                      context: context, initialTime: TimeOfDay.now());
                  if (t != null) {
                    setState(() => startTime =
                        DateTime(dt.year, dt.month, dt.day, t.hour, t.minute));
                    setState(() =>
                    endTime = startTime!.add(const Duration(hours: 1)));
                  }
                }
              },
            ),
            const SizedBox(height: 20),

            // Tổng tiền
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
