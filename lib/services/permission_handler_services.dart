import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PermissionHandlerPage extends StatefulWidget {
  final Widget nextPage;

  const PermissionHandlerPage({Key? key, required this.nextPage}) : super(key: key);

  @override
  State<PermissionHandlerPage> createState() => _PermissionHandlerPageState();
}

class _PermissionHandlerPageState extends State<PermissionHandlerPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Request permissions when page loads
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    try {
      // List of permissions to request
      List<Permission> permissions = [
        Permission.activityRecognition,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ];

      // Request each permission one by one
      for (var permission in permissions) {
        final status = await permission.status;
        if (status != PermissionStatus.granted) {
          await permission.request();
          // Wait between requests
          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      // Initialize Bluetooth
      try {
        bool isAvailable = await FlutterBluePlus.isAvailable;
        if (!isAvailable) {
          print("Bluetooth is not available on this device");
        }
      } catch (e) {
        print('Error initializing Bluetooth: $e');
      }

      // Navigate to next page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.nextPage),
      );
    } catch (e) {
      print('Error requesting permissions: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Requesting Permissions...'),
            ] else
              Text('Setting up permissions...'),
          ],
        ),
      ),
    );
  }
}

