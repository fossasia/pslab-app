import 'dart:async';
import 'package:flutter/foundation.dart';
import '../communication/sensors/sht21.dart';
import '../communication/peripherals/i2c.dart';

class SHT21Provider with ChangeNotifier {
  SHT21? _sensor;
  bool isWorking = false;
  double temp = 0.0;
  double hum = 0.0;

  // Initialize the sensor with the I2C connection
  Future<void> init(I2C i2c) async {
    _sensor ??= SHT21(i2c);
  }

  // Start the loop to read data
  Future<void> startDataLog() async {
    if (_sensor == null) return;

    // FIX 1: Prevent multiple loops running at the same time
    // If it's already working, stop here.
    if (isWorking) return;

    isWorking = true;
    notifyListeners();

    while (isWorking) {
      try {
        // FIX 2: Wrap I2C calls in try-catch to prevent crashing on error
        temp = await _sensor!.getTemperature();
        hum = await _sensor!.getHumidity();
        notifyListeners();
      } catch (e) {
        // Log the error but don't crash the app
        debugPrint("Error reading SHT21: $e");
      }

      // Wait 1 second before next read
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  // Stop the loop
  void stopDataLog() {
    isWorking = false;
    notifyListeners();
  }
}
