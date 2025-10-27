// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// 🔹 Hàm khởi tạo OneSignal
  Future<void> _initializeApp() async {
    try {
      // Khởi tạo OneSignal
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize('YOUR-ONESIGNAL-APP-ID'); // 👈 điền App ID thật
      await OneSignal.Notifications.requestPermission(true);

      // Đăng ký listener khi click vào thông báo
      NotificationService.setupOpenedHandler();

      // Giả lập load app trong 2 giây
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Sau khi init xong → chuyển qua màn hình login hoặc home
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint("❌ OneSignal init error: $e");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
