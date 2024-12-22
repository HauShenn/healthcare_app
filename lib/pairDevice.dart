import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Pairdevice extends StatefulWidget {
  @override
  _HealthDashboardState createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<Pairdevice> {
  BluetoothDevice? connectedDevice;
  BluetoothAdapterState? _adapterState;

  @override
  void initState() {
    super.initState();
    // Check Bluetooth adapter state before scanning
    FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _adapterState = state;
      });

      if (state == BluetoothAdapterState.on) {
        startBluetoothScan();
      }
    });
  }

  // Start scanning for nearby Bluetooth devices
  void startBluetoothScan() async {
    try {
      // Stop any ongoing scan first
      await FlutterBluePlus.stopScan();

      // Start a new scan
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

      // Listen for scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.device.name == "WearOS_Device_Name") {
            // Stop scanning
            FlutterBluePlus.stopScan();

            // Connect to the device
            connectToDevice(r.device);
            break;
          }
        }
      });
    } catch (e) {
      print("Error during scan: $e");
    }
  }

  // Connect to the Bluetooth device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Connect to the device
      await device.connect();

      setState(() {
        connectedDevice = device;
      });

      print("Connected to ${device.name}");
      startCollectingHealthData();
    } catch (e) {
      print("Failed to connect to device: $e");
    }
  }

  // Function to start collecting health data
  void startCollectingHealthData() async {
    if (connectedDevice == null) return;

    try {
      // Discover services
      await connectedDevice!.discoverServices();

      print("Health data collection started...");
      // Implement your specific health data collection logic here
    } catch (e) {
      print("Error discovering services: $e");
    }
  }

  @override
  void dispose() {
    // Disconnect the device when the widget is disposed
    if (connectedDevice != null) {
      disconnectDevice();
    }
    super.dispose();
  }

  // Method to disconnect the device
  void disconnectDevice() async {
    try {
      await connectedDevice?.disconnect();
      setState(() {
        connectedDevice = null;
      });
    } catch (e) {
      print("Error disconnecting device: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Health Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show adapter state
            Text('Bluetooth Adapter: ${_adapterState ?? "Unknown"}'),

            // Show connection status
            Text('Connected to ${connectedDevice?.name ?? 'No device'}'),

            // Add more UI elements as needed
          ],
        ),
      ),
    );
  }
}