import 'package:flutter_background_service/flutter_background_service.dart';

class NotificationHelper {
  static Future<void> createNotificationChannel() async {
    // No need to use the invoke method; the notification channel is automatically created in the background service setup.
    print("Notification channel setup handled by service configuration.");
  }
}
