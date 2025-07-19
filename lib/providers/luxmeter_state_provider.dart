import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:light/light.dart';
import 'package:flutter/foundation.dart';
import 'package:pslab/providers/luxmeter_config_provider.dart';
import 'package:pslab/providers/locator.dart';

class LuxMeterStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  double _currentLux = 0.0;
  StreamSubscription? _lightSubscription;
  Timer? _timeTimer;
  final List<double> _luxData = [];
  final List<double> _timeData = [];
  final List<FlSpot> luxChartData = [];
  Light? _light;
  double _startTime = 0;
  double _currentTime = 0;
  final int _chartMaxLength = 50;
  double _luxMin = 0;
  double _luxMax = 0;
  double _luxSum = 0;
  int _dataCount = 0;
  bool _sensorAvailable = false;
  bool _isRecording = false;
  List<List<dynamic>> _recordedData = [];
  double _recordingStartTime = 0.0;
  bool get isRecording => _isRecording;

  LuxMeterConfigProvider? _configProvider;

  Function(String)? onSensorError;

  void setConfigProvider(LuxMeterConfigProvider configProvider) {
    _configProvider = configProvider;
    _configProvider?.addListener(_onConfigChanged);
  }

  void _onConfigChanged() {
    if (_configProvider != null) {
      // TODO
    }
  }

  LuxMeterConfigProvider? get configProvider => _configProvider;

  void initializeSensors({Function(String)? onError}) {
    onSensorError = onError;

    try {
      _light = Light();
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _currentTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
        _updateData();
        notifyListeners();
      });

      Timer sensorTimeout = Timer(const Duration(seconds: 3), () {
        if (!_sensorAvailable) {
          _handleSensorError(appLocalizations.lightSensorErrorLog);
        }
      });

      _lightSubscription = _light!.lightSensorStream.listen(
        (int luxValue) {
          _currentLux = luxValue.toDouble();
          if (!_sensorAvailable) {
            _sensorAvailable = true;
            sensorTimeout.cancel();
          }
          notifyListeners();
        },
        onError: (error) {
          logger.e("${appLocalizations.lightSensorError} $error");
          sensorTimeout.cancel();
          _handleSensorError(error);
        },
        cancelOnError: false,
      );
    } catch (e) {
      logger.e("${appLocalizations.lightSensorInitialError} $e");
      _handleSensorError(e);
    }
  }

  void _handleSensorError(dynamic error) {
    _sensorAvailable = false;
    onSensorError?.call(appLocalizations.noLightSensor);
    logger.e("${appLocalizations.lightSensorErrorDetails} $error");
  }

  void disposeSensors() {
    _lightSubscription?.cancel();
    _timeTimer?.cancel();
  }

  @override
  void dispose() {
    _configProvider?.removeListener(_onConfigChanged);
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    final lux = _sensorAvailable ? _currentLux : null;
    final time = _currentTime;
    if (lux != null) {
      if (_isRecording) {
        final relativeTime = time - _recordingStartTime;
        final now = DateTime.now();
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
        _recordedData.add([
          dateFormat.format(now),
          relativeTime.toStringAsFixed(2),
          lux.toStringAsFixed(2),
        ]);
      }

      _luxData.add(lux);
      _timeData.add(time);
      _luxSum += lux;
      _dataCount++;
    }
    if (_luxData.length > _chartMaxLength) {
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

  void startRecording() {
    _isRecording = true;
    _recordingStartTime = _currentTime;
    _recordedData = [];
    notifyListeners();
  }

  List<List<dynamic>> stopRecording() {
    _isRecording = false;
    notifyListeners();
    return _recordedData;
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
