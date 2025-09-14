import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/models/luxmeter_config.dart';
import 'package:pslab/others/logger_service.dart';

class LuxMeterConfigProvider extends ChangeNotifier {
  LuxMeterConfig _config = const LuxMeterConfig();

  LuxMeterConfig get config => _config;

  LuxMeterConfigProvider() {
    _loadConfigFromPrefs();
  }

  Future<void> _loadConfigFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('lux_config');
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _config = LuxMeterConfig.fromJson(jsonMap);
        logger.d("Loaded LuxMeterConfig: ${_config.toJson()}");
        notifyListeners();
      }
    } catch (e) {
      logger.e("Error loading LuxMeterConfig from prefs: $e");
      _config = const LuxMeterConfig();
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lux_config', json.encode(_config.toJson()));
      logger.d("Saved LuxMeterConfig: ${_config.toJson()}");
    } catch (e) {
      logger.e("Error saving LuxMeterConfig to prefs: $e");
    }
  }

  void updateConfig(LuxMeterConfig newConfig) {
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
    if (activeSensor != "In-built Sensor" &&
        activeSensor != "BH1750" &&
        activeSensor != "TSL2561") {
      activeSensor = "In-built Sensor";
    }
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
    _config = const LuxMeterConfig();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
