import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:light/light.dart';

import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/luxmeter_config_provider.dart';
import 'package:pslab/providers/locator.dart';

import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/sensors/bh1750.dart';
import 'package:pslab/communication/sensors/tsl2561.dart';

class LuxMeterStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  double _currentLux = 0.0;
  StreamSubscription? _lightSubscription;
  Timer? _timeTimer;
  Timer? _luxTimer;

  final List<double> _luxData = [];
  final List<double> _timeData = [];
  final List<FlSpot> luxChartData = [];

  Light? _light;
  I2C? _i2c;
  ScienceLab? _scienceLab;

  BH1750? _bh1750;
  TSL2561? _tsl2561;

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
  bool get isRecording => _isRecording;

  LuxMeterConfigProvider? _configProvider;
  Function(String)? onSensorError;

  void setConfigProvider(LuxMeterConfigProvider configProvider) {
    _configProvider = configProvider;
    _configProvider?.addListener(_onConfigChanged);
    _onConfigChanged();
  }

  LuxMeterConfigProvider? get configProvider => _configProvider;

  void _onConfigChanged() async {
    if (_configProvider == null) return;
    final activeSensor = _configProvider!.config.activeSensor;

    disposeSensors();
    _resetLuxData();

    if (activeSensor == "In-built Sensor") {
      initializeInbuiltSensor(onError: onSensorError);
    } else if (activeSensor == "BH1750") {
      try {
        await initializeBH1750Sensor(onError: onSensorError);
      } catch (e) {
        _handleSensorError("BH1750 init failed: $e");
      }
    } else if (activeSensor == "TSL2561") {
      try {
        await initializeTSL2561Sensor(onError: onSensorError);
      } catch (e) {
        _handleSensorError("TSL2561 init failed: $e");
      }
    }
  }

  void initializeInbuiltSensor({Function(String)? onError}) {
    onSensorError = onError;
    try {
      _light = Light();
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      int intervalMs = _configProvider?.config.updatePeriod ?? 1000;

      double lastLux = 0.0;

      _lightSubscription = _light!.lightSensorStream.listen(
        (int luxValue) {
          lastLux = luxValue.toDouble();
          if (!_sensorAvailable) {
            _sensorAvailable = true;
          }
        },
        onError: (error) {
          logger.e("${appLocalizations.lightSensorError} $error");
          _handleSensorError(error);
        },
        cancelOnError: false,
      );

      _timeTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
        _currentTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
        _currentLux = lastLux;
        _updateData();
        notifyListeners();
      });
    } catch (e) {
      logger.e("${appLocalizations.lightSensorInitialError} $e");
      _handleSensorError(e);
    }
  }

  Future<void> initializeBH1750Sensor({Function(String)? onError}) async {
    onSensorError = onError;

    try {
      _scienceLab = getIt<ScienceLab>();
      if (_scienceLab == null || !_scienceLab!.isConnected()) {
        onSensorError?.call('ScienceLab not connected');
      }

      _i2c = I2C(_scienceLab!.mPacketHandler);
      _bh1750 = BH1750(_i2c!);

      int intervalMs = _configProvider?.config.updatePeriod ?? 1000;

      int gainValue = _configProvider?.config.sensorGain ?? 1000;
      String gainStr = "${gainValue}mLx";
      _bh1750!.setRange(gainStr);

      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      int lastUpdate = 0;

      _luxTimer = Timer.periodic(Duration(milliseconds: 10), (timer) async {
        try {
          final lux = await _bh1750?.getRaw();
          if (lux != null) {
            _currentLux = lux;
            _sensorAvailable = true;

            double currentTime =
                (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;

            if ((currentTime * 1000 - lastUpdate) >= intervalMs) {
              lastUpdate = (currentTime * 1000).toInt();
              _currentTime = currentTime;
              _updateData();
              notifyListeners();
            }
          }
        } catch (e) {
          logger.e("BH1750 read error: $e");
          _handleSensorError(e);
        }
      });

      logger.d(
          'BH1750 initialized with gain $gainValue at interval $intervalMs ms');
    } catch (e) {
      logger.e("Error initializing BH1750: $e");
      _handleSensorError(e);
    }
  }

  Future<void> initializeTSL2561Sensor({Function(String)? onError}) async {
    onSensorError = onError;

    try {
      _scienceLab = getIt<ScienceLab>();
      if (_scienceLab == null || !_scienceLab!.isConnected()) {
        onSensorError?.call('ScienceLab not connected');
      }

      _i2c = I2C(_scienceLab!.mPacketHandler);
      _tsl2561 = TSL2561(_i2c!, _scienceLab!);

      int intervalMs = _configProvider?.config.updatePeriod ?? 1000;

      int gain = _configProvider?.config.sensorGain ?? 16;
      _tsl2561!.setGain(gain);

      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      int lastUpdate = 0;

      _luxTimer = Timer.periodic(Duration(milliseconds: 10), (timer) async {
        try {
          final lux = await _tsl2561?.getRaw();
          if (lux != null) {
            _currentLux = lux;
            _sensorAvailable = true;

            double currentTime =
                (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;

            if ((currentTime * 1000 - lastUpdate) >= intervalMs) {
              lastUpdate = (currentTime * 1000).toInt();
              _currentTime = currentTime;
              _updateData();
              notifyListeners();
            }
          }
        } catch (e) {
          logger.e("TSL2561 read error: $e");
          _handleSensorError(e);
        }
      });

      logger
          .d('TSL2561 initialized with gain $gain at interval $intervalMs ms');
    } catch (e) {
      logger.e("Error initializing TSL2561: $e");
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
    _luxTimer?.cancel();

    _light = null;
    _bh1750 = null;
    _tsl2561 = null;
    _i2c = null;
    _scienceLab = null;
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
        final now = DateTime.now();
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
        _recordedData.add([
          now.millisecondsSinceEpoch.toString(),
          dateFormat.format(now),
          lux.toStringAsFixed(2),
          0,
          0
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

  void _resetLuxData() {
    _luxData.clear();
    _timeData.clear();
    luxChartData.clear();
    _luxSum = 0;
    _dataCount = 0;
    _luxMin = 0;
    _luxMax = 0;
    _currentTime = 0;
    _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    notifyListeners();
  }

  void startRecording() {
    _isRecording = true;
    _recordedData = [
      ['Timestamp', 'DateTime', 'Readings', 'Latitude', 'Longitude']
    ];
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
