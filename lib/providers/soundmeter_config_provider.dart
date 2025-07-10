import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/models/soundmeter_config.dart';

class SoundMeterConfigProvider extends ChangeNotifier {
  SoundMeterConfig _config = const SoundMeterConfig();
  SoundMeterConfig get config => _config;
  SoundMeterConfigProvider() {
    _loadConfigFromPrefs();
  }
  Future<void> _loadConfigFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('sound_config');
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _config = SoundMeterConfig.fromJson(jsonMap);
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sound_config', json.encode(_config.toJson()));
  }

  void updateConfig(SoundMeterConfig newConfig) {
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
    _config = const SoundMeterConfig();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
