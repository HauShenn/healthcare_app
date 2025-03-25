import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BluetoothConnection extends StatefulWidget {
  @override
  _BluetoothConnectionState createState() => _BluetoothConnectionState();
}

class _BluetoothConnectionState extends State<BluetoothConnection> {
  List<ScanResult> scanResults = [];
  List<Map<String, dynamic>> deviceHistory = [];
  bool isScanning = false;
  bool isConnected = false;
  BluetoothDevice? connectedDevice;

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
    // Listen for Bluetooth state changes
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
    // Check if Bluetooth is enabled
    if (await FlutterBluePlus.isSupported == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bluetooth is not supported on this device'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
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


    // Stop scanning after 4 seconds
    Future.delayed(Duration(seconds: 4), () {
      if (!mounted) return; // Prevent setState if the widget is no longer mounted
      FlutterBluePlus.stopScan();
      setState(() {
        isScanning = false;
      });
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: Duration(seconds: 4));
      await _addToHistory(device);
      setState(() {
        isConnected = true;
        connectedDevice = device;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.name}'),
          backgroundColor: Colors.green,
        ),
      );

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        _handleServices(service);
      }
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

  void _handleServices(BluetoothService service) {
    // Handle different services based on their UUIDs
    // You'll need to identify the correct UUIDs for your H13 mini watch
    print('Service UUID: ${service.uuid}');

    for (BluetoothCharacteristic characteristic in service.characteristics) {
      print('Characteristic UUID: ${characteristic.uuid}');

      // Example: Handle heart rate data
      if (characteristic.properties.notify) {
        characteristic.setNotifyValue(true);
        characteristic.value.listen((value) {
          // Process the data based on your watch's protocol
          print('Received data: $value');
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80, // Taller app bar for better visibility
        title: Text(
          'Connect Your Watch',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        actions: [
          if (isConnected)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Icon(Icons.bluetooth_disabled, size: 32),
                onPressed: disconnectDevice,
                tooltip: 'Disconnect Watch',
              ),
            ),
        ],
      ),
      body: Container(
        color: Colors.grey[50], // Light background for better contrast
        child: Column(
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              color: isConnected ? Colors.green[100] : Colors.blue[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isConnected ? Icons.check_circle : Icons.info_outline,
                    size: 40,
                    color: isConnected ? Colors.green[700] : Colors.blue[700],
                  ),
                  SizedBox(width: 16),
                  Text(
                    isConnected
                        ? 'Your watch is connected'
                        : 'Please connect your watch',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: isConnected ? Colors.green[700] : Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),

            // Scan Button
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: EdgeInsets.symmetric(vertical: 20),
                      minimumSize: Size(double.infinity, 70),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                    ),
                    onPressed: isScanning ? null : startScan,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 32),
                        SizedBox(width: 16),
                        Text(
                          isScanning ? 'Searching...' : 'Search for Watch',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (isConnected) ...[
                    SizedBox(height: 24),
                    Text(
                      'Connected to: ${connectedDevice?.name ?? "Unknown Watch"}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Connection History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildDeviceHistory(),
            // Device List
            Expanded(
              child: scanResults.isEmpty
                  ? Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    isScanning
                        ? 'Looking for nearby watches...'
                        : 'No watches found.\nTap "Search for Watch" above to begin.',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  final result = scanResults[index];
                  final device = result.device;
                  final isConnectedToThisDevice =
                      connectedDevice?.id == device.id;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: isConnectedToThisDevice
                            ? Colors.green.shade300
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isConnectedToThisDevice
                                  ? Colors.green[100]
                                  : Colors.blue[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.watch,
                              size: 36,
                              color: isConnectedToThisDevice
                                  ? Colors.green[700]
                                  : Colors.blue[700],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.name.isNotEmpty
                                      ? device.name
                                      : 'Unknown Watch',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  isConnectedToThisDevice
                                      ? 'Connected'
                                      : 'Available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isConnectedToThisDevice
                                        ? Colors.green[700]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isConnectedToThisDevice
                                  ? Colors.red
                                  : Colors.blue,
                              padding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              isConnectedToThisDevice
                                  ? 'Disconnect'
                                  : 'Connect',
                              style: TextStyle(fontSize: 20),
                            ),
                            onPressed: isConnectedToThisDevice
                                ? () => disconnectDevice()
                                : () => connectToDevice(device),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}