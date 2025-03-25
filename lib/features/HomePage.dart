import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:healthcare_app/features/theme_constants.dart';
import 'package:healthcare_app/services/background_step_tracker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'BluetoothConnection.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  HomePage({required this.userData});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _stepCountController = StreamController<int>.broadcast();
  BluetoothDevice? connectedDevice;
  bool isDeviceConnected = false;
  int currentSteps = 0; // Track steps here
  int? currentHeartRate;
  final double cardPadding = 24.0;
  final double buttonHeight = 80.0;  // Increased from 72.0
  final double fontSize = 18.0;      // Increased from 24.0
  final double subtitleSize = 16.0;  // New
  final double bodySize = 15.0;      // New
  final double iconSize = 24.0;      // Increased from 32.0
  final double spacing = 20.0;

  @override
  void initState() {
    super.initState();
    _initializeBackgroundService();
    _checkConnectedDevice();

  }

  @override
  void dispose() {
    _stepCountController.close();
    super.dispose();
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
    } else {
      print('Activity recognition permission not granted');
    }

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
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required String tooltip,
  }) {
    return Container(
      height: 48, // Fixed height
      width: 48,  // Fixed width
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, size: iconSize * 0.7), // Slightly smaller icon
        onPressed: onPressed,
        color: color,
        tooltip: tooltip,
        padding: EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildDeviceStatusCard() {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isDeviceConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    size: iconSize,
                    color: isDeviceConnected ? Colors.teal.shade600 : Colors.grey,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Watch Status',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Text(
                        isDeviceConnected
                            ? 'Connected to: ${connectedDevice?.name ?? "Unknown Device"}'
                            : 'No device connected',
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: isDeviceConnected ? Colors.teal.shade600 : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isDeviceConnected)
                  _buildIconButton(
                    icon: Icons.bluetooth_disabled,
                    onPressed: disconnectDevice,
                    color: Colors.red.shade600,
                    tooltip: 'Disconnect device',
                  )
                else
                  _buildIconButton(
                    icon: Icons.refresh,
                    onPressed: _checkConnectedDevice,
                    color: Colors.teal.shade600,
                    tooltip: 'Refresh connection',
                  ),
              ],
            ),
            if (!isDeviceConnected) ...[
              SizedBox(height: spacing),
              _buildConnectButton(),
            ],
          ],
        ),
      ),
    );
  }
// New helper method for connect button
  Widget _buildConnectButton() {
    return ElevatedButton(
      onPressed: () => navigateToBluetoothConnection(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: 20.0, // Slightly reduced padding
          vertical: 16.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        minimumSize: Size(double.infinity, buttonHeight),
      ),
      child: FittedBox( // Wrap in FittedBox to prevent overflow
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_searching, size: iconSize),
            SizedBox(width: 12), // Reduced spacing
            Text(
              'Connect Device',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            valueColor: AlwaysStoppedAnimation<Color>(ThemeConstants.primaryTeal),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade700, Colors.teal.shade50],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: spacing),
                _buildDeviceStatusCard(),
                SizedBox(height: spacing),
              ],
            ),
          ),
        ),
      ),
    );
  }


  


  void navigateToBluetoothConnection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BluetoothConnection(
          onStepsReceived: (steps) {
            _stepCountController.add(steps);
          },
        ),
      ),
    );
  }
}
