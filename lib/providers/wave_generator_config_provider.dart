import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/models/wave_generator_config.dart';

class WaveGeneratorConfigProvider extends ChangeNotifier {
  WaveGeneratorConfig _config = const WaveGeneratorConfig();

  WaveGeneratorConfig get config => _config;

  WaveGeneratorConfigProvider() {
    _loadConfigFromPrefs();
  }

  Future<void> _loadConfigFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('wave_generator_config');
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _config = WaveGeneratorConfig.fromJson(jsonMap);
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'wave_generator_config', json.encode(_config.toJson()));
  }

  void updateConfig(WaveGeneratorConfig newConfig) {
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
    _config = const WaveGeneratorConfig();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
