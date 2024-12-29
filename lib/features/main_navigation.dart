import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare_app/features/HomePage.dart';
import 'package:healthcare_app/features/HealthAssessment.dart';
import 'package:healthcare_app/features/MedicationReminders.dart';
import 'package:healthcare_app/features/step_cout.dart';
import 'package:healthcare_app/features/profilePage.dart';
import 'package:healthcare_app/features/Sign-in.dart';

import 'UserManualPage.dart';
import 'nearby_hospitals.dart';

class MainNavigation extends StatefulWidget {
  final Map<String, dynamic> userData;

  MainNavigation({required this.userData});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final double iconSize = 32.0;
  final double fontSize = 24.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'My Health Dashboard',
    'Health Assessment',
    'My Medications',
    'Step Tracker',
    'Nearby Hospitals'
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(userData: widget.userData),
      HealthAssessmentPage(),
      MedicationReminderPage(),
      StepCounter(),
      NearbyHospitalsPage(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: iconSize),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _titles[_currentIndex],
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0, // Remove elevation for a flatter look
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.teal.shade700, Colors.teal.shade500],
                ),
              ),
              accountName: Text(
                widget.userData['name'] ?? 'User',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  color: Colors.white,
                ),
              ),
              accountEmail: Text(
                widget.userData['email'] ?? 'No email provided',
                style: TextStyle(
                  fontSize: fontSize * 0.75,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 40,
                child: Icon(
                  Icons.person,
                  color: Colors.teal.shade600,
                  size: iconSize,
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.help_outline,
              title: 'User Guide',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserManualPage()),
                );
              },
            ),
            Divider(height: 32, thickness: 1),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.teal.shade600,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.health_and_safety_outlined),
              activeIcon: Icon(Icons.health_and_safety),
              label: 'Health',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication_outlined),
              activeIcon: Icon(Icons.medication),
              label: 'Meds',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk_outlined),
              activeIcon: Icon(Icons.directions_walk),
              label: 'Steps',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital_outlined),
              activeIcon: Icon(Icons.local_hospital),
              label: 'Hospitals',
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Icon(
        icon,
        size: iconSize,
        color: Colors.teal.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: fontSize * 0.85,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have signed out'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}