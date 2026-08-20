import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:light/light.dart';

enum HardwareMode {
  all,
  inbuiltSensors,
}

class HardwareFilterProvider with ChangeNotifier {
  static const String _prefKey = 'selected_hardware_filter_mode';
  HardwareMode _currentMode = HardwareMode.all;

  bool _hasCheckedSensors = false;

  final Map<String, bool> _sensorAvailability = {
    '/luxmeter': false,
    '/accelerometer': false,
    '/barometer': false,
    '/compass': false,
    '/gyroscope': false,
    '/thermometer': false,
    '/soundmeter': true,
  };

  HardwareMode get currentMode => _currentMode;
  Map<String, bool> get sensorAvailability => _sensorAvailability;

  HardwareFilterProvider() {
    _loadSavedMode();
  }

  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_prefKey) ?? 0;
    _currentMode =
        HardwareMode.values[index.clamp(0, HardwareMode.values.length - 1)];
    notifyListeners();

    if (_currentMode == HardwareMode.inbuiltSensors) {
      _checkDeviceSensorsDynamically();
    }
  }

  Future<void> setHardwareMode(HardwareMode mode) async {
    if (_currentMode == mode) return;
    _currentMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, mode.index);

    if (_currentMode == HardwareMode.inbuiltSensors && !_hasCheckedSensors) {
      await _checkDeviceSensorsDynamically();
    }
  }

  Future<void> _checkDeviceSensorsDynamically() async {
    if (_hasCheckedSensors) return;

    try {
      final results = await Future.wait([
        _isStreamActive(accelerometerEventStream()),
        _isStreamActive(gyroscopeEventStream()),
        _isStreamActive(magnetometerEventStream()),
        _isStreamActive(barometerEventStream()),
        _isStreamActive(Light().lightSensorStream),
      ]);

      _sensorAvailability['/accelerometer'] = results[0];
      _sensorAvailability['/gyroscope'] = results[1];
      _sensorAvailability['/compass'] = results[2];
      _sensorAvailability['/barometer'] = results[3];
      _sensorAvailability['/luxmeter'] = results[4];

      _hasCheckedSensors = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error in dynamic sensor check: $e');
    }
  }

  Future<bool> _isStreamActive(Stream<dynamic> stream) async {
    try {
      await stream.first.timeout(const Duration(seconds: 2));
      return true;
    } catch (e) {
      return false;
    }
  }
}
