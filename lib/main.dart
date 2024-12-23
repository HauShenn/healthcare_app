import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare_app/service/notificationService.dart';
import 'package:healthcare_app/service/firestore_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'features/Sign-in.dart';
import 'features/HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();
  runApp(MyApp());
}

Future<void> initializeApp() async {
  try {
    await Firebase.initializeApp();
    await NotificationService.initializeNotification();

    // Request necessary permissions
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
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, fetch their data and navigate to HomePage
          return FutureBuilder<Map<String, dynamic>>(
            future: _loadUserData(),
            builder: (context, userDataSnapshot) {
              if (userDataSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (userDataSnapshot.hasData) {
                return HomePage(userData: userDataSnapshot.data!);
              }

              // If we can't load user data, sign out and show login
              FirebaseAuth.instance.signOut();
              return SignInPage();
            },
          );
        }

        // User is not logged in
        return SignInPage();
      },
    );
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    try {
      final userData = await _firestoreService.getUserData();
      return userData.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error loading user data: $e');
      throw e;
    }
  }
}