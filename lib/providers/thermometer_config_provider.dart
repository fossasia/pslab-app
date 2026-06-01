import 'package:flutter/foundation.dart';
import 'package:pslab/constants.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/models/thermometer_config.dart';
import 'package:pslab/others/logger_service.dart';

class ThermometerConfigProvider extends ChangeNotifier {
  ThermometerConfig _config = const ThermometerConfig();

  ThermometerConfig get config => _config;

  ThermometerConfigProvider() {
    _loadConfigFromPrefs();
  }

  Future<void> _loadConfigFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('thermometer_config');
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _config = ThermometerConfig.fromJson(jsonMap);
        logger.d("Loaded ThermometerConfig: ${_config.toJson()}");
        notifyListeners();
      }
    } catch (e) {
      logger.e("Error loading ThermometerConfig from prefs: $e");
      _config = const ThermometerConfig();
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'thermometer_config', json.encode(_config.toJson()));
      logger.d("Saved ThermometerConfig: ${_config.toJson()}");
    } catch (e) {
      logger.e("Error saving ThermometerConfig to prefs: $e");
    }
  }

  void updateIncludeLocationData(bool value) {
    _config = _config.copyWith(includeLocationData: value);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateConfig(ThermometerConfig newConfig) {
    _config = newConfig;
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateUpdatePeriod(int updatePeriod) {
    _config = _config.copyWith(updatePeriod: updatePeriod);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateActiveSensor(String activeSensor) {
    if (activeSensor != appLocalizations.inBuiltSensor &&
        activeSensor != appLocalizations.sht21) {
      activeSensor = appLocalizations.inBuiltSensor;
    }
    _config = _config.copyWith(activeSensor: activeSensor);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateUnit(String unit) {
    if (unit != "Celsius" && unit != "Fahrenheit") {
      unit = "Celsius";
    }
    _config = _config.copyWith(unit: unit);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void resetToDefaults() {
    _config = const ThermometerConfig();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
