import 'package:flutter/foundation.dart';
import 'package:pslab/models/settings_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/others/logger_service.dart';

class SettingsConfigProvider extends ChangeNotifier {
  SettingsConfig _config = const SettingsConfig();

  SettingsConfig get config => _config;

  SettingsConfigProvider() {
    _loadConfigFromPrefs();
  }

  Future<void> _loadConfigFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('settings_config');
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _config = SettingsConfig.fromJson(jsonMap);
        logger.d("Loaded SettingsConfig: ${_config.toJson()}");
        notifyListeners();
      }
    } catch (e) {
      logger.e("Error loading SettingsConfig from prefs: $e");
      _config = const SettingsConfig();
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('settings_config', json.encode(_config.toJson()));
      logger.d("Saved SettingsConfig: ${_config.toJson()}");
    } catch (e) {
      logger.e("Error saving SettingsConfig to prefs: $e");
    }
  }

  void updateConfig(SettingsConfig newConfig) {
    _config = newConfig;
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateExportFormat(String exportFormat) {
    if (exportFormat != "CSV" && exportFormat != "TXT") {
      exportFormat = "CSV";
    }
    _config = _config.copyWith(exportFormat: exportFormat);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void updateAutoStart(bool autoStart) {
    _config = _config.copyWith(autoStart: autoStart);
    notifyListeners();
    _saveConfigToPrefs();
  }

  void resetToDefaults() {
    _config = const SettingsConfig();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
