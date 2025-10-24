// lib/screens/booking/stylist_list_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/booking_services.dart';
import '../../models/booking_models.dart';

class StylistListScreen extends StatefulWidget {
  final int shopId; const StylistListScreen({super.key, required this.shopId});
  @override State<StylistListScreen> createState()=>_StylistListScreenState();
}
class _StylistListScreenState extends State<StylistListScreen>{
  final _svc = StylistService(); late Future<List<Stylist>> _f;
  @override void initState(){ super.initState(); _f = _svc.getByShop(widget.shopId); }
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => context.pop(),
    ),title: const Text('Chọn thợ')),
        body: FutureBuilder<List<Stylist>>(future:_f,builder:(_,snap){
          if(!snap.hasData) return const Center(child:CircularProgressIndicator());
          final list = snap.data!;
          return ListView.builder(itemCount:list.length,itemBuilder:(_,i){
            final st = list[i];
            return ListTile(
              title: Text(st.name),
              onTap: ()=> context.go('/stylists/${st.id}/services?shopId=${widget.shopId}'),
            );
          });
        }));
  }
}
