import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:environment_sensors/environment_sensors.dart';
import 'package:flutter/foundation.dart';
import 'package:pslab/constants.dart';

class ThermometerStateProvider extends ChangeNotifier {
  double _currentTemperature = 0.0;
  StreamSubscription? _temperatureSubscription;
  Timer? _timeTimer;
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
  bool _sensorAvailable = false;
  final EnvironmentSensors _environmentSensors = EnvironmentSensors();

  void initializeSensors() async {
    try {
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _currentTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
        _updateData();
        notifyListeners();
      });

      try {
        await _checkTemperatureSensorAvailability();

        if (_sensorAvailable) {
          _startTemperatureReading();
        } else {
          _showTemperatureSensorUnavailableMessage();
        }
      } catch (e) {
        logger.e("$temperatureSensorInitialError $e");
        _sensorAvailable = false;
        _showTemperatureSensorUnavailableMessage();
      }
    } catch (e) {
      logger.e("$temperatureSensorInitialError $e");
      _showTemperatureSensorUnavailableMessage();
    }
  }

  Future<void> _checkTemperatureSensorAvailability() async {
    try {
      _sensorAvailable = await _environmentSensors
          .getSensorAvailable(SensorType.AmbientTemperature);
    } catch (e) {
      logger.e("Error checking temperature sensor availability: $e");
      _sensorAvailable = false;
    }
  }

  void _startTemperatureReading() {
    try {
      _temperatureSubscription = _environmentSensors.temperature.listen(
        (double temperatureValue) {
          _currentTemperature = temperatureValue;
          notifyListeners();
        },
        onError: (error) {
          logger.e("$temperatureSensorError $error");
        },
        cancelOnError: true,
      );
    } catch (e) {
      logger.e("$temperatureSensorInitialError $e");
      _sensorAvailable = false;
      _showTemperatureSensorUnavailableMessage();
    }
  }

  void _showTemperatureSensorUnavailableMessage() {
    logger.w(temperatureSensorUnavailableMessage);
  }

  void disposeSensors() {
    _temperatureSubscription?.cancel();
    _timeTimer?.cancel();
  }

  @override
  void dispose() {
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    if (!_sensorAvailable) return;

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
    notifyListeners();
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
  bool isSensorAvailable() => _sensorAvailable;

  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    return 10;
  }
}
