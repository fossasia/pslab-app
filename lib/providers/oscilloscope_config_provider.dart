import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/models/oscilloscope_config.dart';

class OscilloscopeConfigProvider extends ChangeNotifier {
  OscilloscopeConfig _config = const OscilloscopeConfig();

  OscilloscopeConfig get config => _config;

  OscilloscopeConfigProvider() {
    _loadConfigFromPrefs();
  }

  Future<void> _loadConfigFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('oscilloscope_config');
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _config = OscilloscopeConfig.fromJson(jsonMap);
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('oscilloscope_config', json.encode(_config.toJson()));
  }

  void updateConfig(OscilloscopeConfig newConfig) {
    _config = newConfig;
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateIncludeLocationData(bool includeLocationData) {
    _config = _config.copyWith(includeLocationData: includeLocationData);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void resetToDefaults() {
    _config = const OscilloscopeConfig();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
