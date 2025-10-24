// lib/screens/booking/shop_list_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/booking_models.dart';
import '../../services/booking_services.dart';

class ShopListScreen extends StatefulWidget { const ShopListScreen({super.key});
@override State<ShopListScreen> createState()=> _ShopListScreenState(); }
class _ShopListScreenState extends State<ShopListScreen>{
  final _svc = ShopService(); late Future<List<Shop>> _f;
  @override void initState(){ super.initState(); _f = _svc.getShops(); }
  @override Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home'); // 👈 đổi route này cho phù hợp với trang chính của bạn
              }
            },
          ),
          title: const Text('Chọn cửa hàng'),
        ),

        body: FutureBuilder<List<Shop>>(future: _f, builder: (_,snap){
          if(!snap.hasData) return const Center(child:CircularProgressIndicator());
          final shops = snap.data!;
          return ListView.separated(
              itemCount: shops.length, separatorBuilder: (_,__)=>const Divider(),
              itemBuilder: (_,i){
                final s = shops[i];
                return ListTile(
                  title: Text(s.name), subtitle: Text(s.address ?? ''),
                  onTap: ()=> context.go('/shops/${s.id}/stylists'),
                );
              });
        }));
  }
}
