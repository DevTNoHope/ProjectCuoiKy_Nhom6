import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'notification_service.dart';

class NotificationInitializer {
  static Future<void> init() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    OneSignal.initialize('YOUR-ONESIGNAL-APP-ID'); // thay ID thật của bạn

    await OneSignal.Notifications.requestPermission(true);

    // NotificationService.setupOpenedHandler();
  }
}
