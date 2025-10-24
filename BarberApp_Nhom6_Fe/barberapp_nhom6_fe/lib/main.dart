// lib/main.dart
import 'package:flutter/material.dart';
import 'routers/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BarberApp());
}

class BarberApp extends StatelessWidget {
  const BarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Barber Booking',
      routerConfig: AppRouter.router,
    );
  }
}
