import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/models/ccs811_config.dart';

class CCS811ConfigProvider extends ChangeNotifier {
  CCS811Config _config = const CCS811Config();

  CCS811Config get config => _config;

  CCS811ConfigProvider() {
    _loadConfigFromPrefs();
  }

  Future<void> _loadConfigFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('ccs811_config');
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _config = CCS811Config.fromJson(jsonMap);
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ccs811_config', json.encode(_config.toJson()));
  }

  void updateConfig(CCS811Config newConfig) {
    _config = newConfig;
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateUpdatePeriod(int updatePeriod) {
    _config = _config.copyWith(updatePeriod: updatePeriod);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateIncludeLocationData(bool includeLocationData) {
    _config = _config.copyWith(includeLocationData: includeLocationData);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void resetToDefaults() {
    _config = const CCS811Config();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
