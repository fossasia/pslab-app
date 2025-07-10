import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/models/accelerometer_config.dart';

class AccelerometerConfigProvider extends ChangeNotifier {
  AccelerometerConfig _config = const AccelerometerConfig();

  AccelerometerConfig get config => _config;

  AccelerometerConfigProvider() {
    _loadConfigFromPrefs();
  }

  Future<void> _loadConfigFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('accelerometer_config');
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _config = AccelerometerConfig.fromJson(jsonMap);
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'accelerometer_config', json.encode(_config.toJson()));
  }

  void updateConfig(AccelerometerConfig newConfig) {
    _config = newConfig;
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateUpdatePeriod(int updatePeriod) {
    _config = _config.copyWith(updatePeriod: updatePeriod);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateHighLimit(int highLimit) {
    _config = _config.copyWith(highLimit: highLimit);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateActiveSensor(String activeSensor) {
    _config = _config.copyWith(activeSensor: activeSensor);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateSensorGain(int sensorGain) {
    _config = _config.copyWith(sensorGain: sensorGain);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateIncludeLocationData(bool includeLocationData) {
    _config = _config.copyWith(includeLocationData: includeLocationData);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void resetToDefaults() {
    _config = const AccelerometerConfig();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
