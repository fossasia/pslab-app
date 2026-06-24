import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/others/logger_service.dart';
import '../models/gas_sensor_config.dart';

class GasSensorConfigProvider extends ChangeNotifier {
  GasSensorConfig _config = const GasSensorConfig();

  GasSensorConfig get config => _config;

  GasSensorConfigProvider() {
    _loadConfigFromPrefs();
  }

  Future<void> _loadConfigFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('gas_sensor_config');
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _config = GasSensorConfig.fromJson(jsonMap);
        logger.d("Loaded GasSensorConfig: ${_config.toJson()}");
        notifyListeners();
      }
    } catch (e) {
      logger.e("Error loading GasSensorConfig from prefs: $e");
      _config = const GasSensorConfig();
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gas_sensor_config', json.encode(_config.toJson()));
      logger.d("Saved GasSensorConfig: ${_config.toJson()}");
    } catch (e) {
      logger.e("Error saving GasSensorConfig to prefs: $e");
    }
  }

  void updateUpdatePeriod(int updatePeriod) {
    _config = _config.copyWith(updatePeriod: updatePeriod);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateActiveSensor(String activeSensor) {
    if (activeSensor != "MQ-135" && activeSensor != "CCS811") {
      activeSensor = "MQ-135";
    }
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
    _config = const GasSensorConfig();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
