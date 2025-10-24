// lib/screens/booking/service_pick_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/booking_services.dart';
import '../../models/booking_models.dart';

class ServicePickScreen extends StatefulWidget {
  final int shopId, stylistId;
  const ServicePickScreen({super.key, required this.shopId, required this.stylistId});
  @override State<ServicePickScreen> createState()=>_ServicePickScreenState();
}
class _ServicePickScreenState extends State<ServicePickScreen>{
  final _svc = ServiceService(); late Future<List<ServiceModel>> _f;
  @override void initState(){ super.initState(); _f = _svc.getServices(shopId: widget.shopId); }
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => context.pop(),
    ),title: const Text('Chọn dịch vụ')),
        body: FutureBuilder<List<ServiceModel>>(future:_f,builder:(_,snap){
          if(!snap.hasData) return const Center(child:CircularProgressIndicator());
          final list = snap.data!;
          return ListView.builder(itemCount:list.length,itemBuilder:(_,i){
            final sv = list[i];
            return ListTile(
              title: Text('${sv.name} (${sv.durationMin} phút)'),
              onTap: ()=> context.go('/booking/slots', extra:{
                'shop': widget.shopId,
                'stylist': widget.stylistId,
                'service': sv,
              }),
            );
          });
        }));
  }
}
