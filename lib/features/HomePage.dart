import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:healthcare_app/service/background_step_tracker.dart'; // You'll need to create this file
import 'package:healthcare_app/features/Sign-in.dart';
import 'package:healthcare_app/features/step_cout.dart';
import 'package:healthcare_app/features/profilePage.dart';
import 'package:healthcare_app/features/MedicationReminders.dart';
import 'package:healthcare_app/features/MedicationReminders.dart';

import 'MedicationReminderList.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  HomePage({required this.userData});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // @override
  // void initState() {
  //   super.initState();
  //   _initializeBackgroundStepTracking();
  // }
  // Future<void> _initializeBackgroundStepTracking() async {
  //   final currentUser = FirebaseAuth.instance.currentUser;
  //   if (currentUser != null) {
  //     try {
  //       // Initialize background step tracking
  //       await BackgroundStepTracker.initializeBackgroundService();
  //     } catch (e) {
  //       print("Error initializing background step tracking: $e");
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final userName = widget.userData['name'] ?? 'User';
    final userEmail = widget.userData['email'] ?? 'No email provided';
    final greeting = _getGreeting();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.blueGrey[800]),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.blueGrey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: _buildDrawer(context, userName, userEmail),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Greeting and Info Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $userName!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Health Summary Card
              _buildHealthSummaryCard(),
              SizedBox(height: 24),

              // Quick Actions
              _buildQuickActionsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String userName, String userEmail) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              userName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: Colors.blue.shade600,
                size: 40,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
            ),
          ),
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.directions_walk,
            title: 'Step Counter',
            onTap: () {
              Navigator.pop(context); // Close the drawer
              navigateToStepCounter(context);
            },
          ),
          Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Sign Out',
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.blueGrey[800],
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildHealthSummaryCard() {
    final steps = 0; // Replace with real data
    final goal = 10000;
    final progress = steps / goal;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Health Goal',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Today\'s Steps: $steps',
            style: TextStyle(
              fontSize: 18,
              color: Colors.blueGrey[700],
            ),
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(Colors.green),
            minHeight: 10,
          ),
          SizedBox(height: 10),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% of your goal',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => navigateToStepCounter(context),
                  icon: Icon(Icons.directions_walk),
                  label: Text('Step Counter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => navigateToMedicationReminders(context),
                  icon: Icon(Icons.medication),
                  label: Text('Medication'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => navigateToMedicationReminderList(context),
            icon: Icon(Icons.list_alt),
            label: Text('Medication List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }


  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 18) return "Good Afternoon";
    return "Good Evening";
  }

  void navigateToStepCounter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StepCounter()),
    );
  }

  void navigateToMedicationReminders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MedicationReminderPage()),
    );
  }
  void navigateToMedicationReminderList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MedicationReminderList()),
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