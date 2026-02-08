import 'package:flutter/foundation.dart';
import '../communication/sensors/mlx90614.dart';
import '../communication/peripherals/i2c.dart';

class MLX90614Provider with ChangeNotifier {
  MLX90614? _sensor;
  bool isWorking = false;

  // This sensor provides two values
  double ambientTemp = 0.0; // Room temperature
  double objectTemp = 0.0; // Target temperature

  // Initialize the sensor with the I2C connection
  Future<void> init(I2C i2c) async {
    _sensor ??= MLX90614(i2c);
  }

  // Start the loop to read data
  Future<void> startDataLog() async {
    if (_sensor == null) return;

    // Check if loop is already running to prevent duplicates
    if (isWorking) return;

    isWorking = true;
    notifyListeners();

    while (isWorking) {
      try {
        // Read both values safely
        ambientTemp = await _sensor!.getAmbientTemperature();
        objectTemp = await _sensor!.getObjectTemperature();
        notifyListeners();
      } catch (e) {
        debugPrint("Error reading MLX90614: $e");
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
