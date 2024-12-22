// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:pedometer/pedometer.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'firestore_service.dart';
// import 'package:healthcare_app/service/NotificationHelper.dart';
//
// Future<void> initializeBackgroundService() async {
//   await Firebase.initializeApp();
//
//   // Initialize local notifications
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//   const AndroidInitializationSettings initializationSettingsAndroid =
//   AndroidInitializationSettings('@mipmap/ic_launcher');
//   final InitializationSettings initializationSettings =
//   InitializationSettings(android: initializationSettingsAndroid);
//   await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//
//   // Start the background service
//   final service = FlutterBackgroundService();
//
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onBackgroundServiceStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: "step_tracking_channel",  // No need to invoke here
//       initialNotificationTitle: "Healthcare App",
//       initialNotificationContent: "Tracking steps in the background...",
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: onBackgroundServiceStart,
//       onBackground: onIosBackground,
//     ),
//   );
//
//   service.startService();
// }
//
// @pragma('vm:entry-point')
// void onBackgroundServiceStart(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   Stream<StepCount> stepCountStream = Pedometer.stepCountStream;
//   stepCountStream.listen((StepCount stepCount) {
//     String? userId = FirebaseAuth.instance.currentUser?.uid;
//
//     if (userId != null) {
//       FirestoreService().saveStepData(
//         userId,
//         stepCount.steps,
//         10000, // Default goal
//         DateTime.now().toIso8601String(),
//       );
//     }
//
//     // Show a notification to indicate that the service is running
//     _showNotification(stepCount.steps);
//   });
// }
//
// void _showNotification(int steps) async {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   const AndroidNotificationDetails androidNotificationDetails =
//   AndroidNotificationDetails(
//     'step_tracking_channel',
//     'Step Tracking',
//     channelDescription: 'Channel for step tracking background service',
//     importance: Importance.low,
//     priority: Priority.low,
//   );
//   const NotificationDetails notificationDetails =
//   NotificationDetails(android: androidNotificationDetails);
//
//   await flutterLocalNotificationsPlugin.show(
//     0,
//     'Step Count: $steps',
//     'Tracking your steps in the background...',
//     notificationDetails,
//   );
// }
//
// @pragma('vm:entry-point')
// bool onIosBackground(ServiceInstance service) {
//   WidgetsFlutterBinding.ensureInitialized();
//   print('iOS Background Service Running');
//   return true;
// }
