import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../models/shop.dart';
import '../../services/shop_service.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({super.key});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final _svc = ShopService();
  late Future<List<Shop>> _f;
  Position? _userPos;
  final Distance _distance = const Distance(); // 👉 Thêm lớp tính khoảng cách

  @override
  void initState() {
    super.initState();
    _f = _svc.getAll();
    _loadUserLocation();
  }

  // 📍 Lấy vị trí hiện tại của user
  Future<void> _loadUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng bật GPS')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quyền truy cập vị trí')));
      return;
    }

    Position pos =
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => _userPos = pos);
  }

  // 📏 Hàm tính khoảng cách giữa user và cửa hàng
  String _getDistanceText(double? shopLat, double? shopLng) {
    if (_userPos == null || shopLat == null || shopLng == null) return '';
    final double meters = _distance(
      LatLng(_userPos!.latitude, _userPos!.longitude),
      LatLng(shopLat, shopLng),
    );
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn cửa hàng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _loadUserLocation,
            tooltip: 'Định vị lại',
          )
        ],
      ),
      body: FutureBuilder<List<Shop>>(
        future: _f,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final shops = snap.data!;
          if (shops.isEmpty) {
            return const Center(child: Text('Chưa có cửa hàng'));
          }

          // 🎯 Xác định vị trí trung tâm bản đồ
          final startPoint = _userPos != null
              ? LatLng(_userPos!.latitude, _userPos!.longitude)
              : (shops.first.lat != null && shops.first.lng != null)
              ? LatLng(shops.first.lat!, shops.first.lng!)
              : const LatLng(10.762622, 106.660172); // fallback: SG

          // 🗺️ Danh sách marker (hiển thị luôn tên cửa hàng)
          final markers = <Marker>[
            // 🧍 Vị trí người dùng
            if (_userPos != null)
              Marker(
                point: LatLng(_userPos!.latitude, _userPos!.longitude),
                width: 60,
                height: 60,
                child: const Icon(Icons.person_pin_circle,
                    color: Colors.red, size: 40),
              ),

            // 🏠 Các cửa hàng
            ...shops.where((s) => s.lat != null && s.lng != null).map(
                  (s) => Marker(
                point: LatLng(s.lat!, s.lng!),
                width: 120,
                height: 60,
                child: GestureDetector(
                  onTap: () => context.go('/shops/${s.id}/stylists'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 📛 Hiển thị tên cửa hàng phía trên marker
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 3,
                                offset: Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.store,
                          color: Colors.teal, size: 32),
                    ],
                  ),
                ),
              ),
            ),
          ];

          return Column(
            children: [
              // 🗺️ Bản đồ OpenStreetMap
              Expanded(
                flex: 2,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: startPoint,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.barberapp_nhom6_fe',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),

              // 📋 Danh sách cửa hàng
              Expanded(
                flex: 3,
                child: ListView.separated(
                  itemCount: shops.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = shops[i];
                    final distanceText =
                    _getDistanceText(s.lat, s.lng); // 👉 tính khoảng cách

                    return ListTile(
                      leading: const Icon(Icons.store, color: Colors.teal),
                      title: Text(
                        s.name,
                        style:
                        const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.address),
                          if (distanceText.isNotEmpty)
                            Text(
                              '📍 Cách bạn $distanceText',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                      trailing:
                      const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.go('/shops/${s.id}/stylists'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
