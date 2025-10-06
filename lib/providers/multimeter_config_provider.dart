import 'package:flutter/foundation.dart';
import 'package:pslab/models/multimeter_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/others/logger_service.dart';

class MultimeterConfigProvider extends ChangeNotifier {
  MultimeterConfig _config = const MultimeterConfig();

  MultimeterConfig get config => _config;

  MultimeterConfigProvider() {
    _loadConfigFromPrefs();
  }

  Future<void> _loadConfigFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('multimeter_config');
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _config = MultimeterConfig.fromJson(jsonMap);
        logger.d("Loaded MultimeterConfig: ${_config.toJson()}");
        notifyListeners();
      }
    } catch (e) {
      logger.e("Error loading MultimeterConfig from prefs: $e");
      _config = const MultimeterConfig();
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('multimeter_config', json.encode(_config.toJson()));
      logger.d("Saved MultimeterConfig: ${_config.toJson()}");
    } catch (e) {
      logger.e("Error saving MultimeterConfig to prefs: $e");
    }
  }

  void updateConfig(MultimeterConfig newConfig) {
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
    _config = const MultimeterConfig();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
