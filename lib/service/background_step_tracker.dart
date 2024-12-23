import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'package:pedometer/pedometer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../service/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String STEP_TRACKING_TASK = 'trackSteps';
const String STEP_TRACKING_UNIQUE_NAME = 'stepTracking';

class BackgroundStepTracker {
  static StreamSubscription<StepCount>? _stepCountSubscription;

  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: true
      );

      await Workmanager().cancelAll();

      await Workmanager().registerPeriodicTask(
          STEP_TRACKING_UNIQUE_NAME,
          STEP_TRACKING_TASK,
          frequency: Duration(minutes: 15),
          initialDelay: Duration(seconds: 5),
          constraints: Constraints(
              networkType: NetworkType.not_required,
              requiresBatteryNotLow: false,
              requiresCharging: false,
              requiresDeviceIdle: false,
              requiresStorageNotLow: false
          ),
          existingWorkPolicy: ExistingWorkPolicy.replace,
          backoffPolicy: BackoffPolicy.linear,
          backoffPolicyDelay: Duration(minutes: 1)
      );

      // Initialize pedometer listening
      await _initializePedometer();

      print('Background step tracking service initialized successfully');
    } catch (e) {
      print('Failed to initialize background service: $e');
    }
  }

  static Future<void> _initializePedometer() async {
    // Cancel any existing subscription
    await _stepCountSubscription?.cancel();

    try {
      _stepCountSubscription = Pedometer.stepCountStream.listen(
            (StepCount event) async {
          await _handleStepCount(event);
        },
        onError: (error) {
          print('Pedometer error: $error');
        },
      );
    } catch (e) {
      print('Error initializing pedometer: $e');
    }
  }

  static Future<void> _handleStepCount(StepCount event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastStepCount = prefs.getInt('lastStepCount') ?? 0;
      final currentTime = DateTime.now();

      // Only process if steps have increased
      if (event.steps > lastStepCount) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final stepDiff = event.steps - lastStepCount;

          // Get current data
          final stepData = await FirestoreService().getStepData(user.uid);
          final currentSteps = stepData['steps'] ?? 0;
          final goal = stepData['goal'] ?? 10000;

          // Save new total
          await FirestoreService().saveStepData(
            user.uid,
            currentSteps + stepDiff,
            goal,
            DateFormat('yyyy-MM-dd').format(currentTime),
          );

          // Update last known values
          await prefs.setInt('lastStepCount', event.steps);
          await prefs.setString('lastStepUpdateTime', currentTime.toIso8601String());

          print('Successfully updated step count. New steps: $stepDiff');
        }
      }
    } catch (e) {
      print('Error handling step count: $e');
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('Starting background task: $task');

    if (task != STEP_TRACKING_TASK) {
      print('Unknown task type: $task');
      return Future.value(false);
    }

    try {
      // Initialize Firebase
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp();
      }

      // Re-initialize pedometer listening
      await BackgroundStepTracker._initializePedometer();

      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(true);
    }
  });
}