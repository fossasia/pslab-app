import 'dart:async';
import 'package:flutter/foundation.dart';
import '../communication/peripherals/i2c.dart';
import '../communication/sensors/sht21.dart';

class SHT21Provider extends ChangeNotifier {
  SHT21? _sensor;
  Timer? _timer;

  // These are the public variables the Screen is trying to read
  double temperature = 0.0;
  double humidity = 0.0;

  bool isRecording = false;

  void init(I2C i2c) {
    _sensor = SHT21(i2c);
  }

  void startDataLog() {
    if (_sensor == null || isRecording) return;

    isRecording = true;
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      try {
        // Fetch new values
        double temp = await _sensor!.getTemperature();
        double hum = await _sensor!.getHumidity();

        // Update variables
        temperature = temp;
        humidity = hum;

        // Notify the screen to update
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print("SHT21 Error: $e");
        }
      }
    });
  }

  void stopDataLog() {
    _timer?.cancel();
    isRecording = false;
  }

  @override
  void dispose() {
    stopDataLog();
    super.dispose();
  }
}
