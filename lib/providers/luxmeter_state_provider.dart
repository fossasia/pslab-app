import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:light/light.dart';
import 'package:flutter/foundation.dart';
import 'package:pslab/constants.dart';

class LuxMeterStateProvider extends ChangeNotifier {
  double _currentLux = 0.0;
  StreamSubscription? _lightSubscription;
  Timer? _timeTimer;
  final List<double> _luxData = [];
  final List<double> _timeData = [];
  final List<FlSpot> luxChartData = [];
  Light? _light;
  double _startTime = 0;
  double _currentTime = 0;
  final int _maxLength = 50;
  double _luxMin = 0;
  double _luxMax = 0;
  double _luxSum = 0;
  int _dataCount = 0;
  bool _sensorAvailable = true;

  Function(String)? onSensorError;

  void initializeSensors({Function(String)? onError}) {
    onSensorError = onError;

    if (!_isPlatformSupported()) {
      _handleUnsupportedPlatform();
      return;
    }

    try {
      _light = Light();
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      if (_sensorAvailable) {
        _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _currentTime =
              (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
          if (_sensorAvailable) {
            _updateData();
          }
          notifyListeners();
        });
      }

      _lightSubscription = _light!.lightSensorStream.listen(
        (int luxValue) {
          _currentLux = luxValue.toDouble();
          _sensorAvailable = true;
          notifyListeners();
        },
        onError: (error) {
          logger.e("$lightSensorError $error");
          _handleSensorError(error);
        },
        cancelOnError: false,
      );
    } catch (e) {
      logger.e("$lightSensorInitialError $e");
      _handleSensorError(e);
    }
  }

  bool _isPlatformSupported() {
    return Platform.isAndroid;
  }

  void _handleUnsupportedPlatform() {
    _sensorAvailable = false;
    if (Platform.isIOS) {
      onSensorError?.call(luxMeterIOSError);
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      onSensorError?.call(luxMeterDesktopError);
    } else if (kIsWeb) {
      onSensorError?.call(luxMeterWebError);
    } else {
      onSensorError?.call(luxMeterPlatformError);
    }
  }

  void _handleSensorError(dynamic error) {
    _sensorAvailable = false;

    if (!_isPlatformSupported()) {
      _handleUnsupportedPlatform();
      return;
    }

    _handleSensorNotAvailable();

    logger.e("$lightSensorErrorDetails $error");
  }

  void _handleSensorNotAvailable() {
    _sensorAvailable = false;
    onSensorError?.call(noLightSensor);
  }

  void disposeSensors() {
    _lightSubscription?.cancel();
    _timeTimer?.cancel();
  }

  @override
  void dispose() {
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    if (!_sensorAvailable) return;

    final lux = _currentLux;
    final time = _currentTime;
    _luxData.add(lux);
    _timeData.add(time);
    _luxSum += lux;
    _dataCount++;
    if (_luxData.length > _maxLength) {
      final removedValue = _luxData.removeAt(0);
      _timeData.removeAt(0);
      _luxSum -= removedValue;
      _dataCount--;
    }
    if (_luxData.isNotEmpty) {
      _luxMin = _luxData.reduce(min);
      _luxMax = _luxData.reduce(max);
    }
    luxChartData.clear();
    for (int i = 0; i < _luxData.length; i++) {
      luxChartData.add(FlSpot(_timeData[i], _luxData[i]));
    }
    notifyListeners();
  }

  double getCurrentLux() => _currentLux;
  double getMinLux() => _luxMin;
  double getMaxLux() => _luxMax;
  double getAverageLux() => _dataCount > 0 ? _luxSum / _dataCount : 0.0;
  List<FlSpot> getLuxChartData() => luxChartData;
  int getDataLength() => luxChartData.length;
  double getCurrentTime() => _currentTime;
  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;
  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;
  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    return 10;
  }
}
