import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:healthcare_app/service/notificationService.dart';
import 'package:permission_handler/permission_handler.dart';
import 'features/Sign-in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp(); // Initialize Firebase and permissions
  await Firebase.initializeApp();
  await NotificationService.initializeNotification();
  runApp(MyApp());
}

Future<void> initializeApp() async {
  try {
    await Firebase.initializeApp();

    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      var result = await Permission.activityRecognition.request();
      if (!result.isGranted) {
        print("Permission denied. Activity recognition will not work.");
      }
    }
  } catch (e) {
    print('Error during initialization: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Healthcare App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: {
        '/login': (context) => SignInPage(),
      },
      home: SignInPage(),
    );
  }
}
