import 'package:flutter/services.dart';

class WearOSService {
  static const platform = MethodChannel('com.yourapp/wearos');

  // Method to get health data from WearOS
  Future<void> getHealthDataFromWearOS() async {
    try {
      final healthData = await platform.invokeMethod('getHealthData');
      print('Health Data from WearOS: $healthData'); // Handle the health data here
      return healthData; // You can return this data to use elsewhere
    } on PlatformException catch (e) {
      print("Error getting data from WearOS: ${e.message}");
    }
  }
}
