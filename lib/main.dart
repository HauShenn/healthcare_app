import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare_app/services/notificationService.dart';
import 'package:healthcare_app/services/firestore_service.dart';
import 'package:healthcare_app/services/permission_handler_services.dart';
import 'features/Sign-in.dart';
import 'features/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();
  runApp(MyApp());
}

Future<void> initializeApp() async {
  try {
    await Firebase.initializeApp();
    await NotificationService.initializeNotification();
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
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
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
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _loadUserData(),
            builder: (context, userDataSnapshot) {
              if (userDataSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userDataSnapshot.hasData) {
                return PermissionHandlerPage(
                  nextPage: MainNavigation(userData: userDataSnapshot.data!),
                );
              }

              FirebaseAuth.instance.signOut();
              return SignInPage();
            },
          );
        }

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