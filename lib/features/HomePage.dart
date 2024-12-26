import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:healthcare_app/features/Sign-in.dart';
import 'package:healthcare_app/features/step_cout.dart';
import 'package:healthcare_app/features/profilePage.dart';
import 'package:healthcare_app/features/MedicationReminders.dart';
import 'package:healthcare_app/services/background_step_tracker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'BluetoothConnection.dart';
import 'HealthAssessment.dart';
import 'MedicationReminderList.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  HomePage({required this.userData});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  BluetoothDevice? connectedDevice;
  bool isDeviceConnected = false;
  // Constants for consistent spacing and sizing
  final double cardPadding = 24.0;
  final double buttonHeight = 72.0;
  final double fontSize = 24.0;
  final double iconSize = 32.0;

  @override
  void initState() {
    super.initState();
    _initializeBackgroundService();
    _checkConnectedDevice();
  }

  Future<void> _checkConnectedDevice() async {
    try {
      var connectedDevices = await FlutterBluePlus.connectedSystemDevices;
      setState(() {
        connectedDevice = connectedDevices.isNotEmpty ? connectedDevices.first : null;
        isDeviceConnected = connectedDevice != null;
      });
    } catch (e) {
      print('Error checking connected device: $e');
    }
  }

  Future<void> disconnectDevice() async {
    try {
      if (connectedDevice != null) {
        await connectedDevice!.disconnect();
        setState(() {
          isDeviceConnected = false;
          connectedDevice = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device disconnected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error disconnecting device: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect device'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> _initializeBackgroundService() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in; skipping background service initialization.');
      return;
    }
    if (await Permission.activityRecognition.request().isGranted) {
      await BackgroundStepTracker.initialize();

    }
    else {
      print('Activity recognition permission not granted');}

    try {
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        'stepTracking',
        'trackSteps',
        frequency: Duration(minutes: 15),
        initialDelay: Duration(seconds: 10),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      print('Background service initialized successfully.');
    } catch (e) {
      print('Error initializing background service: $e');
    }
  }
  Widget _buildDeviceStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDeviceConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  size: 32,
                  color: isDeviceConnected ? Colors.blue : Colors.grey,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Watch Status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        isDeviceConnected
                            ? 'Connected to: ${connectedDevice?.name ?? "Unknown Device"}'
                            : 'No device connected',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDeviceConnected ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDeviceConnected)
                  IconButton(
                    icon: Icon(Icons.bluetooth_disabled),
                    onPressed: disconnectDevice,
                    color: Colors.red,
                    tooltip: 'Disconnect device',
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _checkConnectedDevice,
                    color: Colors.blue,
                  ),
              ],
            ),
            if (!isDeviceConnected) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => navigateToBluetoothConnection(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth_searching),
                    SizedBox(width: 8),
                    Text('Connect Device'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 4.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
        ),
      );
    }

    final userName = widget.userData['name'] ?? 'User';
    final userEmail = widget.userData['email'] ?? 'No email provided';
    final greeting = _getGreeting();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        elevation: 4,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: iconSize),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'My Health Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: _buildDrawer(context, userName, userEmail),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGreetingCard(userName, userEmail, greeting),
            SizedBox(height: 24),
            _buildDeviceStatusCard(), // Add this line
            SizedBox(height: 24),
            _buildQuickAccessButtons(context),
            SizedBox(height: 24),
            _buildHealthSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard(String userName, String userEmail, String greeting) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,\n$userName!',
              style: TextStyle(
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
                height: 1.3,
              ),
            ),
            SizedBox(height: 16),
            Text(
              userEmail,
              style: TextStyle(
                fontSize: fontSize * 0.75,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        _buildAccessButton(
          icon: Icons.medication,
          label: 'My Medications',
          color: Colors.green.shade600,
          onTap: () => navigateToMedicationReminders(context),
        ),
        SizedBox(height: 16),
        _buildAccessButton(
          icon: Icons.directions_walk,
          label: 'Step Counter',
          color: Colors.orange.shade600,
          onTap: () => navigateToStepCounter(context),
        ),
        SizedBox(height: 16),
        _buildAccessButton(
          icon: Icons.health_and_safety,
          label: 'Health Check',
          color: Colors.blue.shade600,
          onTap: () => navigateToHealthAssessment(context),
        ),
        SizedBox(height: 16),
        _buildAccessButton(
          icon: Icons.bluetooth,
          label: 'Connect Watch',
          color: Colors.purple.shade600,
          onTap: () => navigateToBluetoothConnection(context),
        ),
      ],
    );
  }

  Widget _buildAccessButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: Colors.white),
          SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSummaryCard() {
    final steps = 0;
    final goal = 10000;
    final progress = steps / goal;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Progress',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.directions_walk, size: iconSize, color: Colors.green),
                SizedBox(width: 16),
                Text(
                  '$steps steps',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(Colors.green),
                minHeight: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Goal: 10,000 steps',
              style: TextStyle(
                fontSize: fontSize * 0.75,
                color: Colors.grey[600],
              ),
            ),
          ],
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
                fontSize: fontSize,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              userEmail,
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
                color: Colors.blue.shade600,
                size: iconSize,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
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
          // ... (keep other drawer items with updated styling)
          Divider(height: 32, thickness: 1),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(icon, size: iconSize, color: Colors.blue.shade700),
      title: Text(
        title,
        style: TextStyle(
          fontSize: fontSize * 0.85,
          color: Colors.grey[800],
        ),
      ),
      onTap: onTap,
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

  void navigateToHealthAssessment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HealthAssessmentPage()),
    );
  }


  void navigateToBluetoothConnection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BluetoothConnection()),
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