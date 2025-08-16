import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pslab/others/temperature_service.dart';

import '../l10n/app_localizations.dart';
import 'locator.dart';

class ThermometerStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  double _currentTemperature = 0.0;
  Timer? _timeTimer;
  StreamSubscription<double>? _temperatureSubscription;
  final List<double> _temperatureData = [];
  final List<double> _timeData = [];
  final List<FlSpot> temperatureChartData = [];
  double _startTime = 0;
  double _currentTime = 0;
  final int _maxLength = 50;
  double _temperatureMin = 0;
  double _temperatureMax = 0;
  double _temperatureSum = 0;
  int _dataCount = 0;
  bool _isSensorAvailable = false;
  bool _isInitialized = false;

  Future<void> initializeSensors() async {
    if (_isInitialized) return;

    try {
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      _isSensorAvailable =
          await TemperatureService.isTemperatureSensorAvailable();

      if (_isSensorAvailable) {
        final success = await TemperatureService.startTemperatureUpdates();
        if (success) {
          _startListeningToTemperature();

          _currentTemperature =
              await TemperatureService.getCurrentTemperature();
          logger.d('Initial temperature: $_currentTemperature°C');

          logger.d('Temperature sensor initialized successfully');
        } else {
          logger.e('Failed to start temperature updates');
          _isSensorAvailable = false;
        }
      } else {
        logger.w(appLocalizations.temperatureSensorUnavailableMessage);
      }

      _startTimeTracking();
      _isInitialized = true;

      notifyListeners();
    } catch (e) {
      logger.e("${appLocalizations.temperatureSensorInitialError} $e");
      _isSensorAvailable = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _startListeningToTemperature() {
    _temperatureSubscription?.cancel();
    _temperatureSubscription = TemperatureService.temperatureStream.listen(
      (temperature) {
        if (_isValidTemperature(temperature)) {
          _currentTemperature = temperature;
          logger.d('Temperature updated: $temperature°C');
          notifyListeners();
        } else {
          logger.w('Invalid temperature reading: $temperature - ignoring');
        }
      },
      onError: (error) {
        logger.e('Temperature stream error: $error');
      },
    );
  }

  bool _isValidTemperature(double temperature) {
    if (temperature.isNaN || temperature.isInfinite) return false;
    if (temperature < -273.15) return false;
    if (temperature > 200) return false;
    if (temperature.abs() > 1e10) return false;
    return true;
  }

  void _startTimeTracking() {
    _timeTimer?.cancel();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime =
          (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
      _updateData();
      notifyListeners();
    });
  }

  void disposeSensors() {
    _timeTimer?.cancel();
    _temperatureSubscription?.cancel();
    if (_isSensorAvailable) {
      TemperatureService.stopTemperatureUpdates();
    }
    _isInitialized = false;
  }

  @override
  void dispose() {
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    final temperature = _currentTemperature;
    final time = _currentTime;
    _temperatureData.add(temperature);
    _timeData.add(time);
    _temperatureSum += temperature;
    _dataCount++;
    if (_temperatureData.length > _maxLength) {
      final removedValue = _temperatureData.removeAt(0);
      _timeData.removeAt(0);
      _temperatureSum -= removedValue;
      _dataCount--;
    }
    if (_temperatureData.isNotEmpty) {
      _temperatureMin = _temperatureData.reduce(min);
      _temperatureMax = _temperatureData.reduce(max);
    }
    temperatureChartData.clear();
    for (int i = 0; i < _temperatureData.length; i++) {
      temperatureChartData.add(FlSpot(_timeData[i], _temperatureData[i]));
    }
  }

  double getCurrentTemperature() => _currentTemperature;

  double getMinTemperature() => _temperatureMin;

  double getMaxTemperature() => _temperatureMax;

  double getAverageTemperature() =>
      _dataCount > 0 ? _temperatureSum / _dataCount : 0.0;

  List<FlSpot> getTemperatureChartData() => temperatureChartData;

  int getDataLength() => temperatureChartData.length;

  double getCurrentTime() => _currentTime;

  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;

  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;

  bool isSensorAvailable() => _isSensorAvailable;

  bool isInitialized() => _isInitialized;

  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    return 10;
  }
}
