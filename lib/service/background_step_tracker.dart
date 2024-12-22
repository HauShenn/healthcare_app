import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../service/firestore_service.dart';
import 'package:intl/intl.dart';

class BackgroundStepTracker {
  static Future<void> initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'step_counter_channel',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    // Check if user is signed in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    StreamSubscription<StepCount>? stepCountSubscription;

    // Check and request activity recognition permission
    var status = await Permission.activityRecognition.request();
    if (!status.isGranted) return;

    stepCountSubscription = Pedometer.stepCountStream.listen(
            (StepCount event) async {
          // Get current steps
          int steps = event.steps!;

          // Load existing step data or create new
          var stepData = await FirestoreService().getStepData(currentUser.uid);
          int currentGoal = stepData['goal'] ?? 10000;
          String lastRecordedDate = stepData['lastRecordedDate'];

          // Reset steps if it's a new day
          String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          if (lastRecordedDate != today) {
            steps = 0;
          }

          // Save steps to Firestore
          await FirestoreService().saveStepData(
              currentUser.uid,
              steps,
              currentGoal,
              today
          );

          // Optional: Update service notification to show current steps
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: "Step Counter",
              content: "Today's steps: $steps",
            );
          }
        },
        onError: (error) {
          print("Background step tracking error: $error");
        }
    );

    // Keep service running
    service.on('stopService')?.listen((event) {
      stepCountSubscription?.cancel();
      service.stopSelf();
    });
  }
}