import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> initializeNotification() async {
    await AwesomeNotifications().initialize(
      null, // no default icon for now
      [
        NotificationChannel(
          channelKey: 'medication_channel',
          channelName: 'Medication Reminders',
          channelDescription: 'Notification channel for medication reminders',
          defaultColor: Colors.blue,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: true,
          enableLights: true,
          enableVibration: true,
        )
      ],
    );

    // Request permission
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }
  static Future<void> createMedicationReminder({
    required String reminderId,
    required String title,
    required String body,
    required String time,
  }) async {
    final timeComponents = time.split(':');
    final hour = int.parse(timeComponents[0]);
    final minute = int.parse(timeComponents[1]);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: reminderId.hashCode,
        channelKey: 'medication_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  static Future<void> cancelNotification(String reminderId) async {
    await AwesomeNotifications().cancel(reminderId.hashCode);
  }
}