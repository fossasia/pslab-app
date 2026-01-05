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
    // This fixes the lint warning you saw earlier
    _sensor ??= SHT21(i2c);
  }

  // Start the loop to read data
  Future<void> startDataLog() async {
    if (_sensor == null) return;

    isWorking = true;
    notifyListeners();

    while (isWorking) {
      // Fetch new values
      temp = await _sensor!.getTemperature();
      hum = await _sensor!.getHumidity();

      // Update UI
      notifyListeners();

      // Wait 1 second before next read
      await Future.delayed(Duration(milliseconds: 1000));
    }
  }

  // Stop the loop
  void stopDataLog() {
    isWorking = false;
    notifyListeners();
  }
}
