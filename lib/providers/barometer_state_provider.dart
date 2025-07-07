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
  bool _sensorAvailable = false;

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

      Timer sensorTimeout = Timer(const Duration(seconds: 3), () {
        if (!_sensorAvailable) {
          _handleSensorError(barometerSensorError);
        }
      });

      _barometerSubscription = barometerEventStream().listen(
        (BarometerEvent event) {
          _currentPressure = event.pressure / 1013.25;
          if (!_sensorAvailable) {
            _sensorAvailable = true;
            sensorTimeout.cancel();
          }
          notifyListeners();
        },
        onError: (error) {
          logger.e("$barometerSensorError $error");
          sensorTimeout.cancel();
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
    onSensorError?.call(barometerNotAvailable);
    logger.e("$barometerSensorError $error");
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

  double _pressureToAltitude(double pressureAtm) {
    const double seaLevelPressureAtm = 1.0;
    const double temperatureK = 288.15;
    const double lapseRate = 0.0065;
    const double gasConstant = 287.05;
    const double gravity = 9.80665;

    if (pressureAtm <= 0) return 0.0;

    double altitude = (temperatureK / lapseRate) *
        (1 -
            pow(pressureAtm / seaLevelPressureAtm,
                (gasConstant * lapseRate) / gravity));

    return altitude;
  }

  double getCurrentPressure() => _currentPressure;
  double getMinPressure() => _pressureMin;
  double getMaxPressure() => _pressureMax;
  double getAveragePressure() =>
      _dataCount > 0 ? _pressureSum / _dataCount : 0.0;

  double getCurrentAltitude() => _pressureToAltitude(_currentPressure);
  double getMinAltitude() =>
      _pressureMin > 0 ? _pressureToAltitude(_pressureMin) : 0.0;
  double getMaxAltitude() =>
      _pressureMax > 0 ? _pressureToAltitude(_pressureMax) : 0.0;
  double getAverageAltitude() => _pressureToAltitude(getAveragePressure());

  double getMaxAltitudeForChart() =>
      _pressureMax > 0 ? _pressureToAltitude(0) : 10000.0;
  double getMinAltitudeForChart() =>
      _pressureMin > 0 ? _pressureToAltitude(_pressureMax * 1.1) : 0.0;
  double getAltitudeInterval() {
    double maxAlt = getMaxAltitudeForChart();
    return maxAlt > 0 ? (maxAlt / 5) : 2000;
  }

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
