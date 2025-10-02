import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/models/power_source_config.dart';

class PowerSourceConfigProvider extends ChangeNotifier {
  PowerSourceConfig _config = const PowerSourceConfig();

  PowerSourceConfig get config => _config;

  PowerSourceConfigProvider() {
    _loadConfigFromPrefs();
  }

  Future<void> _loadConfigFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('power_source_config');
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _config = PowerSourceConfig.fromJson(jsonMap);
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('power_source_config', json.encode(_config.toJson()));
  }

  void updateConfig(PowerSourceConfig newConfig) {
    _config = newConfig;
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateLoggingInterval(int loggingInterval) {
    _config = _config.copyWith(loggingInterval: loggingInterval);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateIncludeLocationData(bool includeLocationData) {
    _config = _config.copyWith(includeLocationData: includeLocationData);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void resetToDefaults() {
    _config = const PowerSourceConfig();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
