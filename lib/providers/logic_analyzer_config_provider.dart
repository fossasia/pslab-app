import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/models/logic_analyzer_config.dart';

class LogicAnalyzerConfigProvider extends ChangeNotifier {
  LogicAnalyzerConfig _config = const LogicAnalyzerConfig();

  LogicAnalyzerConfig get config => _config;

  LogicAnalyzerConfigProvider() {
    _loadConfigFromPrefs();
  }

  Future<void> _loadConfigFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('logic_analyzer_config');
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _config = LogicAnalyzerConfig.fromJson(jsonMap);
      notifyListeners();
    }
  }

  Future<void> _saveConfigToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'logic_analyzer_config', json.encode(_config.toJson()));
  }

  void updateConfig(LogicAnalyzerConfig newConfig) {
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
    _config = const LogicAnalyzerConfig();
    notifyListeners();
    _saveConfigToPrefs();
  }
}
