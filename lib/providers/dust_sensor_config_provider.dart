import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/models/dust_sensor_config.dart';

class DustSensorConfigProvider extends ChangeNotifier {
  DustSensorConfig _config = const DustSensorConfig();
  DustSensorConfig get config => _config;

  DustSensorConfigProvider() {
    _loadConfigFromPrefs();
  }

  Future<void> _loadConfigFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('dust_config');
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _config = DustSensorConfig.fromJson(jsonMap);
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dust_config', json.encode(_config.toJson()));
  }

  void updateConfig(DustSensorConfig newConfig) {
    _config = newConfig;
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateUpdatePeriod(int updatePeriod) {
    _config = _config.copyWith(updatePeriod: updatePeriod);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateHighLimit(double highLimit) {
    _config = _config.copyWith(highLimit: highLimit);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateActiveSensor(String activeSensor) {
    _config = _config.copyWith(activeSensor: activeSensor);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateIncludeLocationData(bool includeLocationData) {
    _config = _config.copyWith(includeLocationData: includeLocationData);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void resetToDefaults() {
    _config = const DustSensorConfig();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
