import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/booking_services.dart';
import '../../models/booking_models.dart';

class EditBookingScreen extends StatefulWidget {
  final int bookingId;
  const EditBookingScreen({super.key, required this.bookingId});

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  final _bookingSvc = BookingService();
  final _shopSvc = ShopService();
  final _stylistSvc = StylistService();
  final _serviceSvc = ServiceService();

  final _noteCtrl = TextEditingController();
  final _dateFmt = DateFormat('yyyy-MM-dd HH:mm');

  List<Shop> _shops = [];
  List<Stylist> _stylists = [];
  List<ServiceModel> _services = [];

  int? _selectedShopId;
  int? _selectedStylistId;
  int? _selectedServiceId;
  DateTime? _startDateTime;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBookingData();
  }

  Future<void> _loadBookingData() async {
    try {
      final booking = await _bookingSvc.getBookingDetail(widget.bookingId);

      final shopId = booking['shop_id'] as int?;
      final stylistId = booking['stylist_id'] as int?;
      final startDtStr = booking['start_dt'] as String?;
      final note = booking['note'] as String?;
      final servicesJson = booking['services'] as List? ?? [];

      final shops = await _shopSvc.getShops();
      final stylists =
      shopId != null ? await _stylistSvc.getByShop(shopId) : <Stylist>[];
      final services = shopId != null
          ? await _serviceSvc.getServices(shopId: shopId)
          : <ServiceModel>[];

      final currentServiceId = servicesJson.isNotEmpty
          ? (servicesJson.first['service_id'] as int?)
          : null;

      setState(() {
        _shops = shops;
        _stylists = stylists;
        _services = services;
        _selectedShopId = shopId;
        _selectedStylistId = stylistId;
        _selectedServiceId = currentServiceId;
        _startDateTime = startDtStr != null
            ? DateTime.parse(startDtStr).toLocal() // ✅ convert chuẩn VN time
            : null;
        _noteCtrl.text = note ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    if (_selectedShopId == null ||
        _selectedStylistId == null ||
        _selectedServiceId == null ||
        _startDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ thông tin.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final selectedService =
      _services.firstWhere((s) => s.id == _selectedServiceId);

      // 🕒 Chuẩn hóa giờ VN (UTC+7)
      final localStart = _startDateTime!.toUtc().add(const Duration(hours: 7));

      await _bookingSvc.updateBooking(widget.bookingId, {
        'shop_id': _selectedShopId,
        'stylist_id': _selectedStylistId,
        'start_dt': localStart.toIso8601String(),
        'note': _noteCtrl.text.trim(),
        'services': [
          {
            'service_id': _selectedServiceId,
            'price': selectedService.price,
            'duration_min': selectedService.durationMin ?? 30,
          }
        ],
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thay đổi thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi lưu: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa lịch đặt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏪 Chọn cửa hàng',
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<int>(
              value: _selectedShopId,
              items: _shops
                  .map((s) =>
                  DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() {
                  _selectedShopId = v;
                  _selectedStylistId = null;
                  _selectedServiceId = null;
                  _isLoading = true;
                });
                _stylists = await _stylistSvc.getByShop(v);
                _services = await _serviceSvc.getServices(shopId: v);
                setState(() => _isLoading = false);
              },
            ),
            const SizedBox(height: 16),

            const Text('💇‍♂️ Chọn thợ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<int>(
              value: _selectedStylistId,
              items: _stylists
                  .map((s) =>
                  DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedStylistId = v),
            ),
            const SizedBox(height: 16),

            const Text('✂️ Chọn dịch vụ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<int>(
              value: _selectedServiceId,
              items: _services
                  .map((s) => DropdownMenuItem<int>(
                value: s.id,
                child: Text('${s.name} (${s.price}đ)'),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedServiceId = v),
            ),
            const SizedBox(height: 16),

            const Text('🕒 Thời gian bắt đầu:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(
                  _startDateTime == null
                      ? 'Chưa chọn'
                      : _dateFmt.format(_startDateTime!),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDateTime ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                            _startDateTime ?? DateTime.now()),
                      );
                      if (time != null) {
                        setState(() {
                          _startDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
