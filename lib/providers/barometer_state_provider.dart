import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:pslab/constants.dart';

class BarometerStateProvider extends ChangeNotifier {
  double _currentPressure = 0.0;
  StreamSubscription? _barometerSubscription;
  Timer? _timeTimer;
  final List<double> _pressureData = [];
  final List<double> _timeData = [];
  final List<FlSpot> pressureChartData = [];
  double _startTime = 0;
  double _currentTime = 0;
  final int _maxLength = 50;
  double _pressureMin = 0;
  double _pressureMax = 0;
  double _pressureSum = 0;
  int _dataCount = 0;
  bool _sensorAvailable = true;

  Function(String)? onSensorError;

  void initializeSensors({Function(String)? onError}) {
    onSensorError = onError;

    try {
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _currentTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
        if (_sensorAvailable) {
          _updateData();
        }
        notifyListeners();
      });

      _barometerSubscription = barometerEventStream().listen(
        (BarometerEvent event) {
          _currentPressure = event.pressure / 1013.25;
          _sensorAvailable = true;
          notifyListeners();
        },
        onError: (error) {
          logger.e("$barometerSensorError $error");
          _handleSensorError(error);
        },
        cancelOnError: false,
      );
    } catch (e) {
      logger.e("$barometerSensorInitialError $e");
      _handleSensorError(e);
    }
  }

  void _handleSensorError(dynamic error) {
    _sensorAvailable = false;
    String errorString = error.toString().toLowerCase();
    if (errorString.contains('not available') ||
        errorString.contains('not supported') ||
        errorString.contains('sensor not found') ||
        errorString.contains('no sensor')) {
      _handleSensorNotAvailable();
    } else {
      onSensorError?.call('Barometer sensor error occurred');
    }
  }

  void _handleSensorNotAvailable() {
    _sensorAvailable = false;
    onSensorError?.call('Barometer sensor not available on this device');
  }

  void disposeSensors() {
    _barometerSubscription?.cancel();
    _timeTimer?.cancel();
  }

  @override
  void dispose() {
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    if (!_sensorAvailable) return;

    final pressure = _currentPressure;
    final time = _currentTime;
    _pressureData.add(pressure);
    _timeData.add(time);
    _pressureSum += pressure;
    _dataCount++;
    if (_pressureData.length > _maxLength) {
      final removedValue = _pressureData.removeAt(0);
      _timeData.removeAt(0);
      _pressureSum -= removedValue;
      _dataCount--;
    }
    if (_pressureData.isNotEmpty) {
      _pressureMin = _pressureData.reduce(min);
      _pressureMax = _pressureData.reduce(max);
    }
    pressureChartData.clear();
    for (int i = 0; i < _pressureData.length; i++) {
      pressureChartData.add(FlSpot(_timeData[i], _pressureData[i]));
    }
    notifyListeners();
  }

  double getCurrentPressure() => _currentPressure;
  double getMinPressure() => _pressureMin;
  double getMaxPressure() => _pressureMax;
  double getAveragePressure() =>
      _dataCount > 0 ? _pressureSum / _dataCount : 0.0;
  List<FlSpot> getPressureChartData() => pressureChartData;
  int getDataLength() => pressureChartData.length;
  double getCurrentTime() => _currentTime;
  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;
  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;
  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    return 10;
  }

  bool get sensorAvailable => _sensorAvailable;
}
