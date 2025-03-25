import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../services/firestore_service.dart';

class BluetoothConnection extends StatefulWidget {

  final Function(int steps) onStepsReceived;

  BluetoothConnection({required this.onStepsReceived});

  @override
  _BluetoothConnectionState createState() => _BluetoothConnectionState();
}

class _BluetoothConnectionState extends State<BluetoothConnection> {
  List<ScanResult> scanResults = [];
  List<Map<String, dynamic>> deviceHistory = [];
  bool isScanning = false;
  bool isConnected = false;
  BluetoothDevice? connectedDevice;
  FirestoreService _firestoreService = FirestoreService();
  final StreamController<int> stepUpdateController = StreamController<
      int>.broadcast();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _checkBluetoothState();
    _loadDeviceHistory();
  }

  @override
  void dispose() {
    super.dispose();
    FlutterBluePlus.stopScan();
  }

  Future<void> _loadDeviceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('device_history') ?? '[]';
    setState(() {
      deviceHistory = List<Map<String, dynamic>>.from(
          jsonDecode(historyJson).map((x) => Map<String, dynamic>.from(x))
      );
    });
  }

  Future<void> _saveDeviceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_history', jsonEncode(deviceHistory));
  }

  Future<void> _addToHistory(BluetoothDevice device) async {
    final now = DateTime.now();
    final deviceInfo = {
      'name': device.name.isNotEmpty ? device.name : 'Unknown Device',
      'id': device.id.toString(),
      'lastConnected': now.toIso8601String(),
    };

    setState(() {
      deviceHistory.removeWhere((d) => d['id'] == device.id.toString());
      deviceHistory.insert(0, deviceInfo);
      if (deviceHistory.length > 10) deviceHistory.removeLast();
    });

    await _saveDeviceHistory();
  }

  Future<void> _checkBluetoothState() async {
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.off) {
        setState(() {
          scanResults.clear();
          isScanning = false;
          isConnected = false;
          connectedDevice = null;
        });
      }
    });
  }

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Some permissions were denied. Bluetooth functionality may be limited.',
            style: TextStyle(fontSize: 18),
          ),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _enableBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
      final state = await FlutterBluePlus.adapterState.first;
      if (state == BluetoothAdapterState.on) {
        startScan();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enable Bluetooth to scan for devices'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enable Bluetooth: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void startScan() async {
    if (await FlutterBluePlus.isSupported == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bluetooth is not supported on this device'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final BluetoothAdapterState state = await FlutterBluePlus.adapterState
        .first;
    if (state != BluetoothAdapterState.on) {
      _enableBluetooth();
      return;
    }

    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

      FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          scanResults = results;
        });
      }, onDone: () {
        if (!mounted) return;
        setState(() {
          isScanning = false;
        });
      }, onError: (e) {
        print("Error scanning: $e");
        if (!mounted) return;
        setState(() {
          isScanning = false;
        });
      });

      Future.delayed(Duration(seconds: 4), () {
        if (!mounted) return;
        FlutterBluePlus.stopScan();
        setState(() {
          isScanning = false;
        });
      });
    } catch (e) {
      print("Error starting scan: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start scanning: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      await _addToHistory(device);
      setState(() {
        isConnected = true;
        connectedDevice = device;
      });
      await Future.delayed(Duration(seconds: 1));
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      _handleServices(services);
    } catch (e) {
      print("Error connecting to device: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> disconnectDevice() async {
    try {
      if (connectedDevice != null) {
        await connectedDevice!.disconnect();
        setState(() {
          isConnected = false;
          connectedDevice = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device disconnected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("Error disconnecting: $e");
    }
  }


  void _handleServices(List<BluetoothService> services) {
    services.forEach((service) {
      if (service.uuid.toString() == '6e400001-b5a3-f393-e0a9-e50e24dcca9d') {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() ==
              '6e400003-b5a3-f393-e0a9-e50e24dcca9d') {
            characteristic.setNotifyValue(true);
            characteristic.value.listen(
                  (value) {
                if (value.length >= 14) {
                  int steps = value[13];
                  print('Steps from smartwatch: $steps');
                  _updateFirestoreWithSmartWatchSteps(steps);
                  stepUpdateController.add(steps); // Notify listeners
                  if (mounted) {
                    widget.onStepsReceived(steps);
                  }
                }
              },
            );
          }
        });
      }
    });
  }

  // void _handleServices(List<BluetoothService> services) {
  //   services.forEach((service) {
  //     print('Service UUID: ${service.uuid}');
  //
  //     // Check for the Unknown Service (6e400001-b5a3-f393-e0a9-e50e24dcca9d)
  //     if (service.uuid.toString() == '6e400001-b5a3-f393-e0a9-e50e24dcca9d') {
  //       service.characteristics.forEach((characteristic) {
  //         print('  Characteristic UUID: ${characteristic.uuid}');
  //
  //         // Subscribe to the NOTIFY characteristic
  //         if (characteristic.uuid.toString() == '6e400003-b5a3-f393-e0a9-e50e24dcca9d') {
  //           characteristic.setNotifyValue(true);
  //           characteristic.value.listen((value) {
  //             print('Received raw data: ${value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(', ')}');
  //             if (value.length >= 20) {
  //               try {
  //                 Uint8List data = Uint8List.fromList(value);
  //                 ByteData byteData = ByteData.view(data.buffer);
  //
  //                 // Print each byte individually
  //                 for (int i = 0; i < value.length; i++) {
  //                   print('Byte $i: ${value[i]} (${value[i].toRadixString(16).padLeft(2, '0')})');
  //                 }
  //
  //                 // Try to interpret larger chunks of data
  //                 if (value.length >= 4) {
  //                   print('First 4 bytes as int32 (little endian): ${byteData.getInt32(0, Endian.little)}');
  //                   print('First 4 bytes as int32 (big endian): ${byteData.getInt32(0, Endian.big)}');
  //                 }
  //
  //                 // Look for any non-zero values that might be changing
  //                 for (int i = 0; i < value.length; i += 4) {
  //                   if (i + 3 < value.length) {
  //                     int val = byteData.getUint32(i, Endian.little);
  //                     if (val != 0) {
  //                       print('Non-zero 4-byte value at index $i: $val');
  //                     }
  //                   }
  //                 }
  //               } catch (e) {
  //                 print('Error parsing data: $e');
  //               }
  //             } else {
  //               print('Received data is too short: ${value.length} bytes');
  //             }
  //           });
  //         }
  //       });
  //     }
  //   });
  // }
  Future<void> _updateFirestoreWithSmartWatchSteps(int steps) async {
    try {
      String userId = await _firestoreService.getCurrentUserId();
      if (userId.isNotEmpty) {
        await _firestoreService.updateSmartWatchSteps(userId, steps);
      }
    } catch (e) {
      print('Error updating Firestore with smartwatch steps: $e');
    }
  }

  Widget _buildDeviceHistory() {
    if (deviceHistory.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No connection history',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: deviceHistory.length,
      itemBuilder: (context, index) {
        final device = deviceHistory[index];
        final lastConnected = DateTime.parse(device['lastConnected']);
        final isCurrentDevice = connectedDevice?.id.toString() == device['id'];

        return Card(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: ListTile(
            leading: Icon(
              isCurrentDevice ? Icons.bluetooth_connected : Icons.watch,
              color: isCurrentDevice ? Colors.blue : Colors.grey,
            ),
            title: Text(device['name']),
            subtitle: Text(
              'Last connected: ${_formatDate(lastConnected)}',
              style: TextStyle(fontSize: 14),
            ),
            trailing: isCurrentDevice
                ? Chip(
              label: Text('Connected'),
              backgroundColor: Colors.green[100],
              labelStyle: TextStyle(color: Colors.green[700]),
            )
                : null,
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect device',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Find and pair your device',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade100,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.history, color: Colors.white),
                onPressed: () => _showHistoryDialog(),
                tooltip: 'Connection History',
              ),
              if (isConnected)
                IconButton(
                  icon: Icon(Icons.bluetooth_disabled, color: Colors.white),
                  onPressed: disconnectDevice,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
            color: isConnected ? Colors.green.shade700 : Colors.blue.shade700,
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            isConnected ? 'Connected to device' : 'Searching for devices...',
            style: TextStyle(
              fontSize: 16,
              color: isConnected ? Colors.green.shade700 : Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: Size(double.infinity, 60),
        ),
        onPressed: isScanning ? null : startScan,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isScanning)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            if (!isScanning) Icon(Icons.search, size: 24),
            SizedBox(width: 8),
            Text(
              isScanning ? 'Scanning...' : 'Scan for Devices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesList() {
    final filteredResults = scanResults.where((result) =>
    result.device.name.isNotEmpty
    ).toList();
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredResults.length,
        itemBuilder: (context, index) {
          final result = filteredResults[index];
          final device = result.device;
          final isConnectedToThisDevice = connectedDevice?.id == device.id;

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            elevation: isConnectedToThisDevice ? 2 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isConnectedToThisDevice
                    ? Colors.green.shade300
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConnectedToThisDevice
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.watch,
                  color: isConnectedToThisDevice
                      ? Colors.green.shade700
                      : Colors.grey.shade700,
                ),
              ),
              title: Text(
                device.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                isConnectedToThisDevice ? 'Connected' : 'Available',
                style: TextStyle(
                  color: isConnectedToThisDevice
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
              ),
              trailing: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: isConnectedToThisDevice
                      ? Colors.red.shade700
                      : Colors.blue.shade700,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: isConnectedToThisDevice
                    ? () => disconnectDevice()
                    : () => connectToDevice(device),
                child: Text(
                  isConnectedToThisDevice ? 'Disconnect' : 'Connect',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connection History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          _buildDeviceHistory(),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.minPositive,
            constraints: BoxConstraints(
              maxHeight: MediaQuery
                  .of(context)
                  .size
                  .height * 0.8,
              maxWidth: MediaQuery
                  .of(context)
                  .size
                  .width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Connection History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: deviceHistory.isEmpty
                      ? Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.devices_other,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No connection history',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: deviceHistory.length,
                    itemBuilder: (context, index) {
                      final device = deviceHistory[index];
                      final lastConnected = DateTime.parse(
                          device['lastConnected']);
                      final isCurrentDevice = connectedDevice?.id.toString() ==
                          device['id'];

                      return ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCurrentDevice
                                ? Colors.green.shade50
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.watch,
                            color: isCurrentDevice
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                        title: Text(
                          device['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Last connected: ${_formatDate(lastConnected)}',
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: isCurrentDevice
                            ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Connected',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStatusBanner(),
              _buildScanButton(),
              _buildDevicesList(),
            ],
          ),
        ),
      ),
    );
  }
}